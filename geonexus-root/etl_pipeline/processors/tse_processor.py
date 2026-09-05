"""
GeoNexus - Pipeline ETL de Engenharia de Dados Eleitorais
Módulo de Processamento Multi-Cargo (Gerais e Municipais) sem dependência de totalização externa.
"""

import logging
from typing import Dict, List, Optional
import polars as pl
import geopandas as gpd
from shapely.geometry import Point
from sqlalchemy import create_engine

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger("TSEProcessor")

class TSEProcessor:
    CODIGO_MUNICIPIO_RIO_TSE = 60011

    TABELA_CARGOS: Dict[int, str] = {
        1: "PRESIDENTE",
        3: "GOVERNADOR",
        5: "SENADOR",
        6: "DEPUTADO FEDERAL",
        7: "DEPUTADO ESTADUAL",
        8: "DEPUTADO DISTRITAL",
        11: "PREFEITO",
        13: "VEREADOR",
    }

    def __init__(self, db_connection_url: str):
        self.engine = create_engine(db_connection_url)

    def processar_locais_votacao(self, arquivo_locais_csv: str, ano_eleicao: int) -> pl.DataFrame:
        """
        Lê, normaliza e limpa o cadastro de locais e seções do TSE.
        Lê e normaliza o cadastro de locais e seções do Rio de Janeiro.
        """
        logger.info(f"Processando locais de votação para a eleição {ano_eleicao}...")

        # Leitura com scan_csv (avaliação preguiçosa - lazy)
        lazy_df = (
            pl.scan_csv(
                arquivo_locais_csv,
                separator=";",
                encoding="utf8-lossy",
                truncate_ragged_lines=True,
                infer_schema_length=10000
            )
            .filter(
                (pl.col("CD_MUNICIPIO").cast(pl.Int32) == self.CODIGO_MUNICIPIO_RIO_TSE) &
                (pl.col("ANO_ELEICAO").cast(pl.Int32) == ano_eleicao)
            )
            .select([
                pl.col("ANO_ELEICAO").cast(pl.Int32),
                pl.col("NR_ZONA").cast(pl.Int16),
                pl.col("NR_SECAO").cast(pl.Int16),
                pl.col("NM_LOCAL_VOTACAO")
                .str.strip_chars()
                .str.replace_all(r"[\x00-\x1F\x7F]", "")  # Remove caracteres de controle
                .str.replace_all("'", "''")
                .str.to_uppercase(),
                pl.col("DS_ENDERECO")
                .str.strip_chars()
                .str.replace_all("'", "''")
                .str.to_uppercase(),
                pl.col("NM_BAIRRO")
                .str.strip_chars()
                .str.replace_all("'", "''")
                .str.to_uppercase(),
                pl.col("NR_CEP").cast(pl.Utf8).str.slice(0, 8),
                pl.col("NR_LATITUDE")
                .cast(pl.Utf8)
                .str.replace(",", ".")
                .cast(pl.Float64, strict=False)
                .alias("latitude"),
                pl.col("NR_LONGITUDE")
                .cast(pl.Utf8)
                .str.replace(",", ".")
                .cast(pl.Float64, strict=False)
                .alias("longitude"),
            ])
        )

        df = lazy_df.collect()
        logger.info(f"Locais de votação processados: {df.height} seções mapeadas na capital.")
        return df

    def processar_votacao_secao(
        self,
        arquivo_votacao_csv: str,
        ano_eleicao: int,
        cargos_alvo: Optional[List[int]] = None
    ) -> pl.DataFrame:
        """
        Lê e consolida os votos de todas as urnas do Rio de Janeiro.
        """
        logger.info(f"Processando votos por seção para a eleição {ano_eleicao}...")

        filtros = [
            pl.col("CD_MUNICIPIO").cast(pl.Int32) == self.CODIGO_MUNICIPIO_RIO_TSE,
            pl.col("ANO_ELEICAO").cast(pl.Int32) == ano_eleicao
        ]

        if cargos_alvo:
            filtros.append(pl.col("CD_CARGO").cast(pl.Int32).is_in(cargos_alvo))

        lazy_df = (
            pl.scan_csv(
                arquivo_votacao_csv,
                separator=";",
                encoding="utf8-lossy",
                truncate_ragged_lines=True,
                infer_schema_length=10000
            )
            .filter(pl.all_horizontal(filtros))
            .select([
                pl.col("ANO_ELEICAO").cast(pl.Int32),
                pl.col("NR_TURNO").cast(pl.Int8),
                pl.col("NR_ZONA").cast(pl.Int16),
                pl.col("NR_SECAO").cast(pl.Int16),
                pl.col("CD_CARGO").cast(pl.Int16),
                pl.col("DS_CARGO").str.to_uppercase(),
                pl.col("NR_VOTAVEL").cast(pl.Int32),
                pl.col("NM_VOTAVEL").str.strip_chars().str.replace_all("'", "''").str.to_uppercase(),
                pl.col("QT_VOTOS").cast(pl.Int32),
                pl.when(pl.col("NR_VOTAVEL") == 95)
                .then(pl.lit("BRANCO"))
                .when(pl.col("NR_VOTAVEL") == 96)
                .then(pl.lit("NULO"))
                .when(pl.col("NR_VOTAVEL").cast(pl.Utf8).str.len_chars() <= 2)
                .then(pl.lit("LEGENDA"))
                .otherwise(pl.lit("NOMINAL"))
                .alias("tipo_voto")
            ])
        )

        df = lazy_df.collect()
        logger.info(f"Votação processada com sucesso: {df.height} linhas geradas.")
        return df

    def carregar_banco(self, df_locais: pl.DataFrame, df_votacao: pl.DataFrame, ano_eleicao: int):
        """
        Realiza a ingestão com criação de pontos geográficos (PostGIS) e particionamento.
        """
        logger.info("Iniciando carga de dados no PostgreSQL/PostGIS...")

        # Converte para GeoPandas apenas os registros que possuem coordenadas válidas
        df_geo = df_locais.filter(pl.col("latitude").is_not_null() & pl.col("longitude").is_not_null()).to_pandas()

        if not df_geo.empty:
            # PostGIS requer Point(Longitude, Latitude)
            geometrias = [Point(xy) for xy in zip(df_geo["longitude"], df_geo["latitude"])]
            gdf_locais = gpd.GeoDataFrame(df_geo, geometry=geometrias, crs="EPSG:4326")

            gdf_locais.to_postgis(
                name="locais_votacao",
                con=self.engine,
                if_exists="append",
                index=False
            )
            logger.info(f"Carga concluída: {len(gdf_locais)} locais georreferenciados no PostGIS.")

        # Carga dos votos na partição daquele ano
        df_votacao_pd = df_votacao.to_pandas()
        df_votacao_pd.to_sql(
            name=f"votacao_secao_{ano_eleicao}",
            con=self.engine,
            if_exists="append",
            index=False,
            method="multi",
            chunksize=10000
        )
        logger.info(f"Carga da partição votacao_secao_{ano_eleicao} finalizada com sucesso.")
