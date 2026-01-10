"""
GEONEXUS V4 - Script de Ingestão de Dados do TSE
================================================
Este script lê os dados eleitorais do TSE da pasta local
e prepara para inserção no Supabase.

Autor: Squad GEONEXUS
Data: 2024
"""

import os
import glob
import argparse
import logging
from pathlib import Path
from typing import Optional, Generator
import pandas as pd
from dotenv import load_dotenv

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# ============================================
# CONFIGURAÇÕES
# ============================================

# Caminho base dos dados TSE (relativo à raiz do projeto)
BASE_DATA_PATH = Path(__file__).parent.parent / "DADOS TSE GEONEXUS"

# Mapeamento de pastas
DATA_PATHS = {
    "votos_2024": BASE_DATA_PATH / "Votação por seção 2024 BR",
    "votos_2022": BASE_DATA_PATH / "Votação por seção 2022 BR",
    "locais_2024": BASE_DATA_PATH / "Eleitorado Local de Votação 2024 BR",
}

# Colunas a REMOVER para LGPD (anonimização)
COLUNAS_LGPD_REMOVER = [
    # Dados de eleitores que poderiam identificar indivíduos
    "QT_ELEITOR_SECAO",
    "QT_ELEITOR_ELEICAO_FEDERAL", 
    "QT_ELEITOR_ELEICAO_ESTADUAL",
    "QT_ELEITOR_ELEICAO_MUNICIPAL",
    "QT_ELEITOR_BIOMETRIA",
    "QT_ELEITOR_DEFICIENCIA",
    "QT_ELEITOR_INC_NM_SOCIAL",
    # Dados que não são necessários para análise
    "DT_GERACAO",
    "HH_GERACAO",
    "TP_ABRANGENCIA",
    "CD_TIPO_ELEICAO",
    "NM_TIPO_ELEICAO",
    "CD_ELEICAO",
    "DS_ELEICAO",
    "SG_UE",
    "NM_UE",
    "SQ_CANDIDATO",
]

# Colunas essenciais para votos
COLUNAS_VOTOS = [
    "ANO_ELEICAO",
    "NR_TURNO",
    "SG_UF",
    "CD_MUNICIPIO",
    "NM_MUNICIPIO",
    "NR_ZONA",
    "NR_SECAO",
    "CD_CARGO",
    "DS_CARGO",
    "NR_VOTAVEL",
    "NM_VOTAVEL",
    "QT_VOTOS",
    "NR_LOCAL_VOTACAO",
]

# Colunas essenciais para locais de votação
COLUNAS_LOCAIS = [
    "SG_UF",
    "CD_MUNICIPIO",
    "NM_MUNICIPIO",
    "NR_ZONA",
    "NR_SECAO",
    "NR_LOCAL_VOTACAO",
    "NM_LOCAL_VOTACAO",
    "DS_ENDERECO",
    "NM_BAIRRO",
    "NR_CEP",
    "NR_LATITUDE",
    "NR_LONGITUDE",
    "DS_SITU_SECAO_ACESSIBILIDADE",
    "QT_ELEITOR_SECAO",
]


# ============================================
# FUNÇÕES DE LEITURA
# ============================================

def list_csv_files(folder: Path, pattern: str = "*.csv") -> list[Path]:
    """Lista todos os arquivos CSV em uma pasta."""
    if not folder.exists():
        logger.warning(f"Pasta não encontrada: {folder}")
        return []
    
    files = list(folder.glob(pattern))
    logger.info(f"Encontrados {len(files)} arquivos em {folder.name}")
    return files


def read_csv_chunked(
    filepath: Path,
    chunksize: int = 100000,
    usecols: Optional[list] = None,
    encoding: str = "latin-1",
    sep: str = ";"
) -> Generator[pd.DataFrame, None, None]:
    """
    Lê CSV em chunks para economizar memória.
    Arquivos do TSE usam encoding latin-1 e separador ;
    """
    try:
        for chunk in pd.read_csv(
            filepath,
            sep=sep,
            encoding=encoding,
            chunksize=chunksize,
            usecols=usecols,
            dtype=str,  # Lê tudo como string inicialmente
            low_memory=False,
            on_bad_lines="warn"
        ):
            yield chunk
    except Exception as e:
        logger.error(f"Erro lendo {filepath}: {e}")
        raise


# ============================================
# FUNÇÕES DE LIMPEZA E TRANSFORMAÇÃO
# ============================================

def limpar_votos(df: pd.DataFrame) -> pd.DataFrame:
    """
    Limpa e transforma dados de votação.
    Remove colunas sensíveis (LGPD) e converte tipos.
    """
    # Remove colunas LGPD
    colunas_existentes = [c for c in COLUNAS_LGPD_REMOVER if c in df.columns]
    df = df.drop(columns=colunas_existentes, errors='ignore')
    
    # Seleciona apenas colunas necessárias
    colunas_usar = [c for c in COLUNAS_VOTOS if c in df.columns]
    df = df[colunas_usar].copy()
    
    # Converte tipos
    int_cols = ["ANO_ELEICAO", "NR_TURNO", "CD_MUNICIPIO", "NR_ZONA", 
                "NR_SECAO", "CD_CARGO", "NR_VOTAVEL", "QT_VOTOS", "NR_LOCAL_VOTACAO"]
    
    for col in int_cols:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0).astype(int)
    
    # Remove linhas sem votos
    df = df[df["QT_VOTOS"] > 0]
    
    # Renomeia para snake_case (padrão Supabase)
    df.columns = df.columns.str.lower()
    
    return df


def limpar_locais(df: pd.DataFrame) -> pd.DataFrame:
    """
    Limpa e transforma dados de locais de votação.
    Mantém apenas dados de geolocalização e identificação.
    """
    # Seleciona colunas necessárias
    colunas_usar = [c for c in COLUNAS_LOCAIS if c in df.columns]
    df = df[colunas_usar].copy()
    
    # Converte tipos
    int_cols = ["CD_MUNICIPIO", "NR_ZONA", "NR_SECAO", "NR_LOCAL_VOTACAO", "QT_ELEITOR_SECAO"]
    float_cols = ["NR_LATITUDE", "NR_LONGITUDE"]
    
    for col in int_cols:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0).astype(int)
    
    for col in float_cols:
        if col in df.columns:
            # Latitude/Longitude podem estar como string com vírgula
            df[col] = df[col].str.replace(',', '.') if df[col].dtype == 'object' else df[col]
            df[col] = pd.to_numeric(df[col], errors='coerce')
    
    # Remove locais sem coordenadas válidas
    df = df.dropna(subset=["NR_LATITUDE", "NR_LONGITUDE"])
    df = df[(df["NR_LATITUDE"] != 0) & (df["NR_LONGITUDE"] != 0)]
    
    # Processa acessibilidade
    if "DS_SITU_SECAO_ACESSIBILIDADE" in df.columns:
        df["ACESSIBILIDADE"] = df["DS_SITU_SECAO_ACESSIBILIDADE"].str.lower().str.contains("com acessibilidade", na=False)
        df = df.drop(columns=["DS_SITU_SECAO_ACESSIBILIDADE"])
    
    # Renomeia para padrão Supabase
    rename_map = {
        "NR_LATITUDE": "latitude",
        "NR_LONGITUDE": "longitude",
    }
    df = df.rename(columns=rename_map)
    df.columns = df.columns.str.lower()
    
    # Remove duplicatas (um local por zona/seção)
    df = df.drop_duplicates(subset=["sg_uf", "cd_municipio", "nr_zona", "nr_secao"])
    
    return df


def filtrar_por_uf(df: pd.DataFrame, uf: str) -> pd.DataFrame:
    """Filtra DataFrame por UF."""
    coluna_uf = "sg_uf" if "sg_uf" in df.columns else "SG_UF"
    return df[df[coluna_uf].str.upper() == uf.upper()]


# ============================================
# FUNÇÕES DE PROCESSAMENTO POR ESTADO
# ============================================

def processar_votos_estado(uf: str, ano: int = 2024, dry_run: bool = False) -> pd.DataFrame:
    """
    Processa todos os votos de um estado específico.
    
    Args:
        uf: Sigla do estado (ex: "RJ", "SP")
        ano: Ano da eleição (2022 ou 2024)
        dry_run: Se True, apenas analisa sem inserir
    
    Returns:
        DataFrame processado e limpo
    """
    pasta_votos = DATA_PATHS[f"votos_{ano}"]
    arquivo = pasta_votos / f"votacao_secao_{ano}_{uf.upper()}.csv"
    
    if not arquivo.exists():
        logger.error(f"Arquivo não encontrado: {arquivo}")
        return pd.DataFrame()
    
    logger.info(f"Processando votos {uf} {ano}: {arquivo.name}")
    
    all_chunks = []
    total_rows = 0
    
    for i, chunk in enumerate(read_csv_chunked(arquivo, usecols=COLUNAS_VOTOS)):
        chunk_limpo = limpar_votos(chunk)
        all_chunks.append(chunk_limpo)
        total_rows += len(chunk_limpo)
        
        if (i + 1) % 10 == 0:
            logger.info(f"  Processados {total_rows:,} registros...")
    
    if not all_chunks:
        return pd.DataFrame()
    
    df_final = pd.concat(all_chunks, ignore_index=True)
    logger.info(f"Total processado {uf} {ano}: {len(df_final):,} registros")
    
    if dry_run:
        # Mostra sample
        logger.info(f"\n=== AMOSTRA {uf} ===")
        logger.info(f"Colunas: {list(df_final.columns)}")
        logger.info(f"Primeiras linhas:\n{df_final.head()}")
        logger.info(f"Candidatos únicos: {df_final['nm_votavel'].nunique()}")
    
    return df_final


def processar_locais_votacao(dry_run: bool = False) -> pd.DataFrame:
    """
    Processa o arquivo de locais de votação 2024.
    
    Args:
        dry_run: Se True, apenas analisa sem inserir
    
    Returns:
        DataFrame com locais de votação georreferenciados
    """
    arquivo = DATA_PATHS["locais_2024"] / "eleitorado_local_votacao_2024.csv"
    
    if not arquivo.exists():
        logger.error(f"Arquivo não encontrado: {arquivo}")
        return pd.DataFrame()
    
    logger.info(f"Processando locais de votação: {arquivo.name}")
    
    all_chunks = []
    total_rows = 0
    
    for i, chunk in enumerate(read_csv_chunked(arquivo, usecols=COLUNAS_LOCAIS)):
        chunk_limpo = limpar_locais(chunk)
        all_chunks.append(chunk_limpo)
        total_rows += len(chunk_limpo)
        
        if (i + 1) % 10 == 0:
            logger.info(f"  Processados {total_rows:,} locais...")
    
    if not all_chunks:
        return pd.DataFrame()
    
    df_final = pd.concat(all_chunks, ignore_index=True)
    logger.info(f"Total locais processados: {len(df_final):,}")
    
    if dry_run:
        logger.info(f"\n=== AMOSTRA LOCAIS ===")
        logger.info(f"Colunas: {list(df_final.columns)}")
        logger.info(f"Primeiras linhas:\n{df_final.head()}")
        logger.info(f"UFs únicas: {df_final['sg_uf'].unique()}")
        logger.info(f"Locais com coordenadas: {df_final['latitude'].notna().sum()}")
    
    return df_final


# ============================================
# FUNÇÕES DE INSERÇÃO NO SUPABASE
# ============================================

def inserir_supabase(df: pd.DataFrame, tabela: str, batch_size: int = 1000) -> bool:
    """
    Insere dados no Supabase em batches.
    
    Args:
        df: DataFrame para inserir
        tabela: Nome da tabela no Supabase
        batch_size: Tamanho do batch para inserção
    
    Returns:
        True se sucesso, False se erro
    """
    try:
        from supabase import create_client, Client
        
        url = os.getenv("SUPABASE_URL")
        key = os.getenv("SUPABASE_SERVICE_KEY")  # Usar service key para bypass RLS
        
        if not url or not key:
            logger.error("SUPABASE_URL ou SUPABASE_SERVICE_KEY não configurados no .env")
            return False
        
        supabase: Client = create_client(url, key)
        
        records = df.to_dict('records')
        total = len(records)
        
        for i in range(0, total, batch_size):
            batch = records[i:i+batch_size]
            supabase.table(tabela).upsert(batch).execute()
            logger.info(f"  Inseridos {min(i+batch_size, total)}/{total}")
        
        logger.info(f"Inserção completa: {total} registros em {tabela}")
        return True
        
    except ImportError:
        logger.error("Módulo 'supabase' não instalado. Execute: pip install supabase")
        return False
    except Exception as e:
        logger.error(f"Erro inserindo no Supabase: {e}")
        return False


# ============================================
# CLI - Interface de Linha de Comando
# ============================================

def main():
    parser = argparse.ArgumentParser(
        description="GEONEXUS V4 - Ingestão de dados TSE",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemplos:
  python ingest_tse.py --state RR --dry-run     # Teste com Roraima (menor estado)
  python ingest_tse.py --state RJ --year 2024   # Processa Rio de Janeiro 2024
  python ingest_tse.py --locais --dry-run       # Testa locais de votação
  python ingest_tse.py --all --year 2024        # Processa todos os estados
        """
    )
    
    parser.add_argument(
        "--state", "-s",
        type=str,
        help="Sigla do estado para processar (ex: RJ, SP, RR)"
    )
    parser.add_argument(
        "--year", "-y",
        type=int,
        choices=[2022, 2024],
        default=2024,
        help="Ano da eleição (default: 2024)"
    )
    parser.add_argument(
        "--locais", "-l",
        action="store_true",
        help="Processar locais de votação"
    )
    parser.add_argument(
        "--all", "-a",
        action="store_true",
        help="Processar todos os estados"
    )
    parser.add_argument(
        "--dry-run", "-d",
        action="store_true",
        help="Apenas analisar, não inserir no banco"
    )
    parser.add_argument(
        "--insert", "-i",
        action="store_true",
        help="Inserir dados no Supabase"
    )
    parser.add_argument(
        "--output", "-o",
        type=str,
        help="Salvar resultado em arquivo CSV"
    )
    
    args = parser.parse_args()
    
    # Carrega .env
    env_path = Path(__file__).parent.parent / ".env"
    if env_path.exists():
        load_dotenv(env_path)
        logger.info("Variáveis de ambiente carregadas")
    
    # Verifica caminhos dos dados
    logger.info(f"Caminho base dos dados: {BASE_DATA_PATH}")
    for nome, path in DATA_PATHS.items():
        status = "✓" if path.exists() else "✗"
        logger.info(f"  {status} {nome}: {path}")
    
    # Processa conforme argumentos
    if args.locais:
        df = processar_locais_votacao(dry_run=args.dry_run)
        if args.insert and not args.dry_run and not df.empty:
            inserir_supabase(df, "locais_votacao")
        if args.output:
            df.to_csv(args.output, index=False)
            logger.info(f"Salvo em: {args.output}")
    
    elif args.state:
        df = processar_votos_estado(
            uf=args.state,
            ano=args.year,
            dry_run=args.dry_run
        )
        if args.insert and not args.dry_run and not df.empty:
            inserir_supabase(df, "votos_secao")
        if args.output:
            df.to_csv(args.output, index=False)
            logger.info(f"Salvo em: {args.output}")
    
    elif args.all:
        # Lista todos os estados disponíveis
        pasta = DATA_PATHS[f"votos_{args.year}"]
        arquivos = list_csv_files(pasta)
        ufs = [f.stem.split("_")[-1] for f in arquivos]
        
        for uf in sorted(ufs):
            logger.info(f"\n{'='*50}")
            logger.info(f"PROCESSANDO: {uf}")
            logger.info(f"{'='*50}")
            
            df = processar_votos_estado(
                uf=uf,
                ano=args.year,
                dry_run=args.dry_run
            )
            
            if args.insert and not args.dry_run and not df.empty:
                inserir_supabase(df, "votos_secao")
    
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
