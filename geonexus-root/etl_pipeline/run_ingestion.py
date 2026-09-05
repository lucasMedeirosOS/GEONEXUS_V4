"""
GeoNexus - Disparo de Ingestao de Dados Eleitorais
Varre recursivamente o diretorio data/raw/tse/{ano} e encontra os CSVs nas subpastas.
"""

import argparse
import glob
import logging
import os

from etl_pipeline.processors.tse_processor import TSEProcessor

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger("IngestionRunner")

# String de conexao com o PostgreSQL/PostGIS local via Docker.
DB_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+psycopg://postgres:postgres@localhost:5432/geonexus",
)


def encontrar_arquivo_recursivo(pasta_ano: str, termo_busca: str) -> str | None:
    """Busca em profundidade um arquivo CSV que contenha o termo no nome."""
    arquivos = glob.glob(
        os.path.join(pasta_ano, "**", f"*{termo_busca}*.csv"),
        recursive=True,
    )
    return arquivos[0] if arquivos else None


def processar_ano(ano: int, pasta_base: str = "./data/raw/tse"):
    pasta_ano = os.path.join(pasta_base, str(ano))

    logger.info(f"Localizando arquivos para a eleicao {ano} dentro de: {pasta_ano}")

    if not os.path.exists(pasta_ano):
        logger.error(f"Pasta do ano nao encontrada: {pasta_ano}")
        return

    arquivo_locais = encontrar_arquivo_recursivo(
        pasta_ano,
        f"eleitorado_local_votacao_{ano}",
    )
    arquivo_votacao = encontrar_arquivo_recursivo(
        pasta_ano,
        f"votacao_secao_{ano}_RJ",
    )

    if not arquivo_locais:
        logger.error(f"Arquivo de locais de votacao nao encontrado para {ano}")
        return
    if not arquivo_votacao:
        logger.error(f"Arquivo de votacao por secao nao encontrado para {ano}")
        return

    logger.info(f"[OK] Arquivo de locais: {arquivo_locais}")
    logger.info(f"[OK] Arquivo de votacao: {arquivo_votacao}")
    logger.info("Iniciando ingestao com Polars (Municipio do Rio de Janeiro - 60011)...")
    processor = TSEProcessor(DB_URL)

    df_locais = processor.processar_locais_votacao(arquivo_locais, ano)
    df_votos = processor.processar_votacao_secao(arquivo_votacao, ano)
    processor.carregar_banco(df_locais, df_votos, ano)

    logger.info(f"Ingestao do ano {ano} concluida com sucesso no banco de dados.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Executor de Ingestao do Data Lake GeoNexus")
    parser.add_argument(
        "--ano",
        type=int,
        choices=[2020, 2022, 2024],
        default=2022,
        help="Ano da eleicao a processar",
    )
    parser.add_argument(
        "--pasta",
        type=str,
        default="./data/raw/tse",
        help="Caminho do diretorio de dados",
    )
    args = parser.parse_args()

    processar_ano(args.ano, args.pasta)
