"""
GeoNexus - Disparo de Ingestao de Dados Eleitorais
Le diretamente do Data Lake local ou diretorio de storage sem dependencia de web scraping.
"""

import argparse
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


def processar_ano(ano: int, pasta_base: str = "./data/raw/tse"):
    pasta_ano = os.path.join(pasta_base, str(ano))

    arquivo_locais = os.path.join(pasta_ano, f"eleitorado_local_votacao_{ano}.csv")
    arquivo_votacao = os.path.join(pasta_ano, f"votacao_secao_{ano}_RJ.csv")

    logger.info(f"Verificando arquivos para a eleicao {ano} em: {pasta_ano}")

    if not os.path.exists(arquivo_locais):
        logger.error(f"Arquivo de locais de votacao nao encontrado: {arquivo_locais}")
        return
    if not os.path.exists(arquivo_votacao):
        logger.error(f"Arquivo de votacao por secao nao encontrado: {arquivo_votacao}")
        return

    logger.info(f"Arquivos validados. Iniciando processamento do ano {ano}...")
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
