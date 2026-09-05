# GeoNexus: Plataforma de Inteligência Geoespacial

O **GeoNexus** é uma plataforma de inteligência geográfica aplicada à gestão de mandatos públicos e à estratégia político-eleitoral. O sistema cruza microdados eleitorais do Tribunal Superior Eleitoral (TSE) com dados de zeladoria urbana da Prefeitura do Rio de Janeiro (Data.Rio / Central 1746), permitindo correlacionar densidade de votos, demandas de infraestrutura e aplicação de emendas parlamentares por território.

## Principais funcionalidades

### Mandato e zeladoria

- Acompanhamento territorial de chamados do 1746, incluindo iluminação, asfalto e saneamento.
- Gestão de ofícios legislativos e acompanhamento de prazos de resposta dos órgãos públicos.
- Mapeamento geoespacial de emendas parlamentares por bairro e região administrativa.

### Inteligência eleitoral

- Séries históricas de votação por urna e local de votação, de 2008 a 2024/2026.
- Reconciliação e validação automática dos dados com a totalização oficial do TSE.
- Análise de penetração eleitoral e taxas de abstenção por local de votação.

### Cruzamento espacial com PostGIS

- Geração de zonas de influência de 500 m, 1 km e 2 km ao redor dos colégios eleitorais.
- Detecção de demandas de infraestrutura em áreas de alta concentração de eleitores.

## Stack tecnológica

| Camada | Tecnologia |
| --- | --- |
| Frontend mobile e web | Flutter 3.22+, Dart 3.x, Clean Architecture, Provider/BLoC |
| Backend API | Python 3.11+, FastAPI, SQLAlchemy 2.0, Pydantic v2 |
| Engenharia de dados | Polars (LazyFrames), DuckDB, GeoPandas, Google Geocoding API |
| Banco relacional e espacial | PostgreSQL 16, PostGIS 3.4, WGS84 (EPSG:4326) |
| Infraestrutura e nuvem | Docker, Google Cloud Run, Google Cloud SQL, BigQuery GIS |

## Estrutura do repositório

```text
├── android/                   # Configurações da plataforma Android
├── assets/                    # Ícones, fontes e mapas vetoriais
├── database/                  # Migrações e esquemas DDL do banco de dados
├── geonexus-root/
│   ├── backend/               # Microsserviço API REST (FastAPI)
│   ├── database/              # DDL e extensões PostGIS
│   ├── etl_pipeline/          # Ingestão de dados do TSE e Data.Rio (Polars)
│   └── docker-compose.yml     # Orquestração do PostgreSQL 16 + PostGIS
├── lib/                       # Código-fonte do aplicativo Flutter
├── scripts/                   # Scripts de automação e deploy
└── pubspec.yaml               # Dependências do projeto Flutter
```

## Execução local

O banco local pode ser iniciado com Docker Compose:

```powershell
docker compose up -d
```

Para executar a API:

```powershell
cd geonexus-root/backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload
```

O pipeline ETL usa os dados eleitorais do TSE em CSV, com codificação `latin-1` e separador `;`. Os arquivos de entrada devem estar disponíveis antes da execução da carga.

## Status

🚧 **Em desenvolvimento.** A plataforma está em fase de integração entre o aplicativo Flutter, a API FastAPI, o pipeline ETL e o banco geoespacial PostGIS.
