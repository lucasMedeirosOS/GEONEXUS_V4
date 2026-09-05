"""
GeoNexus - Extrator Automatizado de Microdados do TSE
Suporte para Eleições 2020, 2022 e 2024 (Município do Rio de Janeiro).
"""

import argparse
import logging
import os
import zipfile

import requests

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger("TSEDownloader")

# URLs oficiais do CDN do Tribunal Superior Eleitoral
URLS_TSE = {
    2020: {
        "votacao_secao": "https://cdn.tse.jus.br/estatistica/sead/odsele/votacao_secao/votacao_secao_2020_RJ.zip",
        "locais_votacao": "https://cdn.tse.jus.br/estatistica/sead/odsele/eleitorado_locais_votacao/eleitorado_local_votacao_2020.zip",
        "totalizacao": "https://cdn.tse.jus.br/estatistica/sead/odsele/votacao_candidato_munzona/votacao_candidato_munzona_2020.zip",
    },
    2022: {
        "votacao_secao": "https://cdn.tse.jus.br/estatistica/sead/odsele/votacao_secao/votacao_secao_2022_RJ.zip",
        "locais_votacao": "https://cdn.tse.jus.br/estatistica/sead/odsele/eleitorado_locais_votacao/eleitorado_local_votacao_2022.zip",
        "totalizacao": "https://cdn.tse.jus.br/estatistica/sead/odsele/votacao_candidato_munzona/votacao_candidato_munzona_2022_RJ.zip",
    },
    2024: {
        "votacao_secao": "https://cdn.tse.jus.br/estatistica/sead/odsele/votacao_secao/votacao_secao_2024_RJ.zip",
        "locais_votacao": "https://cdn.tse.jus.br/estatistica/sead/odsele/eleitorado_locais_votacao/eleitorado_local_votacao_2024.zip",
        "totalizacao": "https://cdn.tse.jus.br/estatistica/sead/odsele/votacao_candidato_munzona/votacao_candidato_munzona_2024_RJ.zip",
    },
}


def baixar_e_extrair(url: str, pasta_destino: str, nome_arquivo: str):
    os.makedirs(pasta_destino, exist_ok=True)
    caminho_zip = os.path.join(pasta_destino, f"{nome_arquivo}.zip")

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
        "Accept-Language": "pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7",
        "Referer": "https://dadosabertos.tse.jus.br/",
        "Sec-Fetch-Dest": "document",
        "Sec-Fetch-Mode": "navigate",
        "Sec-Fetch-Site": "cross-site",
        "Upgrade-Insecure-Requests": "1",
    }

    logger.info(f"Iniciando download de: {url}")
    with requests.get(url, headers=headers, stream=True, timeout=60) as resposta:
        resposta.raise_for_status()
        total_size = int(resposta.headers.get("content-length", 0))
        baixado = 0
        with open(caminho_zip, "wb") as arquivo:
            for chunk in resposta.iter_content(chunk_size=1024 * 1024):
                if chunk:
                    arquivo.write(chunk)
                    baixado += len(chunk)
                    if total_size > 0:
                        progresso = (baixado / total_size) * 100
                        print(f"\rBaixando {nome_arquivo}: {progresso:.1f}% concluído", end="")

    print()
    logger.info(f"Download concluído. Descompactando {caminho_zip}...")
    with zipfile.ZipFile(caminho_zip, "r") as zip_ref:
        zip_ref.extractall(pasta_destino)

    os.remove(caminho_zip)
    logger.info(f"Arquivos extraídos em: {pasta_destino}")


def executar_downloads(ano: int, base_dir: str = "./data/raw/tse"):
    if ano not in URLS_TSE:
        logger.error(f"Ano {ano} inválido. Escolha entre: 2020, 2022 ou 2024.")
        return

    destino_ano = os.path.join(base_dir, str(ano))
    logger.info(f"Iniciando captura de dados do TSE para o ano {ano}...")

    baixar_e_extrair(URLS_TSE[ano]["votacao_secao"], destino_ano, f"votacao_secao_{ano}_RJ")
    baixar_e_extrair(URLS_TSE[ano]["locais_votacao"], destino_ano, f"locais_votacao_{ano}")
    baixar_e_extrair(URLS_TSE[ano]["totalizacao"], destino_ano, f"totalizacao_{ano}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Downloader Oficial do TSE para o GeoNexus")
    parser.add_argument(
        "--ano",
        type=int,
        choices=[2020, 2022, 2024],
        required=True,
        help="Ano da eleição: 2020, 2022 ou 2024",
    )
    args = parser.parse_args()

    executar_downloads(args.ano)