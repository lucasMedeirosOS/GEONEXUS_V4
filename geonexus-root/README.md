# Geonexus Root

This repository contains the project structure for the Geonexus platform, split into backend, ETL, database, and mobile app components.

## Structure

- backend: FastAPI application
- etl_pipeline: data extraction, transformation, and loading scripts
- database: SQL migrations and schema definitions
- mobile_app: mobile project workspace

## Getting started

1. Create a virtual environment.
2. Install backend dependencies from backend/requirements.txt.
3. Run the API with uvicorn.

## Example

```bash
cd geonexus-root/backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```
