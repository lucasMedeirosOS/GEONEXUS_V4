import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/local_votacao.dart';
import '../../domain/entities/voto_secao.dart';
import '../../domain/entities/obra.dart';
import '../../domain/entities/obra_acao.dart';
import '../../domain/entities/resumo_geonexus.dart';
import '../../domain/entities/map_pin.dart';
import '../../domain/repositories/eleitoral_repository.dart';
import '../../domain/repositories/obras_repository.dart';
import '../models/local_votacao_model.dart';
import '../models/voto_secao_model.dart';
import '../models/resumo_geonexus_model.dart';
import '../models/map_pin_model.dart';
import '../models/obra_acao_model.dart';
import '../models/dashboard_stats.dart';
import '../models/team_member.dart';
import '../models/radar_oportunidade.dart';

/// Implementação concreta do repositório usando Supabase
/// 
/// Esta classe conecta ao backend Supabase e executa as queries
/// de votos, locais de votação e obras.
class SupabaseRepositoryImpl implements EleitoralRepository {
  final SupabaseClient _client;

  SupabaseRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ============================================
  // VOTOS POR ESTADO - Query Principal
  // ============================================

  /// Busca votos por estado (UF) com limite para performance
  /// 
  /// Query: SELECT * FROM votos_secao WHERE sg_uf = 'RJ' LIMIT 2000
  Future<Either<String, List<VotoSecao>>> getVotosPorEstado(String uf) async {
    try {
      final response = await _client
          .from('votos_secao')
          .select()
          .eq('sg_uf', uf.toUpperCase())
          .limit(2000);

      final votos = (response as List)
          .map((json) => VotoSecaoModel.fromJson(json))
          .toList();

      return Right(votos);
    } on PostgrestException catch (e) {
      return Left('Erro no banco de dados: ${e.message}');
    } catch (e) {
      return Left('Erro ao buscar votos do estado $uf: $e');
    }
  }

  // ============================================
  // IMPLEMENTAÇÕES DO EleitoralRepository
  // ============================================

  @override
  Future<Either<String, List<LocalVotacao>>> getLocaisVotacao({
    required String uf,
    int? cdMunicipio,
  }) async {
    print('');
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║  🔍 DEBUG MODE - DIAGNÓSTICO SUPABASE                        ║');
    print('╠══════════════════════════════════════════════════════════════╣');
    print('║  --- INICIANDO BUSCA NO SUPABASE ---                         ║');
    print('║  BUSCANDO ESTADO: ${uf.toUpperCase().padRight(41)}║');
    print('║  TABELA: locais_votacao                                      ║');
    print('║  LIMITE: 500 registros                                       ║');
    print('╚══════════════════════════════════════════════════════════════╝');
    print('');
    
    try {
      var query = _client
          .from('locais_votacao')
          .select()
          .eq('sg_uf', uf.toUpperCase());

      if (cdMunicipio != null) {
        print('📍 FILTRO MUNICÍPIO: $cdMunicipio');
        query = query.eq('cd_municipio', cdMunicipio);
      }

      print('⏳ Executando query no Supabase...');
      final response = await query.limit(500);
      print('✅ Query executada com sucesso!');
      print('📊 Tipo da resposta: ${response.runtimeType}');
      print('📊 Quantidade de registros brutos: ${(response as List).length}');
      
      if ((response).isEmpty) {
        print('');
        print('⚠️ ═══════════════════════════════════════════════════════════');
        print('⚠️  ALERTA: NENHUM REGISTRO RETORNADO!');
        print('⚠️  Possíveis causas:');
        print('⚠️  1. Tabela locais_votacao está vazia');
        print('⚠️  2. Não há registros para UF=$uf');
        print('⚠️  3. Policies RLS bloqueando acesso');
        print('⚠️  4. Problema de autenticação anônima');
        print('⚠️ ═══════════════════════════════════════════════════════════');
        print('');
      } else {
        print('📋 Primeiro registro (amostra): ${response.first}');
      }

      final locais = (response)
          .map((json) => LocalVotacaoModel.fromJson(json))
          .toList();

      print('');
      print('╔══════════════════════════════════════════════════════════════╗');
      print('║  ✅ SUCESSO! LOCAIS ENCONTRADOS: ${locais.length.toString().padRight(25)}║');
      print('╚══════════════════════════════════════════════════════════════╝');
      print('');

      return Right(locais);
    } on PostgrestException catch (e) {
      print('');
      print('╔══════════════════════════════════════════════════════════════╗');
      print('║  ❌ ERRO CRÍTICO SUPABASE (PostgrestException)               ║');
      print('╠══════════════════════════════════════════════════════════════╣');
      print('║  Código: ${e.code?.padRight(51) ?? 'N/A'.padRight(51)}║');
      print('║  Mensagem: ${e.message.substring(0, e.message.length > 49 ? 49 : e.message.length).padRight(49)}║');
      print('║  Detalhes: ${e.details?.toString().substring(0, 49).padRight(49) ?? 'N/A'.padRight(49)}║');
      print('╚══════════════════════════════════════════════════════════════╝');
      print('');
      return Left('Erro no banco de dados: ${e.message}');
    } catch (e) {
      print('');
      print('╔══════════════════════════════════════════════════════════════╗');
      print('║  ❌ ERRO CRÍTICO SUPABASE (Exception)                        ║');
      print('╠══════════════════════════════════════════════════════════════╣');
      print('║  $e');
      print('╚══════════════════════════════════════════════════════════════╝');
      print('');
      return Left('Erro ao buscar locais: $e');
    }
  }

  @override
  Future<Either<String, List<LocalVotacao>>> getLocaisVotacaoByBounds({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
  }) async {
    try {
      final response = await _client
          .from('locais_votacao')
          .select()
          .gte('latitude', swLat)
          .lte('latitude', neLat)
          .gte('longitude', swLng)
          .lte('longitude', neLng)
          .limit(1000);

      final locais = (response as List)
          .map((json) => LocalVotacaoModel.fromJson(json))
          .toList();

      return Right(locais);
    } on PostgrestException catch (e) {
      return Left('Erro no banco de dados: ${e.message}');
    } catch (e) {
      return Left('Erro ao buscar locais por bounds: $e');
    }
  }

  @override
  Future<Either<String, List<VotoSecao>>> getVotosSecao({
    required int anoEleicao,
    required String uf,
    int? cdMunicipio,
    int? nrZona,
    int? nrSecao,
    int? cdCargo,
  }) async {
    try {
      var query = _client
          .from('votos_secao')
          .select()
          .eq('ano_eleicao', anoEleicao)
          .eq('sg_uf', uf.toUpperCase());

      if (cdMunicipio != null) {
        query = query.eq('cd_municipio', cdMunicipio);
      }
      if (nrZona != null) {
        query = query.eq('nr_zona', nrZona);
      }
      if (nrSecao != null) {
        query = query.eq('nr_secao', nrSecao);
      }
      if (cdCargo != null) {
        query = query.eq('cd_cargo', cdCargo);
      }

      final response = await query.limit(2000);

      final votos = (response as List)
          .map((json) => VotoSecaoModel.fromJson(json))
          .toList();

      return Right(votos);
    } on PostgrestException catch (e) {
      return Left('Erro no banco de dados: ${e.message}');
    } catch (e) {
      return Left('Erro ao buscar votos: $e');
    }
  }

  @override
  Future<Either<String, Map<String, int>>> getVotosPorCandidato({
    required int anoEleicao,
    required int cdMunicipio,
    required int cdCargo,
  }) async {
    try {
      final response = await _client.rpc(
        'votos_agregados_por_candidato',
        params: {
          'p_ano_eleicao': anoEleicao,
          'p_cd_municipio': cdMunicipio,
          'p_cd_cargo': cdCargo,
        },
      );

      final Map<String, int> result = {};
      for (final row in response as List) {
        result[row['nm_votavel'] as String] = row['total_votos'] as int;
      }
      return Right(result);
    } on PostgrestException catch (e) {
      return Left('Erro no banco de dados: ${e.message}');
    } catch (e) {
      return Left('Erro ao agregar votos: $e');
    }
  }

  @override
  Future<Either<String, List<Map<String, dynamic>>>> getHeatmapVotos({
    required int anoEleicao,
    required int cdMunicipio,
    required int nrVotavel,
  }) async {
    try {
      final response = await _client.rpc(
        'heatmap_votos_candidato',
        params: {
          'p_ano_eleicao': anoEleicao,
          'p_cd_municipio': cdMunicipio,
          'p_nr_votavel': nrVotavel,
        },
      );

      return Right(List<Map<String, dynamic>>.from(response));
    } on PostgrestException catch (e) {
      return Left('Erro no banco de dados: ${e.message}');
    } catch (e) {
      return Left('Erro ao gerar heatmap: $e');
    }
  }

  // ============================================
  // QUERIES COM JOIN (Votos + Locais)
  // ============================================

  /// Busca votos com coordenadas para plotar no mapa
  Future<Either<String, List<Map<String, dynamic>>>> getVotosComCoordenadas({
    required String uf,
    int? cdMunicipio,
    int? cdCargo,
  }) async {
    try {
      // Join entre votos_secao e locais_votacao
      var query = _client
          .from('votos_secao')
          .select('''
            *,
            locais_votacao!inner(latitude, longitude, nm_local_votacao)
          ''')
          .eq('sg_uf', uf.toUpperCase());

      if (cdMunicipio != null) {
        query = query.eq('cd_municipio', cdMunicipio);
      }
      if (cdCargo != null) {
        query = query.eq('cd_cargo', cdCargo);
      }

      final response = await query.limit(1000);

      return Right(List<Map<String, dynamic>>.from(response));
    } on PostgrestException catch (e) {
      return Left('Erro no banco de dados: ${e.message}');
    } catch (e) {
      return Left('Erro ao buscar votos com coordenadas: $e');
    }
  }

  // ============================================
  // DASHBOARD MAPA - RPC Otimizada
  // ============================================

  /// Busca anos de eleição disponíveis no banco
  /// 
  /// Retorna lista de anos ordenados (mais recente primeiro).
  /// Usa RPC otimizada ou fallback para valores padrão.
  Future<Either<String, List<int>>> getAnosDisponiveis() async {
    print('');
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║  🔍 GEONEXUS - BUSCANDO ANOS DISPONÍVEIS                     ║');
    print('╚══════════════════════════════════════════════════════════════╝');
    print('');

    try {
      // Tenta RPC otimizada primeiro
      final response = await _client.rpc('get_anos_disponiveis');
      
      final anos = (response as List)
          .map((r) => r is int ? r : (r['ano'] as int))
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a)); // Mais recente primeiro

      print('✅ Anos disponíveis: $anos');
      return Right(anos);
    } on PostgrestException catch (e) {
      print('⚠️ RPC get_anos_disponiveis não existe, usando fallback: ${e.message}');
      // Fallback para anos padrão
      return const Right([2024, 2022, 2020, 2018]);
    } catch (e) {
      print('❌ Erro ao buscar anos: $e');
      return const Right([2024, 2022, 2020, 2018]);
    }
  }

  /// Busca cargos disponíveis para um ano específico
  /// 
  /// Retorna lista de cargos (ex: PREFEITO, VEREADOR, GOVERNADOR).
  Future<Either<String, List<String>>> getCargosPorAno(int ano) async {
    print('');
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║  🔍 GEONEXUS - BUSCANDO CARGOS PARA ANO $ano                  ║');
    print('╚══════════════════════════════════════════════════════════════╝');
    print('');

    try {
      // Tenta RPC otimizada primeiro
      final response = await _client.rpc(
        'get_cargos_por_ano',
        params: {'p_ano': ano},
      );
      
      final cargos = (response as List)
          .map((r) => r is String ? r : (r['cargo'] as String))
          .toSet()
          .toList();

      print('✅ Cargos para $ano: $cargos');
      return Right(cargos);
    } on PostgrestException catch (e) {
      print('⚠️ RPC get_cargos_por_ano não existe, usando fallback: ${e.message}');
      // Fallback baseado no ano (municipal vs estadual/federal)
      // NOTA: Banco usa title case (Prefeito, Vereador)
      if (ano % 4 == 0 && ano % 2 == 0) {
        // Anos divisíveis por 4: eleição municipal
        return const Right(['Prefeito', 'Vereador']);
      } else {
        // Anos ímpares de eleição: estadual/federal
        return const Right(['Governador', 'Senador', 'Deputado Federal', 'Deputado Estadual']);
      }
    } catch (e) {
      print('❌ Erro ao buscar cargos: $e');
      return const Right(['Prefeito', 'Vereador']);
    }
  }

  /// Busca bairros disponíveis para um ano e cargo específicos
  /// 
  /// Retorna lista de bairros (strings) para popular o dropdown de filtro.
  /// Usa a RPC get_bairros_disponiveis.
  /// 
  /// Em caso de erro ou timeout, retorna lista vazia (não quebra a aplicação).
  Future<Either<String, List<String>>> getBairrosDisponiveis({
    required int ano,
    required String cargo,
  }) async {
    print('');
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║  🔍 GEONEXUS - BUSCANDO BAIRROS DISPONÍVEIS                  ║');
    print('╠══════════════════════════════════════════════════════════════╣');
    print('║  ANO: ${ano.toString().padRight(53)}║');
    print('║  CARGO: ${cargo.padRight(51)}║');
    print('╚══════════════════════════════════════════════════════════════╝');
    print('');

    try {
      // Timeout de 10 segundos para não travar a UI
      final response = await _client.rpc(
        'get_bairros_disponiveis',
        params: {
          'p_ano': ano,
          'p_cargo': cargo,
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ Timeout ao buscar bairros (10s)');
          return []; // Retorna lista vazia em caso de timeout
        },
      );

      // Se response for null ou não for lista, retorna vazio
      if (response == null) {
        print('⚠️ Resposta nula da RPC');
        return const Right([]);
      }

      final List<dynamic> responseList = response is List ? response : [];
      
      final bairros = responseList
          .map((r) => r is String ? r : (r['nm_bairro'] as String? ?? ''))
          .where((b) => b.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      print('✅ Bairros disponíveis: ${bairros.length}');
      if (bairros.isNotEmpty) {
        print('📋 Primeiros bairros: ${bairros.take(5).join(', ')}');
      }

      return Right(bairros);
    } on PostgrestException catch (e) {
      print('⚠️ RPC get_bairros_disponiveis erro: ${e.message}');
      return const Right([]); // Retorna lista vazia como fallback
    } catch (e) {
      print('❌ Erro ao buscar bairros: $e');
      return const Right([]); // Nunca quebra a aplicação
    }
  }

  /// Busca o ranking de candidatos para um local de votação específico
  /// 
  /// Retorna lista ordenada por votos (do maior para o menor).
  /// Usado no "Raio-X do Local" para mostrar todos os candidatos.
  /// 
  /// Parâmetros:
  /// - ano: Ano da eleição
  /// - cargo: Cargo eleitoral (Prefeito, Vereador, etc)
  /// - localVotacao: Nome exato do local de votação
  /// 
  /// Retorno: Lista de {nome_candidato: String, total_votos: int}
  Future<Either<String, List<Map<String, dynamic>>>> getRankingLocal({
    required int ano,
    required String cargo,
    required String localVotacao,
  }) async {
    print('');
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║  🏆 GEONEXUS - RAIO-X DO LOCAL (RANKING)                     ║');
    print('╠══════════════════════════════════════════════════════════════╣');
    print('║  ANO: ${ano.toString().padRight(53)}║');
    print('║  CARGO: ${cargo.padRight(51)}║');
    print('║  LOCAL: ${localVotacao.substring(0, localVotacao.length > 50 ? 50 : localVotacao.length).padRight(51)}║');
    print('╚══════════════════════════════════════════════════════════════╝');
    print('');

    try {
      final response = await _client.rpc(
        'get_ranking_local',
        params: {
          'p_ano': ano,
          'p_cargo': cargo,
          'p_local_votacao': localVotacao,
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⏱️ Timeout ao buscar ranking (15s)');
          return [];
        },
      );

      if (response == null) {
        print('⚠️ Resposta nula da RPC get_ranking_local');
        return const Right([]);
      }

      final List<dynamic> responseList = response is List ? response : [];
      
      // Converte para lista tipada
      final ranking = responseList.map((r) => {
        'nome_candidato': r['nome_candidato'] as String? ?? 'Desconhecido',
        'total_votos': (r['total_votos'] as num?)?.toInt() ?? 0,
      }).toList();

      print('✅ Ranking carregado: ${ranking.length} candidatos');
      if (ranking.isNotEmpty) {
        print('🥇 1º: ${ranking.first['nome_candidato']} (${ranking.first['total_votos']} votos)');
      }

      return Right(ranking);
    } on PostgrestException catch (e) {
      print('⚠️ RPC get_ranking_local erro: ${e.message}');
      return Left('Erro ao buscar ranking: ${e.message}');
    } catch (e) {
      print('❌ Erro ao buscar ranking: $e');
      return Left('Erro ao buscar ranking: $e');
    }
  }

  /// Sugestões de candidatos para autocomplete (a partir de 3 letras)
  /// 
  /// Chamado enquanto o usuário digita na barra de busca.
  /// Usa a RPC suggest_candidatos que retorna até 10 sugestões.
  /// 
  /// Parâmetros:
  /// - termo: Texto digitado pelo usuário (mínimo 3 caracteres)
  /// - ano: Ano da eleição selecionado
  /// - cargo: Cargo selecionado
  Future<Either<String, List<String>>> getSuggestCandidatos({
    required String termo,
    required int ano,
    required String cargo,
  }) async {
    // Não busca se termo tiver menos de 3 caracteres
    if (termo.length < 3) {
      return const Right([]);
    }

    print('');
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║  🔍 GEONEXUS - AUTOCOMPLETE CANDIDATOS                       ║');
    print('╠══════════════════════════════════════════════════════════════╣');
    print('║  TERMO: ${termo.padRight(51)}║');
    print('║  ANO: ${ano.toString().padRight(53)}║');
    print('║  CARGO: ${cargo.padRight(51)}║');
    print('╚══════════════════════════════════════════════════════════════╝');
    print('');

    try {
      final response = await _client.rpc(
        'suggest_candidatos',
        params: {
          'p_termo': termo,
          'p_ano': ano,
          'p_cargo': cargo,
        },
      );

      final sugestoes = (response as List)
          .map((r) => r['nome_candidato'] as String)
          .toList();

      print('✅ Sugestões encontradas: ${sugestoes.length}');
      if (sugestoes.isNotEmpty) {
        print('📋 Primeiras sugestões: ${sugestoes.take(3).join(', ')}');
      }

      return Right(sugestoes);
    } on PostgrestException catch (e) {
      print('❌ Erro RPC suggest_candidatos: ${e.message}');
      return Left('Erro ao buscar sugestões: ${e.message}');
    } catch (e) {
      print('❌ Erro ao buscar sugestões: $e');
      return Left('Erro ao buscar sugestões: $e');
    }
  }

  /// Busca pins do mapa usando RPC search_dashboard_mapa
  /// 
  /// Parâmetros obrigatórios:
  /// - ano: Ano da eleição (ex: 2024, 2022)
  /// - cargo: Cargo eleitoral (ex: 'Prefeito', 'Vereador')
  /// 
  /// Parâmetros opcionais:
  /// - search: Texto para filtrar por nome do candidato (ex: "Ronaldo")
  /// - bairro: Nome do bairro para filtrar (null = todos)
  /// - limit: Quantidade máxima de registros a retornar
  /// 
  /// Retorna lista de MapPin com coordenadas e total de votos.
  Future<Either<String, List<MapPin>>> getMapPins({
    required int ano,
    required String cargo,
    String? search,
    String? bairro,
    int? limit,
  }) async {
    print('');
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║  🔍 GEONEXUS - DASHBOARD MAPA (RPC)                          ║');
    print('╠══════════════════════════════════════════════════════════════╣');
    print('║  --- INICIANDO BUSCA NO SUPABASE ---                         ║');
    print('║  RPC: search_dashboard_mapa                                  ║');
    print('║  ANO: ${ano.toString().padRight(53)}║');
    print('║  CARGO: ${cargo.padRight(51)}║');
    if (bairro != null && bairro.isNotEmpty) {
      print('║  BAIRRO: ${bairro.padRight(50)}║');
    }
    if (search != null && search.isNotEmpty) {
      print('║  BUSCA: ${search.padRight(51)}║');
    }
    if (limit != null) {
      print('║  LIMIT: ${limit.toString().padRight(51)}║');
    }
    print('╚══════════════════════════════════════════════════════════════╝');
    print('');

    try {
      // Monta os parâmetros da RPC
      final Map<String, dynamic> rpcParams = {
        'p_ano': ano,
        'p_cargo': cargo,
      };
      
      // Adiciona parâmetros opcionais
      if (bairro != null && bairro.isNotEmpty) {
        rpcParams['p_bairro'] = bairro;
      }
      if (search != null && search.isNotEmpty) {
        rpcParams['p_search'] = search;
      }
      if (limit != null) {
        rpcParams['p_limit'] = limit;
      }
      
      print('⏳ Chamando RPC: search_dashboard_mapa($rpcParams)...');
      
      final response = await _client.rpc(
        'search_dashboard_mapa',
        params: rpcParams,
      );

      print('✅ RPC executada com sucesso!');
      print('📊 Tipo da resposta: ${response.runtimeType}');
      
      List<dynamic> results = response as List<dynamic>? ?? [];
      print('📊 Quantidade de registros: ${results.length}');

      // Se RPC retornou vazio, tenta fallback para view_mapa_geral
      if (results.isEmpty) {
        print('');
        print('⚠️ RPC retornou vazio. Tentando fallback para view_mapa_geral...');
        
        try {
          // Primeiro, vamos ver quais cargos existem na view
          final debugQuery = await _client
              .from('view_mapa_geral')
              .select('ds_cargo')
              .eq('ano_eleicao', ano)
              .limit(10);
          
          final cargosNaView = (debugQuery as List).map((r) => r['ds_cargo']).toSet().toList();
          print('📋 Cargos encontrados na view para $ano: $cargosNaView');
          
          // Agora busca com o cargo correto
          final fallbackResponse = await _client
              .from('view_mapa_geral')
              .select('*')
              .eq('ano_eleicao', ano)
              .eq('ds_cargo', cargo)
              .limit(2000);
          
          results = fallbackResponse as List<dynamic>? ?? [];
          print('📊 Fallback retornou: ${results.length} registros');
          
          if (results.isEmpty && cargosNaView.isNotEmpty) {
            // Tenta com o primeiro cargo disponível
            final cargoDisponivel = cargosNaView.first as String;
            print('⚠️ Cargo "$cargo" não encontrado. Tentando "$cargoDisponivel"...');
            
            final retryResponse = await _client
                .from('view_mapa_geral')
                .select('*')
                .eq('ano_eleicao', ano)
                .eq('ds_cargo', cargoDisponivel)
                .limit(2000);
            
            results = retryResponse as List<dynamic>? ?? [];
            print('📊 Retry com $cargoDisponivel retornou: ${results.length} registros');
          }
        } catch (fallbackError) {
          print('❌ Fallback falhou: $fallbackError');
        }
      }

      if (results.isEmpty) {
        print('');
        print('⚠️ ═══════════════════════════════════════════════════════════');
        print('⚠️  ALERTA: NENHUM REGISTRO RETORNADO!');
        print('⚠️  Verifique se há dados para ANO=$ano e CARGO=$cargo');
        print('⚠️ ═══════════════════════════════════════════════════════════');
        print('');
        return const Right([]);
      }

      // Mostra um registro de amostra para debug
      print('📋 Primeiro registro (amostra): ${results.first}');

      // Converte para objetos, filtrando registros com coordenadas nulas
      final List<MapPin> pins = [];
      int skippedCount = 0;

      for (final json in results) {
        final model = MapPinModel.fromJson(json);
        if (model != null) {
          pins.add(model);
        } else {
          skippedCount++;
        }
      }

      print('');
      print('╔══════════════════════════════════════════════════════════════╗');
      print('║  ✅ SUCESSO! DASHBOARD MAPA CARREGADO                        ║');
      print('╠══════════════════════════════════════════════════════════════╣');
      print('║  📍 Locais válidos: ${pins.length.toString().padRight(40)}║');
      print('║  ⚠️  Descartados (coords nulas): ${skippedCount.toString().padRight(27)}║');
      print('║  🗳️  Filtro: $cargo $ano'.padRight(61) + '║');
      print('╚══════════════════════════════════════════════════════════════╝');
      print('');

      return Right(pins);
    } on PostgrestException catch (e) {
      print('');
      print('╔══════════════════════════════════════════════════════════════╗');
      print('║  ❌ ERRO CRÍTICO SUPABASE (PostgrestException)               ║');
      print('╠══════════════════════════════════════════════════════════════╣');
      print('║  Código: ${e.code?.padRight(51) ?? 'N/A'.padRight(51)}║');
      print('║  Mensagem: ${e.message.substring(0, e.message.length > 49 ? 49 : e.message.length).padRight(49)}║');
      print('╚══════════════════════════════════════════════════════════════╝');
      print('');
      return Left('Erro no banco de dados: ${e.message}');
    } catch (e) {
      print('');
      print('╔══════════════════════════════════════════════════════════════╗');
      print('║  ❌ ERRO CRÍTICO SUPABASE (Exception)                        ║');
      print('╠══════════════════════════════════════════════════════════════╣');
      print('║  $e');
      print('╚══════════════════════════════════════════════════════════════╝');
      print('');
      return Left('Erro ao buscar locais: $e');
    }
  }

  /// Busca locais usando a RPC function search_mapa_geral com filtros
  /// 
  /// Parâmetros obrigatórios:
  /// - ano: Ano da eleição
  /// - cargo: Cargo eleitoral
  /// - searchText: texto para busca case-insensitive (opcional)
  /// 
  /// Se [searchText] estiver vazia, retorna todos os registros via getMapPins().
  Future<Either<String, List<MapPin>>> searchMapPins({
    required int ano,
    required String cargo,
    String searchText = '',
  }) async {
    // Se busca vazia, retorna todos com filtros
    if (searchText.trim().isEmpty) {
      return getMapPins(ano: ano, cargo: cargo);
    }

    print('');
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║  🔍 GEONEXUS - BUSCA COM FILTROS                             ║');
    print('╠══════════════════════════════════════════════════════════════╣');
    print('║  ANO: ${ano.toString().padRight(53)}║');
    print('║  CARGO: ${cargo.padRight(51)}║');
    print('║  BUSCA: ${searchText.padRight(51)}║');
    print('╚══════════════════════════════════════════════════════════════╝');
    print('');

    try {
      // Primeiro, busca os dados filtrados por ano/cargo
      final response = await _client.rpc(
        'search_dashboard_mapa',
        params: {
          'p_ano': ano,
          'p_cargo': cargo,
        },
      );

      print('✅ RPC executada com sucesso!');
      
      final List<dynamic> results = response as List<dynamic>? ?? [];
      
      // Filtra localmente pelo texto de busca (case-insensitive)
      // NOTA: nm_bairro foi removido do banco em 2026-01-06
      final filteredResults = results.where((json) {
        final nmLocal = (json['nm_local_votacao'] as String? ?? '').toLowerCase();
        final searchLower = searchText.toLowerCase();
        return nmLocal.contains(searchLower);
      }).toList();

      print('📊 Total registros: ${results.length}');
      print('📊 Após filtro de busca: ${filteredResults.length}');

      if (filteredResults.isEmpty) {
        print('⚠️ Nenhum registro encontrado para: "$searchText"');
        return const Right([]);
      }

      // Converte para objetos
      final List<MapPin> pins = [];
      int skippedCount = 0;

      for (final json in filteredResults) {
        final model = MapPinModel.fromJson(json);
        if (model != null) {
          pins.add(model);
        } else {
          skippedCount++;
          print('⚠️ Registro descartado (coords nulas): ${json['nm_local_votacao']}');
        }
      }

      print('');
      print('╔══════════════════════════════════════════════════════════════╗');
      print('║  ✅ BUSCA CONCLUÍDA                                          ║');
      print('╠══════════════════════════════════════════════════════════════╣');
      print('║  📍 Locais válidos: ${pins.length.toString().padRight(40)}║');
      print('║  ⚠️  Descartados (coords nulas): ${skippedCount.toString().padRight(27)}║');
      print('╚══════════════════════════════════════════════════════════════╝');
      print('');

      return Right(pins);
    } on PostgrestException catch (e) {
      print('');
      print('❌ ERRO SUPABASE RPC: ${e.code} - ${e.message}');
      print('');
      return Left('Erro na busca: ${e.message}');
    } catch (e) {
      print('');
      print('❌ ERRO GERAL: $e');
      print('');
      return Left('Erro ao buscar: $e');
    }
  }

  // ============================================
  // OBRAS/AÇÕES - CRUD
  // ============================================

  /// Cria uma nova obra/ação no banco de dados
  /// 
  /// O user_id é automaticamente definido como o usuário logado.
  /// Retorna a obra criada com ID ou erro.
  Future<Either<String, ObraAcao>> createObra(ObraAcaoModel obra) async {
    print('');
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║  🏗️ GEONEXUS - CADASTRO DE OBRA/AÇÃO                         ║');
    print('╠══════════════════════════════════════════════════════════════╣');
    print('║  TÍTULO: ${obra.titulo.padRight(50)}║');
    print('╚══════════════════════════════════════════════════════════════╝');
    print('');

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        print('❌ Usuário não autenticado');
        return const Left('Usuário não autenticado. Faça login para cadastrar obras.');
      }

      // Adiciona user_id ao mapa
      final data = obra.toMap();
      data['user_id'] = userId;

      final response = await _client
          .from('obras_acoes')
          .insert(data)
          .select()
          .single();

      final createdObra = ObraAcaoModel.fromJson(response);
      print('✅ Obra cadastrada com sucesso: ${createdObra.id}');

      return Right(createdObra);
    } on PostgrestException catch (e) {
      print('❌ Erro Postgrest: ${e.message}');
      return Left('Erro ao cadastrar obra: ${e.message}');
    } catch (e) {
      print('❌ Erro ao cadastrar obra: $e');
      return Left('Erro ao cadastrar obra: $e');
    }
  }

  /// Lista obras/ações do usuário logado
  /// 
  /// Retorna apenas as obras criadas pelo usuário atual.
  Future<Either<String, List<ObraAcao>>> getMinhasObras() async {
    print('🔍 Buscando minhas obras...');

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Left('Usuário não autenticado');
      }

      final response = await _client
          .from('obras_acoes')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final obras = (response as List)
          .map((json) => ObraAcaoModel.fromJson(json))
          .toList();

      print('✅ ${obras.length} obras encontradas');

      return Right(obras);
    } on PostgrestException catch (e) {
      print('❌ Erro Postgrest: ${e.message}');
      return Left('Erro ao buscar obras: ${e.message}');
    } catch (e) {
      print('❌ Erro ao buscar obras: $e');
      return Left('Erro ao buscar obras: $e');
    }
  }

  /// Atualiza uma obra existente
  /// 
  /// O ID da obra deve ser válido e pertencer ao usuário.
  Future<Either<String, ObraAcao>> updateObra(ObraAcaoModel obra) async {
    print('');
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║  ✏️ GEONEXUS - ATUALIZANDO OBRA                               ║');
    print('╠══════════════════════════════════════════════════════════════╣');
    print('║  TÍTULO: ${obra.titulo.padRight(50)}║');
    print('╚══════════════════════════════════════════════════════════════╝');
    print('');

    try {
      if (obra.id == null) {
        return const Left('ID da obra não informado');
      }

      final data = obra.toMap();
      // Remove campos que não devem ser atualizados
      data.remove('user_id');
      data.remove('created_at');

      final response = await _client
          .from('obras_acoes')
          .update(data)
          .eq('id', obra.id!)
          .select()
          .single();

      final updatedObra = ObraAcaoModel.fromJson(response);
      print('✅ Obra atualizada com sucesso');

      return Right(updatedObra);
    } on PostgrestException catch (e) {
      print('❌ Erro Postgrest: ${e.message}');
      return Left('Erro ao atualizar obra: ${e.message}');
    } catch (e) {
      print('❌ Erro ao atualizar obra: $e');
      return Left('Erro ao atualizar obra: $e');
    }
  }

  /// Exclui uma obra pelo ID
  /// 
  /// A RLS garante que apenas o dono pode excluir.
  Future<Either<String, bool>> deleteObra(String obraId) async {
    print('');
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║  🗑️ GEONEXUS - EXCLUINDO OBRA                                 ║');
    print('╚══════════════════════════════════════════════════════════════╝');
    print('');

    try {
      await _client
          .from('obras_acoes')
          .delete()
          .eq('id', obraId);

      print('✅ Obra excluída com sucesso: $obraId');

      return const Right(true);
    } on PostgrestException catch (e) {
      print('❌ Erro Postgrest: ${e.message}');
      return Left('Erro ao excluir obra: ${e.message}');
    } catch (e) {
      print('❌ Erro ao excluir obra: $e');
      return Left('Erro ao excluir obra: $e');
    }
  }

  /// Busca todas as obras com coordenadas para exibir no mapa
  /// 
  /// Filtra apenas obras que possuem latitude e longitude válidas.
  Future<Either<String, List<ObraAcao>>> getObrasPins() async {
    print('');
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║  🏗️ GEONEXUS - BUSCANDO OBRAS PARA O MAPA                    ║');
    print('╚══════════════════════════════════════════════════════════════╝');
    print('');

    try {
      final response = await _client
          .from('obras_acoes')
          .select('''
            id,
            user_id,
            titulo,
            descricao,
            ruas_atendidas,
            padrinho_vereador,
            padrinho_prefeito,
            familias_beneficiadas,
            pessoas_beneficiadas,
            latitude,
            longitude,
            status,
            created_at
          ''')
          .not('latitude', 'is', null)
          .not('longitude', 'is', null)
          .order('created_at', ascending: false);

      final obras = (response as List)
          .map((json) => ObraAcaoModel.fromJson(json))
          .where((obra) => obra.hasLocation)
          .toList();

      print('✅ ${obras.length} obras com localização encontradas');
      if (obras.isNotEmpty) {
        print('📍 Primeira: ${obras.first.titulo}');
      }

      return Right(obras);
    } on PostgrestException catch (e) {
      print('❌ Erro Postgrest: ${e.message}');
      return Left('Erro ao buscar obras: ${e.message}');
    } catch (e) {
      print('❌ Erro ao buscar obras: $e');
      return Left('Erro ao buscar obras: $e');
    }
  }

  // ============================================
  // DASHBOARD KPIs
  // ============================================

  /// Busca estatísticas do dashboard via RPC
  /// 
  /// Parâmetros:
  /// - ano: Ano eleitoral (2020, 2022, 2024)
  /// - cargo: Cargo do candidato
  /// - bairro: Filtro por bairro (opcional)
  Future<Either<String, DashboardStats>> getDashboardStats({
    required int ano,
    required String cargo,
    String? bairro,
  }) async {
    print('');
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║  📊 GEONEXUS - CARREGANDO KPIs DO DASHBOARD                  ║');
    print('╠══════════════════════════════════════════════════════════════╣');
    print('║  ANO: $ano | CARGO: $cargo');
    print('╚══════════════════════════════════════════════════════════════╝');
    print('');

    try {
      final response = await _client.rpc(
        'get_dashboard_kpis',
        params: {
          'p_ano': ano,
          'p_cargo': cargo,
          'p_bairro': bairro,
        },
      ).single();

      if (response == null) {
        print('⚠️ RPC retornou null, usando valores padrão');
        return Right(DashboardStats.empty());
      }

      final stats = DashboardStats.fromJson(response as Map<String, dynamic>);
      print('✅ KPIs carregados: $stats');

      return Right(stats);
    } on PostgrestException catch (e) {
      print('❌ Erro RPC: ${e.message}');
      // Fallback: busca dados manualmente se RPC falhar
      return _getDashboardStatsFallback();
    } catch (e) {
      print('❌ Erro ao carregar KPIs: $e');
      return _getDashboardStatsFallback();
    }
  }

  /// Fallback para carregar stats quando RPC não existe
  Future<Either<String, DashboardStats>> _getDashboardStatsFallback() async {
    try {
      print('⚠️ Usando fallback para estatísticas...');

      // Conta obras por status
      final obrasResponse = await _client
          .from('obras_acoes')
          .select('status')
          .timeout(const Duration(seconds: 5));

      final obras = obrasResponse as List;
      int pendentes = 0;
      int emAndamento = 0;
      int concluidas = 0;
      int canceladas = 0;

      for (final obra in obras) {
        switch (obra['status']?.toString().toLowerCase()) {
          case 'pendente':
            pendentes++;
            break;
          case 'em_andamento':
            emAndamento++;
            break;
          case 'concluida':
            concluidas++;
            break;
          case 'cancelada':
            canceladas++;
            break;
        }
      }

      final stats = DashboardStats(
        totalVotos: 0, // Seria necessário query complexa
        melhorBairro: null,
        votosMelhorBairro: null,
        totalObras: obras.length,
        obrasPendentes: pendentes,
        obrasEmAndamento: emAndamento,
        obrasConcluidas: concluidas,
        obrasCanceladas: canceladas,
      );

      print('✅ Stats via fallback: $stats');
      return Right(stats);
    } catch (e) {
      print('❌ Fallback também falhou: $e');
      return Right(DashboardStats.empty());
    }
  }

  // ============================================
  // GESTÃO DE EQUIPE (Premium)
  // ============================================

  /// Busca estatísticas da equipe via RPC
  /// 
  /// Retorna lista de membros com suas obras cadastradas.
  Future<Either<String, List<TeamMember>>> getEquipeStats() async {
    print('');
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║  👥 GEONEXUS - CARREGANDO EQUIPE                             ║');
    print('╚══════════════════════════════════════════════════════════════╝');
    print('');

    try {
      // Tenta RPC primeiro
      final response = await _client.rpc('get_equipe_stats');

      if (response != null && response is List) {
        final members = response
            .map((json) => TeamMember.fromJson(json as Map<String, dynamic>))
            .toList();

        print('✅ ${members.length} membros carregados via RPC');
        return Right(members);
      }

      // Fallback: busca diretamente da tabela profiles
      return _getEquipeStatsFallback();
    } on PostgrestException catch (e) {
      print('⚠️ RPC falhou, usando fallback: ${e.message}');
      return _getEquipeStatsFallback();
    } catch (e) {
      print('❌ Erro ao carregar equipe: $e');
      return _getEquipeStatsFallback();
    }
  }

  /// Fallback para carregar equipe quando RPC não existe
  Future<Either<String, List<TeamMember>>> _getEquipeStatsFallback() async {
    try {
      print('⚠️ Usando fallback para equipe...');

      // Busca todos os perfis
      final profilesResponse = await _client
          .from('profiles')
          .select('id, nome, email, plano, ultimo_acesso, created_at')
          .order('created_at', ascending: false);

      final profiles = profilesResponse as List;
      final members = <TeamMember>[];

      for (final profile in profiles) {
        // Conta obras de cada usuário
        final obrasCount = await _client
            .from('obras_acoes')
            .select('id')
            .eq('user_id', profile['id'])
            .count(CountOption.exact);

        members.add(TeamMember(
          id: profile['id'] as String,
          nome: profile['nome'] as String? ?? 'Sem nome',
          email: profile['email'] as String? ?? '',
          plano: TeamMember.parsePlano(profile['plano'] as String?),
          obrasCadastradas: obrasCount.count,
          ultimoAcesso: profile['ultimo_acesso'] != null
              ? DateTime.tryParse(profile['ultimo_acesso'] as String)
              : null,
          criadoEm: profile['created_at'] != null
              ? DateTime.tryParse(profile['created_at'] as String)
              : null,
        ));
      }

      print('✅ ${members.length} membros via fallback');
      return Right(members);
    } catch (e) {
      print('❌ Fallback equipe falhou: $e');
      return Left('Erro ao carregar equipe: $e');
    }
  }

  /// Atualiza o plano de um usuário
  /// 
  /// Permite promover/rebaixar membros da equipe.
  Future<Either<String, bool>> updateUserPlan(String userId, String newPlan) async {
    print('');
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║  🔄 GEONEXUS - ATUALIZANDO PLANO DO USUÁRIO                  ║');
    print('╠══════════════════════════════════════════════════════════════╣');
    print('║  USER: $userId');
    print('║  NOVO PLANO: $newPlan');
    print('╚══════════════════════════════════════════════════════════════╝');
    print('');

    try {
      await _client
          .from('profiles')
          .update({'plano': newPlan})
          .eq('id', userId);

      print('✅ Plano atualizado com sucesso');
      return const Right(true);
    } on PostgrestException catch (e) {
      print('❌ Erro Postgrest: ${e.message}');
      return Left('Erro ao atualizar plano: ${e.message}');
    } catch (e) {
      print('❌ Erro ao atualizar plano: $e');
      return Left('Erro ao atualizar plano: $e');
    }
  }

  // ============================================
  // RADAR DE OPORTUNIDADES (Premium)
  // ============================================

  /// Busca oportunidades de votação para o candidato
  /// 
  /// Retorna locais onde o candidato tem baixa votação
  /// comparado ao total, indicando oportunidade de crescimento.
  Future<Either<String, List<RadarOportunidade>>> getRadarPins({
    required int ano,
    required String cargo,
    required String nomeCandidato,
  }) async {
    print('');
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║  🎯 GEONEXUS - RADAR DE OPORTUNIDADES                       ║');
    print('╠══════════════════════════════════════════════════════════════╣');
    print('║  ANO: $ano | CARGO: $cargo');
    print('║  CANDIDATO: $nomeCandidato');
    print('╚══════════════════════════════════════════════════════════════╝');
    print('');

    if (nomeCandidato.trim().isEmpty) {
      return const Left('Digite o nome do candidato para buscar oportunidades');
    }

    try {
      final response = await _client.rpc(
        'get_radar_oportunidades',
        params: {
          'p_ano': ano,
          'p_cargo': cargo,
          'p_meu_candidato': nomeCandidato,
        },
      );

      if (response == null || response is! List) {
        print('⚠️ RPC retornou null ou inválido');
        return const Right([]);
      }

      final oportunidades = response
          .map((json) => RadarOportunidade.fromJson(json as Map<String, dynamic>))
          .where((o) => o.hasLocation)
          .toList();

      print('✅ ${oportunidades.length} oportunidades encontradas');

      return Right(oportunidades);
    } on PostgrestException catch (e) {
      print('❌ Erro RPC: ${e.message}');
      // Fallback: busca manual não implementada para Radar
      return Left('Erro ao buscar oportunidades: ${e.message}');
    } catch (e) {
      print('❌ Erro ao buscar oportunidades: $e');
      return Left('Erro ao buscar oportunidades: $e');
    }
  }
}

