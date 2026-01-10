import os
import asyncio
from dotenv import load_dotenv
from supabase import create_client, Client

async def auditar_banco():
    print("--- 🕵️‍♂️ AUDITORIA DE DADOS GEONEXUS ---")
    
    load_dotenv()
    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_ANON_KEY")

    if not url or not key:
        print("❌ ERRO: .env não encontrado ou vazio.")
        return

    supabase: Client = create_client(url, key)

    # 1. Checar Tabela de VOTOS
    print("\n1️⃣  Verificando tabela 'votos_secao'...")
    try:
        # Pega 1000 registros para amostragem
        resp = supabase.table("votos_secao").select("sg_uf").limit(1000).execute()
        ufs = set(row['sg_uf'] for row in resp.data)
        print(f"   Estados encontrados (Amostra): {ufs}")
        
        # Tenta contar RJ especificamente
        resp_rj = supabase.table("votos_secao").select("*", count="exact").eq("sg_uf", "RJ").limit(1).execute()
        print(f"   Total de registros 'RJ': {resp_rj.count}")

    except Exception as e:
        print(f"   ⚠️ Erro ao ler votos: {e}")

    # 2. Checar Tabela de LOCAIS (A que o mapa usa)
    print("\n2️⃣  Verificando tabela 'locais_votacao'...")
    try:
        resp = supabase.table("locais_votacao").select("sg_uf").limit(1000).execute()
        if len(resp.data) == 0:
             print("   ⚠️ ALERTA: A tabela 'locais_votacao' está TOTALMENTE VAZIA!")
        else:
            ufs = set(row['sg_uf'] for row in resp.data)
            print(f"   Estados encontrados (Amostra): {ufs}")
            
            # Tenta contar RJ especificamente
            resp_rj = supabase.table("locais_votacao").select("*", count="exact").eq("sg_uf", "RJ").limit(1).execute()
            print(f"   Total de locais 'RJ': {resp_rj.count}")
            
    except Exception as e:
        print(f"   ⚠️ Erro ao ler locais: {e}")

if __name__ == "__main__":
    asyncio.run(auditar_banco())