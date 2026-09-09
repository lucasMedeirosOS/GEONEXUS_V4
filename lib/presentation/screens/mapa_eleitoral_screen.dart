import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/ponto_votacao_model.dart';
import '../../data/services/eleitoral_service.dart';
import '../core/theme/app_theme.dart';

class MapaEleitoralScreen extends StatefulWidget {
  const MapaEleitoralScreen({super.key});

  @override
  State<MapaEleitoralScreen> createState() => _MapaEleitoralScreenState();
}

class _MapaEleitoralScreenState extends State<MapaEleitoralScreen> {
  static const _pontoCentralRio = LatLng(-22.9068, -43.1729);

  List<PontoVotacao> _pontos = const [];
  List<Map<String, dynamic>> _candidatos = const [];
  int? _candidatoSelecionado;
  PontoVotacao? _colegioSelecionado;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarRanking();
  }

  Future<void> _carregarRanking() async {
    await _executarComLoading(() async {
      final ranking = await EleitoralService.getRanking(
        ano: 2022,
        cargo: 6,
        limit: 10,
      );
      if (!mounted) return;

      setState(() {
        _candidatos = ranking;
        _candidatoSelecionado = ranking.isEmpty ? null : ranking.first['numero'] as int;
        _errorMessage = null;
      });

      if (_candidatoSelecionado != null) {
        await _carregarMapaCandidato(_candidatoSelecionado!, showLoading: false);
      }
    });
  }

  Future<void> _carregarMapaCandidato(
    int numero, {
    bool showLoading = true,
  }) async {
    await _executarComLoading(() async {
      final pontos = await EleitoralService.getMapaCandidato(
        numeroCandidato: numero,
      );
      if (!mounted) return;
      setState(() {
        _pontos = pontos;
        _colegioSelecionado = null;
        _errorMessage = null;
      });
    }, showLoading: showLoading);
  }

  Future<void> _executarComLoading(
    Future<void> Function() action, {
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) setState(() => _isLoading = true);
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Não foi possível carregar os dados.');
    } finally {
      if (showLoading && mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidato = _candidatos.cast<Map<String, dynamic>?>().firstWhere(
          (item) => item?['numero'] == _candidatoSelecionado,
          orElse: () => null,
        );

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        title: const Text('MAPA ELEITORAL'),
        actions: [
          IconButton(
            tooltip: 'Atualizar dados',
            onPressed: _isLoading ? null : _carregarRanking,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              center: _pontoCentralRio,
              zoom: 11,
              maxZoom: 18,
              minZoom: 9,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'br.gov.geonexus.app',
              ),
              MarkerLayer(
                markers: _pontos.map(_buildMarker).toList(),
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildCandidateSelector(candidato),
          ),
          if (_errorMessage != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: _buildErrorCard(),
            ),
          if (_colegioSelecionado != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: _buildDetailsCard(_colegioSelecionado!),
            ),
          if (_isLoading)
            const Positioned(
              top: 90,
              right: 24,
              child: Card(
                color: AppTheme.cardDark,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Marker _buildMarker(PontoVotacao ponto) {
    final color = ponto.votos > 150
        ? AppTheme.error
        : ponto.votos > 50
            ? AppTheme.accentGold
            : AppTheme.primaryPurple;
    final size = ponto.votos > 100 ? 42.0 : 32.0;

    return Marker(
      point: LatLng(ponto.latitude, ponto.longitude),
      width: size,
      height: size,
      child: GestureDetector(
        onTap: () => setState(() => _colegioSelecionado = ponto),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 5, offset: Offset(0, 2)),
            ],
          ),
          alignment: Alignment.center,
          child: FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                '${ponto.votos}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCandidateSelector(Map<String, dynamic>? candidato) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            isExpanded: true,
            value: _candidatoSelecionado,
            hint: Text(candidato == null ? 'Selecione um candidato' : '${candidato['nome']}'),
            dropdownColor: AppTheme.cardDark,
            items: _candidatos.map((item) {
              return DropdownMenuItem<int>(
                value: item['numero'] as int,
                child: Text(
                  '${item['nome']} · ${item['votos']} votos',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (numero) {
              if (numero != null) _carregarMapaCandidato(numero);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard(PontoVotacao ponto) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.school, color: AppTheme.accentGold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ponto.local,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar detalhes',
                  onPressed: () => setState(() => _colegioSelecionado = null),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(ponto.bairro, style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 10),
            Text(
              '${ponto.votos} votos apurados neste local',
              style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: AppTheme.cardDark,
      child: ListTile(
        leading: const Icon(Icons.cloud_off, color: AppTheme.error),
        title: const Text('API indisponível'),
        subtitle: const Text('Verifique o backend e tente novamente.'),
        trailing: IconButton(
          tooltip: 'Tentar novamente',
          onPressed: _carregarRanking,
          icon: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}
