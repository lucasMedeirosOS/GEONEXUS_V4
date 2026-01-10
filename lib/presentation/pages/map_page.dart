import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../domain/entities/local_votacao.dart';
import '../../domain/entities/resumo_geonexus.dart';
import '../../domain/entities/map_pin.dart';
import '../../domain/entities/obra_acao.dart';
import '../core/theme/app_theme.dart';
import '../core/services/access_control_service.dart';
import '../providers/map_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/obras_providers.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/floating_search_bar.dart';
import '../widgets/layer_toggle_button.dart';
import '../widgets/filter_bottom_sheet.dart';
import 'obras/cadastro_obra_page.dart';

/// Página principal do mapa GEONEXUS
/// 
/// Renderiza o Google Maps com estilo Dark Tech,
/// marcadores roxo neon e integração com Supabase.
class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  GoogleMapController? _mapController;
  String? _darkMapStyle;
  Set<Marker> _markers = {};
  Set<Circle> _heatmapCircles = {};

  // Posição Inicial: Rio de Janeiro
  static const LatLng _rjCenter = LatLng(-22.9068, -43.1729);
  static const double _initialZoom = 11.0;

  // Cores Neon
  static const Color _purpleNeon = Color(0xFFBB86FC);
  static const Color _goldNeon = Color(0xFFFFD700);
  static const Color _orangeNeon = Color(0xFFFF6B35);

  // BitmapDescriptor customizado
  BitmapDescriptor? _purpleMarkerIcon;
  BitmapDescriptor? _goldMarkerIcon;
  BitmapDescriptor? _orangeMarkerIcon;
  
  // Marcadores de obras
  Set<Marker> _obrasMarkers = {};

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _createCustomMarkers();
  }

  /// Carrega o JSON de estilo do mapa dos assets
  Future<void> _loadMapStyle() async {
    try {
      final style = await rootBundle.loadString('assets/map_style_dark.json');
      setState(() {
        _darkMapStyle = style;
      });
      debugPrint('✓ Estilo Dark Tech carregado');
    } catch (e) {
      debugPrint('✗ Erro carregando estilo do mapa: $e');
    }
  }

  /// Cria marcadores customizados com cores Neon
  Future<void> _createCustomMarkers() async {
    _purpleMarkerIcon = await _createNeonMarker(_purpleNeon);
    _goldMarkerIcon = await _createNeonMarker(_goldNeon);
    _orangeMarkerIcon = await _createNeonMarker(_orangeNeon);
    setState(() {});
  }

  /// Cria um marcador com efeito glow neon
  Future<BitmapDescriptor> _createNeonMarker(Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(56, 56);

    // Glow externo
    final glowPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      24,
      glowPaint,
    );

    // Glow médio
    final glow2Paint = Paint()
      ..color = color.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      16,
      glow2Paint,
    );

    // Círculo principal
    final mainPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      10,
      mainPaint,
    );

    // Borda branca
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      10,
      borderPaint,
    );

    // Centro luminoso
    final centerPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      4,
      centerPaint,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final activeLayer = ref.watch(activeLayerProvider);
    final mapState = ref.watch(mapStateProvider);
    final userPlan = ref.watch(userPlanProvider);

    // Listener para atualizar marcadores de VOTOS
    // (movido de _onMapCreated para build - exigência do Riverpod)
    ref.listen<MapState>(mapStateProvider, (previous, next) {
      if (next is MapSuccess) {
        // Prioriza MapPins > ResumoGeonexus > Locais
        if (next.mapPins.isNotEmpty) {
          _updateMarkersFromMapPins(next.mapPins);
        } else if (next.resumoGeonexus.isNotEmpty) {
          _updateMarkersFromResumo(next.resumoGeonexus);
        } else if (next.locais.isNotEmpty) {
          _updateMarkersFromLocais(next.locais);
        }
      }
    });

    // Listener para atualizar marcadores de OBRAS
    ref.listen<AsyncValue<List<ObraAcao>>>(obrasPinsProvider, (previous, next) {
      next.whenData((obras) {
        _updateMarkersFromObras(obras);
      });
    });

    // Carrega obras quando camada de obras está ativa
    if (activeLayer == MapLayer.obras) {
      ref.watch(obrasPinsProvider);
    }

    // Determina quais marcadores exibir baseado na camada ativa
    final displayMarkers = activeLayer == MapLayer.obras 
        ? _obrasMarkers 
        : _markers;

    // Verifica se o usuário pode cadastrar obras E se está na camada de obras
    final showObraFab = AccessControlService.canCadastrarObra(userPlan) && 
                        activeLayer == MapLayer.obras;

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ============ GOOGLE MAP (FULL SCREEN) ============
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _rjCenter,
              zoom: _initialZoom,
            ),
            onMapCreated: _onMapCreated,
            markers: displayMarkers,
            circles: activeLayer == MapLayer.votos ? _heatmapCircles : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),

          // ============ LOADING STATE ============
          if (mapState is MapLoading)
            Container(
              color: AppTheme.primaryBlack.withOpacity(0.7),
              child: const ElegantLoadingIndicator(
                message: 'CARREGANDO DADOS DO RJ',
              ),
            ),

          // ============ SEARCH BAR (TOP - COM SAFEAREA) ============
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: FloatingSearchBar(
                  onSearch: _handleSearch,
                ),
              ),
            ),
          ),

          // ============ LOCATION BUTTON (BOTTOM LEFT) ============
          Positioned(
            bottom: 120,
            left: 16,
            child: _buildLocationButton(),
          ),

          // ============ LAYER TOGGLES + FAB (BOTTOM RIGHT) ============
          Positioned(
            bottom: 120,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botão Votos (em cima)
                LayerToggleButton(
                  icon: Icons.how_to_vote,
                  label: 'Votos',
                  isActive: activeLayer == MapLayer.votos,
                  onTap: () => ref.read(activeLayerProvider.notifier).state = MapLayer.votos,
                  activeColor: _purpleNeon,
                ),
                const SizedBox(height: 8),
                
                // Botão Obras
                LayerToggleButton(
                  icon: Icons.construction,
                  label: 'Obras',
                  isActive: activeLayer == MapLayer.obras,
                  onTap: () => ref.read(activeLayerProvider.notifier).state = MapLayer.obras,
                  activeColor: _goldNeon,
                ),
                
                // FAB Nova Obra (apenas se visível)
                if (showObraFab) ...[
                  const SizedBox(height: 16),
                  _buildObraFabCompact(),
                ],
              ],
            ),
          ),

          // ============ INFO CARD (Success) ============
          if (mapState is MapSuccess)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: _buildInfoCard(mapState),
            ),

          // ============ ERROR CARD ============
          if (mapState is MapError)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: _buildErrorCard((mapState as MapError).message),
            ),
        ],
      ),
    );
  }

  /// FAB compacto para cadastro de obras (dentro da Column)
  Widget _buildObraFabCompact() {
    return FloatingActionButton.extended(
      heroTag: 'obraFab',
      onPressed: () async {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const CadastroObraPage()),
        );
        
        if (result == true && mounted) {
          ref.invalidate(obrasPinsProvider);
          ref.invalidate(dashboardStatsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Obra registrada no mapa!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      backgroundColor: _goldNeon,
      foregroundColor: Colors.black,
      icon: const Icon(Icons.add),
      label: const Text(
        'NOVA OBRA',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLocationButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_purpleNeon, Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _purpleNeon.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _goToRioDeJaneiro,
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Icon(
              Icons.my_location,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  /// FAB para cadastro de obras (apenas para Standard e Premium)
  Widget? _buildObraFab() {
    final userPlan = ref.watch(userPlanProvider);
    
    // Verifica se o usuário pode cadastrar obras
    if (!AccessControlService.canCadastrarObra(userPlan)) {
      return null;
    }

    return FloatingActionButton.extended(
      onPressed: () async {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const CadastroObraPage()),
        );
        
        // Se cadastrou com sucesso, poderia recarregar dados
        if (result == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Obra registrada no mapa!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      backgroundColor: _goldNeon,
      foregroundColor: Colors.black,
      icon: const Icon(Icons.add),
      label: const Text(
        'NOVA OBRA',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoCard(MapSuccess state) {
    final totalLocais = state.totalLocais;
    final totalVotos = state.totalVotos;
    final ano = ref.watch(selectedYearProvider);
    final cargo = ref.watch(selectedCargoProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E).withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _purpleNeon.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: _purpleNeon.withOpacity(0.2),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _purpleNeon.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_on,
              color: _purpleNeon,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$totalLocais locais de votação',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Total: ${_formatNumber(totalVotos)} votos',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showFilters,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _goldNeon.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _goldNeon.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$cargo $ano',
                    style: const TextStyle(
                      color: _goldNeon,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit, color: _goldNeon, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.red),
            onPressed: () => ref.read(mapStateProvider.notifier).loadLocaisPorEstado('RJ'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(
            color: _purpleNeon.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.map, 'Mapa', true),
              _buildNavItem(Icons.analytics_outlined, 'Dashboard', false),
              _buildNavItem(Icons.search, 'Buscar', false),
              _buildNavItem(Icons.settings_outlined, 'Config', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? _goldNeon : Colors.white38,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? _goldNeon : Colors.white38,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // CALLBACKS E HANDLERS
  // ============================================

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    // Carrega dados com filtros padrão (ano + cargo)
    final ano = ref.read(selectedYearProvider);
    final cargo = ref.read(selectedCargoProvider);
    
    print('');
    print('🗺️ MapPage: Mapa criado, carregando dados com ANO=$ano, CARGO=$cargo');
    print('');
    
    ref.read(mapStateProvider.notifier).loadResumoGeonexus(
      ano: ano,
      cargo: cargo,
    );
    
    // REMOVIDO: ref.listen não é permitido fora do build (Riverpod)
    // Agora o listener está no método build()
  }

  void _updateMarkersFromLocais(List<LocalVotacao> locais) {
    final markers = locais.map((local) {
      return Marker(
        markerId: MarkerId('local_${local.id}'),
        position: LatLng(local.latitude, local.longitude),
        icon: _purpleMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: InfoWindow(
          title: local.nmLocalVotacao,
          snippet: 'Zona ${local.nrZona} • Seção ${local.nrSecao}',
        ),
        onTap: () => _showLocalDetails(local),
      );
    }).toSet();

    setState(() {
      _markers = markers;
    });

    debugPrint('✓ ${markers.length} marcadores plotados no mapa');
  }

  /// Atualiza marcadores a partir dos dados do ResumoGeonexus
  /// 
  /// Esta é a forma recomendada para melhor performance,
  /// usando a tabela otimizada resumo_geonexus_rj.
  void _updateMarkersFromResumo(List<ResumoGeonexus> resumos) {
    final markers = resumos.map((resumo) {
      return Marker(
        markerId: MarkerId('resumo_${resumo.id}'),
        position: LatLng(resumo.nrLatitude, resumo.nrLongitude),
        icon: _purpleMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: InfoWindow(
          title: resumo.nmLocalVotacao,
          snippet: '${_formatNumber(resumo.totalVotos)} votos',
        ),
        onTap: () => _showResumoDetails(resumo),
      );
    }).toSet();

    setState(() {
      _markers = markers;
    });

    debugPrint('✓ ${markers.length} marcadores GEONEXUS plotados no mapa');
  }

  /// Mostra detalhes de um local do ResumoGeonexus
  void _showResumoDetails(ResumoGeonexus resumo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _purpleNeon.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.how_to_vote, color: _purpleNeon),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    resumo.nmLocalVotacao,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow(
              Icons.location_on, 
              'Lat: ${resumo.nrLatitude.toStringAsFixed(6)}'
            ),
            _buildDetailRow(
              Icons.location_on_outlined, 
              'Lng: ${resumo.nrLongitude.toStringAsFixed(6)}'
            ),
            const Divider(color: Colors.white24, height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _goldNeon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _goldNeon.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.how_to_vote, color: _goldNeon),
                  const SizedBox(width: 12),
                  Text(
                    '${_formatNumber(resumo.totalVotos)} VOTOS',
                    style: const TextStyle(
                      color: _goldNeon,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Atualiza marcadores a partir dos dados do MapPin
  /// 
  /// Esta é a forma recomendada para melhor performance,
  /// usando a tabela resumo_geonexus_rj.
  void _updateMarkersFromMapPins(List<MapPin> pins) {
    final markers = pins.map((pin) {
      return Marker(
        markerId: MarkerId('pin_${pin.uniqueId}'),
        position: LatLng(pin.nrLatitude, pin.nrLongitude),
        icon: _purpleMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: InfoWindow(
          title: pin.nomeCandidato,
          snippet: 'Votos neste local: ${_formatNumber(pin.totalVotos)}',
        ),
        onTap: () => _showMapPinDetails(pin),
      );
    }).toSet();

    setState(() {
      _markers = markers;
    });

    debugPrint('✓ ${markers.length} marcadores MapPin plotados no mapa');
  }

  /// Atualiza marcadores de OBRAS (camada tática)
  /// 
  /// Usa cor laranja para diferenciar das votações.
  void _updateMarkersFromObras(List<ObraAcao> obras) {
    final markers = obras.where((obra) => obra.hasLocation).map((obra) {
      return Marker(
        markerId: MarkerId('obra_${obra.id}'),
        position: LatLng(obra.latitude!, obra.longitude!),
        icon: _orangeMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: obra.titulo,
          snippet: obra.status.displayName,
        ),
        onTap: () => _showObraDetails(obra),
      );
    }).toSet();

    setState(() {
      _obrasMarkers = markers;
    });

    debugPrint('✓ ${markers.length} marcadores de OBRAS plotados no mapa');
  }

  /// Mostra detalhes de uma obra cadastrada
  void _showObraDetails(ObraAcao obra) {
    final userPlan = ref.read(userPlanProvider);
    final canEdit = AccessControlService.canCadastrarObra(userPlan);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (modalContext) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header com botões de ação
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_orangeNeon, _orangeNeon.withOpacity(0.6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _orangeNeon.withOpacity(0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.construction, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          obra.titulo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildStatusChip(obra.status),
                      ],
                    ),
                  ),
                  // Botões de ação (apenas para Standard+)
                  if (canEdit) ...[
                    IconButton(
                      icon: const Icon(Icons.edit, color: _goldNeon),
                      tooltip: 'Editar',
                      onPressed: () {
                        Navigator.of(modalContext).pop();
                        _navigateToEditObra(obra);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Excluir',
                      onPressed: () => _confirmDeleteObra(modalContext, obra),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // Descrição
              if (obra.descricao != null && obra.descricao!.isNotEmpty) ...[
                _buildObraSection('Descrição', Icons.description),
                const SizedBox(height: 8),
                Text(
                  obra.descricao!,
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
                const SizedBox(height: 20),
              ],

              // Padrinhos
              if (obra.padrinhoVereador != null || obra.padrinhoPrefeito != null) ...[
                _buildObraSection('Padrinhos Políticos', Icons.people),
                const SizedBox(height: 8),
                if (obra.padrinhoVereador != null)
                  _buildPadrinhoRow('Vereador', obra.padrinhoVereador!),
                if (obra.padrinhoPrefeito != null)
                  _buildPadrinhoRow('Prefeito', obra.padrinhoPrefeito!),
                const SizedBox(height: 20),
              ],

              // Métricas
              if (obra.familiasBeneficiadas != null || obra.totalBeneficiados > 0) ...[
                _buildObraSection('Impacto Social', Icons.analytics),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (obra.familiasBeneficiadas != null)
                      Expanded(
                        child: _buildMetricCard(
                          'Famílias',
                          obra.familiasBeneficiadas.toString(),
                          Icons.family_restroom,
                        ),
                      ),
                    if (obra.familiasBeneficiadas != null) const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Pessoas',
                        obra.totalBeneficiados.toString(),
                        Icons.people,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Ruas atendidas
              if (obra.ruasAtendidas.isNotEmpty) ...[
                _buildObraSection('Ruas Atendidas', Icons.add_road),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: obra.ruasAtendidas.map((rua) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _goldNeon.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _goldNeon.withOpacity(0.3)),
                    ),
                    child: Text(
                      rua,
                      style: const TextStyle(color: _goldNeon, fontSize: 12),
                    ),
                  )).toList(),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Navega para a tela de edição
  void _navigateToEditObra(ObraAcao obra) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CadastroObraPage(obraParaEditar: obra),
      ),
    );

    if (result == true && mounted) {
      // Recarrega obras após edição
      ref.invalidate(obrasPinsProvider);
      ref.invalidate(dashboardStatsProvider);
    }
  }

  /// Diálogo de confirmação para exclusão
  void _confirmDeleteObra(BuildContext modalContext, ObraAcao obra) {
    showDialog(
      context: modalContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text(
              'Excluir Obra?',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'Tem certeza que deseja excluir "${obra.titulo}"?\n\nEsta ação não pode ser desfeita.',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop(); // Fecha dialog
              Navigator.of(modalContext).pop(); // Fecha modal
              await _deleteObra(obra);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  /// Executa a exclusão da obra
  Future<void> _deleteObra(ObraAcao obra) async {
    if (obra.id == null) return;

    final repository = ref.read(repositoryProvider);
    final result = await repository.deleteObra(obra.id!);

    result.fold(
      (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (_) {
        // Recarrega dados
        ref.invalidate(obrasPinsProvider);
        ref.invalidate(dashboardStatsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Obra excluída com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }

  Widget _buildStatusChip(ObraStatus status) {
    Color color;
    switch (status) {
      case ObraStatus.pendente:
        color = Colors.grey;
        break;
      case ObraStatus.emAndamento:
        color = Colors.blue;
        break;
      case ObraStatus.concluida:
        color = Colors.green;
        break;
      case ObraStatus.cancelada:
        color = Colors.red;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildObraSection(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _orangeNeon, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPadrinhoRow(String cargo, String nome) {
    return Padding(
      padding: const EdgeInsets.only(left: 26, top: 4),
      child: Row(
        children: [
          Text(
            '$cargo: ',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
          ),
          Text(
            nome,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _orangeNeon.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _orangeNeon.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: _orangeNeon, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Mostra o Raio-X do Local de Votação
  /// 
  /// Exibe modal expandido com ranking de todos os candidatos no local.
  void _showMapPinDetails(MapPin pin) {
    final ano = ref.read(selectedYearProvider);
    final cargo = ref.read(selectedCargoProvider);
    final searchQuery = ref.read(searchQueryProvider);
    final repository = ref.read(repositoryProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_purpleNeon, _purpleNeon.withOpacity(0.6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _purpleNeon.withOpacity(0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.analytics, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RAIO-X DO LOCAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          pin.nmLocalVotacao,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(color: Colors.white12, height: 1),
            
            // Ranking List
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: repository.getRankingLocal(
                  ano: ano,
                  cargo: cargo,
                  localVotacao: pin.nmLocalVotacao,
                ).then((result) => result.getOrElse(() => [])),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: _purpleNeon),
                          SizedBox(height: 16),
                          Text(
                            'Carregando ranking...',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Erro ao carregar ranking',
                            style: TextStyle(color: Colors.red.shade300),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  final ranking = snapshot.data ?? [];
                  
                  if (ranking.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox, color: Colors.white38, size: 48),
                          SizedBox(height: 16),
                          Text(
                            'Nenhum dado disponível',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: ranking.length,
                    itemBuilder: (context, index) {
                      final candidato = ranking[index];
                      final nome = candidato['nome_candidato'] as String;
                      final votos = candidato['total_votos'] as int;
                      final posicao = index + 1;
                      
                      // Verifica se é o candidato buscado
                      final isHighlighted = searchQuery.isNotEmpty &&
                          nome.toLowerCase().contains(searchQuery.toLowerCase());
                      
                      // Medalhas para top 3
                      IconData? medalIcon;
                      Color? medalColor;
                      if (posicao == 1) {
                        medalIcon = Icons.emoji_events;
                        medalColor = const Color(0xFFFFD700); // Ouro
                      } else if (posicao == 2) {
                        medalIcon = Icons.emoji_events;
                        medalColor = const Color(0xFFC0C0C0); // Prata
                      } else if (posicao == 3) {
                        medalIcon = Icons.emoji_events;
                        medalColor = const Color(0xFFCD7F32); // Bronze
                      }
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? _goldNeon.withOpacity(0.15)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isHighlighted
                                ? _goldNeon.withOpacity(0.5)
                                : Colors.white12,
                            width: isHighlighted ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Posição
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: medalColor?.withOpacity(0.2) ?? 
                                       _purpleNeon.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: medalIcon != null
                                    ? Icon(medalIcon, color: medalColor, size: 20)
                                    : Text(
                                        '$posicao°',
                                        style: TextStyle(
                                          color: isHighlighted ? _goldNeon : Colors.white70,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Nome
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nome,
                                    style: TextStyle(
                                      color: isHighlighted ? _goldNeon : Colors.white,
                                      fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (isHighlighted)
                                    const Text(
                                      '★ Candidato buscado',
                                      style: TextStyle(
                                        color: _goldNeon,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            
                            // Votos
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isHighlighted
                                    ? _goldNeon.withOpacity(0.2)
                                    : _purpleNeon.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_formatNumber(votos)} votos',
                                style: TextStyle(
                                  color: isHighlighted ? _goldNeon : _purpleNeon,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToRioDeJaneiro() {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_rjCenter, 12),
    );
  }

  void _handleSearch(String query) {
    final ano = ref.read(selectedYearProvider);
    final cargo = ref.read(selectedCargoProvider);
    
    // Armazena a busca para destacar no Raio-X
    ref.read(searchQueryProvider.notifier).state = query;
    
    debugPrint('🔍 Buscando candidato: "$query" | ANO=$ano | CARGO=$cargo');
    
    // Passa a busca para a RPC (filtra por nome do candidato)
    // Se query estiver vazia, retorna todos os dados do filtro atual
    ref.read(mapStateProvider.notifier).loadResumoGeonexus(
      ano: ano,
      cargo: cargo,
      search: query.isEmpty ? null : query,
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  void _showProfile() {
    // TODO: Implementar perfil
  }

  void _showLocalDetails(LocalVotacao local) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _purpleNeon.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.how_to_vote, color: _purpleNeon),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    local.nmLocalVotacao,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow(Icons.grid_view, 'Zona ${local.nrZona} • Seção ${local.nrSecao}'),
            if (local.acessibilidade)
              _buildDetailRow(Icons.accessible, 'Com acessibilidade', color: Colors.green),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purpleNeon,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'VER VOTOS DESTA SEÇÃO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Colors.white38),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color ?? Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
