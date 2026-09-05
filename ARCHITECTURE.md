# GeoNexus - Arquitetura

O GeoNexus é composto por um aplicativo Flutter, uma API FastAPI, um pipeline de ingestão e um banco PostgreSQL com PostGIS.

## Módulos principais

### `etl_pipeline/`

- `processors/tse_processor.py`: Motor de normalização em alta velocidade com Polars. Realiza a leitura dos arquivos do Data Lake local ou Cloud Storage, filtra os dados do Rio de Janeiro, sanitiza nomes de colégios, resolve coordenadas WGS84 e alimenta o PostGIS.
- `run_ingestion.py`: Orquestrador de ingestão desacoplado de web scrapers externos. Recebe o ano e o caminho do Data Lake, processa os arquivos de locais e votação e grava os dados diretamente no PostGIS.

### `backend/`

- Serviço REST construído com FastAPI para exposição dos dados e funcionalidades da plataforma.

### `database/`

- Esquemas, extensões PostGIS e migrações do banco de dados.

### Aplicativo Flutter

- Interface mobile e web organizada segundo Clean Architecture.
