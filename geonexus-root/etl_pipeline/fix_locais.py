"""
GeoNexus - Correcao de Encoding e Normalizacao de Colunas de Locais de Votacao
"""

import glob
import os
import tempfile
import geopandas as gpd
import polars as pl
from shapely.geometry import Point
from sqlalchemy import create_engine, text

DB_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+psycopg://postgres:postgres@localhost:5432/geonexus",
)
engine = create_engine(DB_URL)


def recarregar_locais(ano: int = 2022):
    padrao = f"./data/raw/tse/{ano}/**/eleitorado_local_votacao_{ano}*.csv"
    arquivos = glob.glob(padrao, recursive=True)

    if not arquivos:
        print(f"Arquivo nao encontrado para {ano}")
        return

    caminho_csv = arquivos[0]
    print(f"Lendo com encoding latin-1: {caminho_csv}")

    # O Polars atual aceita apenas UTF-8 no scan_csv; a decodificacao estrita
    # ocorre antes da leitura para preservar corretamente os acentos do TSE.
    conteudo_utf8 = open(caminho_csv, "rb").read().decode("latin-1")
    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", suffix=".csv", delete=False) as arquivo_utf8:
        arquivo_utf8.write(conteudo_utf8)
        caminho_utf8 = arquivo_utf8.name

    try:
        lazy_df = pl.scan_csv(
            caminho_utf8,
            separator=";",
            encoding="utf8",
            truncate_ragged_lines=True,
            infer_schema_length=10000,
        )
        coluna_ano = "ANO_ELEICAO" if "ANO_ELEICAO" in lazy_df.collect_schema().names() else "AA_ELEICAO"
        df = (
            lazy_df
            .filter(
                (pl.col("CD_MUNICIPIO").cast(pl.Int32) == 60011)
                & (pl.col(coluna_ano).cast(pl.Int32) == ano)
            )
            .select([
                pl.col(coluna_ano).cast(pl.Int32).alias("ano_eleicao"),
                pl.col("NR_ZONA").cast(pl.Int16).alias("nr_zona"),
                pl.col("NR_SECAO").cast(pl.Int16).alias("nr_secao"),
                pl.col("NM_LOCAL_VOTACAO").str.strip_chars().str.to_uppercase().alias("nome_local"),
                pl.col("DS_ENDERECO").str.strip_chars().str.to_uppercase().alias("endereco"),
                pl.col("NM_BAIRRO").str.strip_chars().str.to_uppercase().alias("bairro"),
                pl.col("NR_CEP").cast(pl.Utf8).str.slice(0, 8).alias("nr_cep"),
                pl.col("NR_LATITUDE").cast(pl.Utf8).str.replace(",", ".").cast(pl.Float64, strict=False).alias("latitude"),
                pl.col("NR_LONGITUDE").cast(pl.Utf8).str.replace(",", ".").cast(pl.Float64, strict=False).alias("longitude"),
            ])
            .collect()
        )
    finally:
        os.remove(caminho_utf8)

    print(f"Total de registros filtrados no Rio de Janeiro: {df.height}")

    with engine.begin() as connection:
        connection.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))
        connection.execute(text("""
            CREATE TABLE IF NOT EXISTS locais_votacao (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                ano_eleicao INT NOT NULL,
                nr_zona SMALLINT NOT NULL,
                nr_secao SMALLINT NOT NULL,
                nome_local VARCHAR(255) NOT NULL,
                endereco VARCHAR(255),
                bairro VARCHAR(100),
                nr_cep VARCHAR(20),
                latitude DOUBLE PRECISION,
                longitude DOUBLE PRECISION,
                geom GEOMETRY(Point, 4326)
            )
        """))
        connection.execute(text(
            "CREATE INDEX IF NOT EXISTS idx_locais_votacao_zona_secao "
            "ON locais_votacao (nr_zona, nr_secao)"
        ))
        connection.execute(text(
            "CREATE INDEX IF NOT EXISTS idx_locais_votacao_geom "
            "ON locais_votacao USING GIST (geom)"
        ))

    df_geo = df.filter(
        pl.col("latitude").is_not_null() & pl.col("longitude").is_not_null()
    ).to_pandas()

    if not df_geo.empty:
        print("Gerando geometrias PostGIS (WGS84)...")
        geometrias = [Point(xy) for xy in zip(df_geo["longitude"], df_geo["latitude"])]
        gdf = gpd.GeoDataFrame(df_geo, geometry=geometrias, crs="EPSG:4326")
        gdf = gdf.rename(columns={"geometry": "geom"})
        gdf = gdf.set_geometry("geom")

        print("Gravando no PostgreSQL...")
        gdf.to_postgis(
            name="locais_votacao",
            con=engine,
            if_exists="append",
            index=False,
        )
        print("Tabela locais_votacao recarregada com sucesso e com acentuacao corrigida!")


if __name__ == "__main__":
    recarregar_locais(2022)
