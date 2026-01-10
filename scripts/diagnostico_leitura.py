import os
import asyncio
from dotenv import load_dotenv
from supabase import create_client, Client

async def testar_leitura():
    print("--- INICIANDO DIAGNÓSTICO DE LEITURA (SIMULANDO O APP) ---")
    
    # 1. Carrega as variáveis
    load_dotenv()
    url = os.getenv("SUPABASE_URL")
    # TRUQUE: Usamos a ANON KEY (a mesma do App), não a Service Key
    key = os.getenv("SUPABASE_ANON_KEY") 

    if not url or not key:
        print("❌ ERRO: Faltam variáveis no .env")
        return

    print(f"📡 Conectando em: {url}")
    print("🔑 Usando chave: ANON (Pública)")

    try:
        # 2. Conecta
        supabase: Client = create_client(url, key)

        # 3. Tenta ler 5 locais (exatamente como o App faria)
        print("⏳ Tentando ler a tabela 'votos_secao'...")
        response = supabase.table("votos_secao").select("*").limit(5).execute()

        # 4. Analisa o resultado
        dados = response.data
        if len(dados) > 0:
            print(f"✅ SUCESSO! O Supabase devolveu {len(dados)} registros.")
            print("📝 Exemplo de dado:", dados[0])
            print("\nCONCLUSÃO: O Banco está PERFEITO. O bloqueio é no Celular/Rede.")
        else:
            print("⚠️ ALERTA: O Supabase devolveu 0 registros (Lista Vazia).")
            print("CONCLUSÃO: O problema é o RLS (Permissão) no Supabase.")

    except Exception as e:
        print(f"❌ ERRO CRÍTICO: {e}")

if __name__ == "__main__":
    asyncio.run(testar_leitura())