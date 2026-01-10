-- ============================================
-- GEONEXUS V4 - SCHEMA DO BANCO DE DADOS
-- Supabase (PostgreSQL)
-- ============================================

-- ============================================
-- 1. EXTENSÕES NECESSÁRIAS
-- ============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================
-- 2. TABELAS PRINCIPAIS
-- ============================================

-- Locais de Votação (com geolocalização)
CREATE TABLE locais_votacao (
    id BIGSERIAL PRIMARY KEY,
    sg_uf VARCHAR(2) NOT NULL,
    cd_municipio INTEGER NOT NULL,
    nm_municipio VARCHAR(100) NOT NULL,
    nr_zona INTEGER NOT NULL,
    nr_secao INTEGER NOT NULL,
    nr_local_votacao INTEGER NOT NULL,
    nm_local_votacao VARCHAR(200) NOT NULL,
    ds_endereco TEXT,
    nm_bairro VARCHAR(100),
    nr_cep VARCHAR(10),
    latitude DECIMAL(12, 8),
    longitude DECIMAL(12, 8),
    acessibilidade BOOLEAN DEFAULT FALSE,
    qt_eleitores_secao INTEGER DEFAULT 0,
    geom GEOMETRY(POINT, 4326),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(sg_uf, cd_municipio, nr_zona, nr_secao)
);

-- Índices para performance
CREATE INDEX idx_locais_votacao_uf ON locais_votacao(sg_uf);
CREATE INDEX idx_locais_votacao_municipio ON locais_votacao(cd_municipio);
CREATE INDEX idx_locais_votacao_geom ON locais_votacao USING GIST(geom);
CREATE INDEX idx_locais_votacao_latlon ON locais_votacao(latitude, longitude);

-- Trigger para atualizar geometria automaticamente
CREATE OR REPLACE FUNCTION update_geom_from_latlon()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
        NEW.geom = ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_geom
BEFORE INSERT OR UPDATE ON locais_votacao
FOR EACH ROW EXECUTE FUNCTION update_geom_from_latlon();

-- ============================================
-- Votos por Seção (dados agregados)
-- ============================================
CREATE TABLE votos_secao (
    id BIGSERIAL PRIMARY KEY,
    ano_eleicao INTEGER NOT NULL,
    nr_turno INTEGER DEFAULT 1,
    sg_uf VARCHAR(2) NOT NULL,
    cd_municipio INTEGER NOT NULL,
    nm_municipio VARCHAR(100) NOT NULL,
    nr_zona INTEGER NOT NULL,
    nr_secao INTEGER NOT NULL,
    cd_cargo INTEGER NOT NULL,
    ds_cargo VARCHAR(50) NOT NULL,
    nr_votavel INTEGER NOT NULL,
    nm_votavel VARCHAR(100) NOT NULL,
    qt_votos INTEGER NOT NULL DEFAULT 0,
    nr_local_votacao INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(ano_eleicao, nr_turno, sg_uf, cd_municipio, nr_zona, nr_secao, cd_cargo, nr_votavel)
);

-- Índices para consultas rápidas
CREATE INDEX idx_votos_ano ON votos_secao(ano_eleicao);
CREATE INDEX idx_votos_uf ON votos_secao(sg_uf);
CREATE INDEX idx_votos_municipio ON votos_secao(cd_municipio);
CREATE INDEX idx_votos_candidato ON votos_secao(nr_votavel);
CREATE INDEX idx_votos_cargo ON votos_secao(cd_cargo);
CREATE INDEX idx_votos_local ON votos_secao(nr_local_votacao);

-- ============================================
-- Obras Públicas (com triangulação)
-- ============================================
CREATE TABLE obras (
    id BIGSERIAL PRIMARY KEY,
    titulo VARCHAR(200) NOT NULL,
    descricao TEXT,
    latitude DECIMAL(12, 8) NOT NULL,
    longitude DECIMAL(12, 8) NOT NULL,
    geom GEOMETRY(POINT, 4326),
    bairro VARCHAR(100),
    
    -- Triangulação de evidências
    foto_oficio_url TEXT,
    foto_oficio_ocr TEXT,
    numero_chamado_1746 VARCHAR(50),
    diario_oficial_ref VARCHAR(100),
    data_oficio DATE,
    data_chamado_1746 DATE,
    data_diario_oficial DATE,
    
    -- Status e validação
    status VARCHAR(20) DEFAULT 'pendente' CHECK (status IN ('pendente', 'validado', 'apadrinhado', 'refutado')),
    politico_associado VARCHAR(100),
    score_triangulacao INTEGER DEFAULT 0,
    
    -- Metadados
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_obras_geom ON obras USING GIST(geom);
CREATE INDEX idx_obras_status ON obras(status);
CREATE INDEX idx_obras_bairro ON obras(bairro);

CREATE TRIGGER trigger_update_geom_obras
BEFORE INSERT OR UPDATE ON obras
FOR EACH ROW EXECUTE FUNCTION update_geom_from_latlon();

-- ============================================
-- Chamados 1746
-- ============================================
CREATE TABLE chamados_1746 (
    id BIGSERIAL PRIMARY KEY,
    numero_chamado VARCHAR(50) UNIQUE NOT NULL,
    tipo VARCHAR(100) NOT NULL,
    subtipo VARCHAR(100),
    descricao TEXT,
    latitude DECIMAL(12, 8),
    longitude DECIMAL(12, 8),
    geom GEOMETRY(POINT, 4326),
    bairro VARCHAR(100),
    data_abertura TIMESTAMPTZ NOT NULL,
    data_fechamento TIMESTAMPTZ,
    status VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_chamados_geom ON chamados_1746 USING GIST(geom);
CREATE INDEX idx_chamados_tipo ON chamados_1746(tipo);
CREATE INDEX idx_chamados_data ON chamados_1746(data_abertura);

CREATE TRIGGER trigger_update_geom_chamados
BEFORE INSERT OR UPDATE ON chamados_1746
FOR EACH ROW EXECUTE FUNCTION update_geom_from_latlon();

-- ============================================
-- Histórico de Nomeações (PREMIUM)
-- ============================================
CREATE TABLE historico_nomeacoes (
    id BIGSERIAL PRIMARY KEY,
    nome_completo VARCHAR(200) NOT NULL,
    cpf_hash VARCHAR(64), -- Hash para anonimização
    cargo VARCHAR(100) NOT NULL,
    orgao VARCHAR(200),
    tipo_nomeacao VARCHAR(50) CHECK (tipo_nomeacao IN ('efetivo', 'comissionado', 'temporario')),
    data_nomeacao DATE NOT NULL,
    data_exoneracao DATE,
    diario_oficial_ref VARCHAR(100),
    politico_indicador VARCHAR(100),
    partido VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Flag premium
    is_premium BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_nomeacoes_nome ON historico_nomeacoes(nome_completo);
CREATE INDEX idx_nomeacoes_orgao ON historico_nomeacoes(orgao);
CREATE INDEX idx_nomeacoes_politico ON historico_nomeacoes(politico_indicador);

-- ============================================
-- 3. VIEWS MATERIALIZADAS (Performance)
-- ============================================

-- Agregação de votos por candidato/município
CREATE MATERIALIZED VIEW mv_votos_agregados AS
SELECT 
    ano_eleicao,
    sg_uf,
    cd_municipio,
    nm_municipio,
    cd_cargo,
    ds_cargo,
    nr_votavel,
    nm_votavel,
    SUM(qt_votos) as total_votos,
    COUNT(DISTINCT nr_secao) as total_secoes
FROM votos_secao
GROUP BY ano_eleicao, sg_uf, cd_municipio, nm_municipio, cd_cargo, ds_cargo, nr_votavel, nm_votavel;

CREATE UNIQUE INDEX idx_mv_votos_agg ON mv_votos_agregados(ano_eleicao, cd_municipio, cd_cargo, nr_votavel);

-- ============================================
-- 4. FUNÇÕES RPC PARA O FLUTTER
-- ============================================

-- Votos agregados por candidato
CREATE OR REPLACE FUNCTION votos_agregados_por_candidato(
    p_ano_eleicao INTEGER,
    p_cd_municipio INTEGER,
    p_cd_cargo INTEGER
)
RETURNS TABLE(nm_votavel TEXT, total_votos BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        vs.nm_votavel::TEXT,
        SUM(vs.qt_votos)::BIGINT
    FROM votos_secao vs
    WHERE vs.ano_eleicao = p_ano_eleicao
      AND vs.cd_municipio = p_cd_municipio
      AND vs.cd_cargo = p_cd_cargo
    GROUP BY vs.nm_votavel
    ORDER BY SUM(vs.qt_votos) DESC;
END;
$$ LANGUAGE plpgsql;

-- Heatmap de votos para um candidato
CREATE OR REPLACE FUNCTION heatmap_votos_candidato(
    p_ano_eleicao INTEGER,
    p_cd_municipio INTEGER,
    p_nr_votavel INTEGER
)
RETURNS TABLE(latitude DECIMAL, longitude DECIMAL, qt_votos INTEGER, weight DECIMAL) AS $$
DECLARE
    max_votos DECIMAL;
BEGIN
    -- Calcula o máximo para normalização
    SELECT MAX(vs.qt_votos)::DECIMAL INTO max_votos
    FROM votos_secao vs
    JOIN locais_votacao lv ON vs.nr_local_votacao = lv.nr_local_votacao 
                           AND vs.sg_uf = lv.sg_uf
    WHERE vs.ano_eleicao = p_ano_eleicao
      AND vs.cd_municipio = p_cd_municipio
      AND vs.nr_votavel = p_nr_votavel;
    
    IF max_votos IS NULL OR max_votos = 0 THEN
        max_votos := 1;
    END IF;
    
    RETURN QUERY
    SELECT 
        lv.latitude,
        lv.longitude,
        vs.qt_votos,
        (vs.qt_votos::DECIMAL / max_votos) as weight
    FROM votos_secao vs
    JOIN locais_votacao lv ON vs.nr_local_votacao = lv.nr_local_votacao 
                           AND vs.sg_uf = lv.sg_uf
    WHERE vs.ano_eleicao = p_ano_eleicao
      AND vs.cd_municipio = p_cd_municipio
      AND vs.nr_votavel = p_nr_votavel
      AND lv.latitude IS NOT NULL
      AND lv.longitude IS NOT NULL;
END;
$$ LANGUAGE plpgsql;

-- Buscar locais de votação em bounding box
CREATE OR REPLACE FUNCTION locais_in_bounds(
    sw_lat DECIMAL,
    sw_lng DECIMAL,
    ne_lat DECIMAL,
    ne_lng DECIMAL
)
RETURNS SETOF locais_votacao AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM locais_votacao
    WHERE latitude BETWEEN sw_lat AND ne_lat
      AND longitude BETWEEN sw_lng AND ne_lng;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 5. ROW LEVEL SECURITY (RLS)
-- ============================================

-- Habilitar RLS nas tabelas
ALTER TABLE locais_votacao ENABLE ROW LEVEL SECURITY;
ALTER TABLE votos_secao ENABLE ROW LEVEL SECURITY;
ALTER TABLE obras ENABLE ROW LEVEL SECURITY;
ALTER TABLE chamados_1746 ENABLE ROW LEVEL SECURITY;
ALTER TABLE historico_nomeacoes ENABLE ROW LEVEL SECURITY;

-- Políticas para locais_votacao (leitura pública)
CREATE POLICY "Leitura pública de locais de votação"
ON locais_votacao FOR SELECT
TO public
USING (true);

-- Políticas para votos_secao (leitura pública)
CREATE POLICY "Leitura pública de votos"
ON votos_secao FOR SELECT
TO public
USING (true);

-- Políticas para obras
CREATE POLICY "Leitura pública de obras"
ON obras FOR SELECT
TO public
USING (true);

CREATE POLICY "Inserção de obras autenticada"
ON obras FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Atualização de obras pelo criador"
ON obras FOR UPDATE
TO authenticated
USING (auth.uid() = created_by);

-- Políticas para chamados_1746
CREATE POLICY "Leitura de chamados autenticada"
ON chamados_1746 FOR SELECT
TO authenticated
USING (true);

-- Políticas para histórico_nomeacoes (PREMIUM)
CREATE POLICY "Leitura de nomeações premium"
ON historico_nomeacoes FOR SELECT
TO authenticated
USING (
    -- Verifica se usuário tem assinatura premium
    EXISTS (
        SELECT 1 FROM auth.users u
        JOIN public.user_subscriptions s ON u.id = s.user_id
        WHERE u.id = auth.uid() 
          AND s.plan = 'premium' 
          AND s.status = 'active'
    )
    OR is_premium = FALSE
);

-- ============================================
-- 6. TABELA DE ASSINATURAS (para RLS premium)
-- ============================================
CREATE TABLE user_subscriptions (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) UNIQUE NOT NULL,
    plan VARCHAR(20) DEFAULT 'free' CHECK (plan IN ('free', 'premium', 'enterprise')),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'canceled', 'expired')),
    started_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuário vê própria assinatura"
ON user_subscriptions FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- ============================================
-- 7. COMENTÁRIOS PARA DOCUMENTAÇÃO
-- ============================================
COMMENT ON TABLE locais_votacao IS 'Locais de votação com geolocalização do TSE';
COMMENT ON TABLE votos_secao IS 'Votos agregados por seção eleitoral (LGPD compliant)';
COMMENT ON TABLE obras IS 'Obras públicas com sistema de triangulação de evidências';
COMMENT ON TABLE chamados_1746 IS 'Chamados do serviço 1746 da Prefeitura';
COMMENT ON TABLE historico_nomeacoes IS 'Histórico de nomeações do Diário Oficial (Premium)';
