-- ============================================
-- GEONEXUS V4 - VIEW MAPA GERAL
-- View otimizada para plotagem no mapa
-- ============================================

-- DROP VIEW IF EXISTS view_mapa_geral;

-- ============================================
-- VIEW MAPA GERAL
-- ============================================
-- Agrega votos por local de votação para evitar
-- carregar milhões de registros individuais.
-- 
-- Campos retornados:
--   id: ID do local de votação
--   nr_latitude: Latitude para o marcador
--   nr_longitude: Longitude para o marcador
--   nm_local_votacao: Nome do local (título do marcador)
--   nm_bairro: Bairro do local
--   nm_municipio: Nome do município
--   sg_uf: Sigla do estado
--   total_votos: Soma de todos os votos do local
--   total_secoes: Quantidade de seções no local
--   total_candidatos: Candidatos distintos que receberam votos
-- ============================================

CREATE OR REPLACE VIEW view_mapa_geral AS
SELECT 
    lv.id,
    lv.latitude AS nr_latitude,
    lv.longitude AS nr_longitude,
    lv.nm_local_votacao,
    lv.nm_bairro,
    lv.nm_municipio,
    lv.sg_uf,
    lv.ds_endereco,
    lv.acessibilidade,
    COALESCE(agg.total_votos, 0) AS total_votos,
    COALESCE(agg.total_secoes, 0) AS total_secoes,
    COALESCE(agg.total_candidatos, 0) AS total_candidatos
FROM locais_votacao lv
LEFT JOIN (
    SELECT 
        nr_local_votacao,
        sg_uf,
        cd_municipio,
        SUM(qt_votos) AS total_votos,
        COUNT(DISTINCT nr_secao) AS total_secoes,
        COUNT(DISTINCT nr_votavel) AS total_candidatos
    FROM votos_secao
    GROUP BY nr_local_votacao, sg_uf, cd_municipio
) agg ON lv.nr_local_votacao = agg.nr_local_votacao 
     AND lv.sg_uf = agg.sg_uf
     AND lv.cd_municipio = agg.cd_municipio
WHERE lv.latitude IS NOT NULL 
  AND lv.longitude IS NOT NULL;

-- ============================================
-- ÍNDICES PARA PERFORMANCE DA VIEW
-- ============================================
-- A view usa os índices já existentes em locais_votacao:
--   idx_locais_votacao_latlon
--   idx_locais_votacao_uf
-- 
-- Para melhor performance, adicione index no votos_secao:
CREATE INDEX IF NOT EXISTS idx_votos_local_uf_municipio 
ON votos_secao(nr_local_votacao, sg_uf, cd_municipio);

-- ============================================
-- RLS POLICY (Leitura Pública)
-- ============================================
-- Views herdam as políticas das tabelas base,
-- porém para garantir acesso anônimo ao mapa:

-- Se a view não funcionar com RLS, criar função RPC:
CREATE OR REPLACE FUNCTION get_mapa_geral(
    p_uf VARCHAR DEFAULT NULL,
    p_limit INTEGER DEFAULT 1000
)
RETURNS TABLE(
    id BIGINT,
    nr_latitude DECIMAL,
    nr_longitude DECIMAL,
    nm_local_votacao VARCHAR,
    nm_bairro VARCHAR,
    nm_municipio VARCHAR,
    sg_uf VARCHAR,
    total_votos BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        v.id,
        v.nr_latitude,
        v.nr_longitude,
        v.nm_local_votacao::VARCHAR,
        v.nm_bairro::VARCHAR,
        v.nm_municipio::VARCHAR,
        v.sg_uf::VARCHAR,
        v.total_votos::BIGINT
    FROM view_mapa_geral v
    WHERE (p_uf IS NULL OR v.sg_uf = p_uf)
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FUNÇÃO DE BUSCA (Case Insensitive)
-- ============================================
CREATE OR REPLACE FUNCTION search_mapa_geral(
    p_query VARCHAR,
    p_limit INTEGER DEFAULT 1000
)
RETURNS TABLE(
    id BIGINT,
    nr_latitude DECIMAL,
    nr_longitude DECIMAL,
    nm_local_votacao VARCHAR,
    nm_bairro VARCHAR,
    nm_municipio VARCHAR,
    sg_uf VARCHAR,
    total_votos BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        v.id,
        v.nr_latitude,
        v.nr_longitude,
        v.nm_local_votacao::VARCHAR,
        v.nm_bairro::VARCHAR,
        v.nm_municipio::VARCHAR,
        v.sg_uf::VARCHAR,
        v.total_votos::BIGINT
    FROM view_mapa_geral v
    WHERE v.nm_local_votacao ILIKE '%' || p_query || '%'
       OR v.nm_bairro ILIKE '%' || p_query || '%'
       OR v.nm_municipio ILIKE '%' || p_query || '%'
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- COMENTÁRIOS
-- ============================================
COMMENT ON VIEW view_mapa_geral IS 'View otimizada para plotagem no mapa do GeoNexus. Agrega votos por local de votação.';
COMMENT ON FUNCTION get_mapa_geral IS 'RPC para buscar locais do mapa com filtro por UF (bypass RLS)';
COMMENT ON FUNCTION search_mapa_geral IS 'RPC para buscar locais por nome/bairro (case insensitive)';
