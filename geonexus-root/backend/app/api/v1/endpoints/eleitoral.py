from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.db.database import get_db

router = APIRouter(prefix="/eleitoral", tags=["Inteligência Eleitoral"])

ANOS_ELEICAO_SUPORTADOS = {2020, 2022, 2024}


def validar_ano(ano: int) -> int:
    if ano not in ANOS_ELEICAO_SUPORTADOS:
        raise HTTPException(status_code=400, detail="Ano de eleição não suportado")
    return ano


@router.get("/ranking", response_model=List[Dict[str, Any]])
def ranking_candidatos(
    ano: int = Query(2022, description="Ano da eleição"),
    cargo: int = Query(
        6,
        description="Código do cargo: 1=Pres, 3=Gov, 5=Sen, 6=Dep. Fed, 7=Dep. Est",
    ),
    limit: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db),
):
    """Retorna os candidatos mais votados no Município do Rio de Janeiro."""
    ano = validar_ano(ano)
    sql = text(f"""
        SELECT
            nr_votavel AS numero,
            nm_votavel AS nome,
            SUM(qt_votos) AS total_votos
        FROM votacao_secao_{ano}
        WHERE cd_cargo = :cargo
        GROUP BY nr_votavel, nm_votavel
        ORDER BY total_votos DESC
        LIMIT :limit
    """)
    resultados = db.execute(sql, {"cargo": cargo, "limit": limit}).mappings().all()
    return [
        {
            "numero": resultado["numero"],
            "nome": resultado["nome"],
            "votos": resultado["total_votos"],
        }
        for resultado in resultados
    ]


@router.get("/candidato/{numero_candidato}/mapa")
def mapa_votos_candidato(
    numero_candidato: int,
    ano: int = Query(2022),
    db: Session = Depends(get_db),
):
    """Retorna votos do candidato agregados por local de votação."""
    ano = validar_ano(ano)
    sql = text(f"""
        SELECT
            l.nome_local,
            l.bairro,
            l.latitude,
            l.longitude,
            SUM(v.qt_votos) AS votos
        FROM votacao_secao_{ano} v
        JOIN locais_votacao l
          ON l.nr_zona = v.nr_zona
         AND l.nr_secao = v.nr_secao
        WHERE v.nr_votavel = :numero
          AND l.latitude IS NOT NULL
          AND l.longitude IS NOT NULL
        GROUP BY l.nome_local, l.bairro, l.latitude, l.longitude
        ORDER BY votos DESC
    """)
    resultados = db.execute(sql, {"numero": numero_candidato}).mappings().all()
    return [
        {
            "local": resultado["nome_local"],
            "bairro": resultado["bairro"],
            "latitude": resultado["latitude"],
            "longitude": resultado["longitude"],
            "votos": resultado["votos"],
        }
        for resultado in resultados
    ]


@router.get("/locais", response_model=List[Dict[str, Any]])
def listar_locais_votacao(
    bairro: Optional[str] = Query(None, description="Filtro opcional por bairro"),
    limit: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
):
    """Lista locais de votação com endereço e coordenadas."""
    where_clause = "WHERE l.bairro ILIKE :bairro" if bairro else ""
    sql = text(f"""
        SELECT DISTINCT ON (l.nome_local, l.bairro)
            l.nome_local,
            l.endereco,
            l.bairro,
            l.latitude,
            l.longitude
        FROM locais_votacao l
        {where_clause}
        ORDER BY l.nome_local, l.bairro
        LIMIT :limit
    """)
    params = {"bairro": f"%{bairro}%", "limit": limit} if bairro else {"limit": limit}
    resultados = db.execute(sql, params).mappings().all()
    return [
        {
            "nome_local": resultado["nome_local"],
            "endereco": resultado["endereco"],
            "bairro": resultado["bairro"],
            "latitude": resultado["latitude"],
            "longitude": resultado["longitude"],
        }
        for resultado in resultados
    ]
