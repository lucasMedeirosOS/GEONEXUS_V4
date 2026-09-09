import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/ponto_votacao_model.dart';

class EleitoralService {
  const EleitoralService._();

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000/api/v1';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000/api/v1'
        : 'http://localhost:8000/api/v1';
  }

  static Future<List<Map<String, dynamic>>> getRanking({
    int ano = 2022,
    int cargo = 6,
    int limit = 10,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/eleitoral/ranking?ano=$ano&cargo=$cargo&limit=$limit',
    );
    final response = await http.get(uri);
    _ensureSuccess(response, 'ranking eleitoral');

    final dados = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return dados
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<List<PontoVotacao>> getMapaCandidato({
    required int numeroCandidato,
    int ano = 2022,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/eleitoral/candidato/$numeroCandidato/mapa?ano=$ano',
    );
    final response = await http.get(uri);
    _ensureSuccess(response, 'mapa do candidato');

    final dados = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return dados
        .map((item) => PontoVotacao.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();
  }

  static void _ensureSuccess(http.Response response, String recurso) {
    if (response.statusCode != 200) {
      throw Exception(
        'Falha ao carregar $recurso (${response.statusCode})',
      );
    }
  }
}
