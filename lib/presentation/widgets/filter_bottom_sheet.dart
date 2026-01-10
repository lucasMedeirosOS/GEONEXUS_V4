import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/map_providers.dart';

/// Bottom sheet para seleção de filtros do mapa
/// 
/// Permite ao usuário selecionar:
/// - Ano da eleição (obrigatório)
/// - Cargo (obrigatório, carrega dinamicamente baseado no ano)
/// 
/// Filtros opcionais (para implementação futura):
/// - Zona eleitoral
/// - Colégio/Local de votação
/// - Candidato
class FilterBottomSheet extends ConsumerStatefulWidget {
  final VoidCallback? onApply;

  const FilterBottomSheet({
    super.key,
    this.onApply,
  });

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late int _selectedAno;
  late String _selectedCargo;
  String? _selectedBairro;

  // Cores Neon
  static const Color _purpleNeon = Color(0xFFBB86FC);
  static const Color _goldNeon = Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    // Inicializa com valores atuais dos providers
    _selectedAno = ref.read(selectedYearProvider);
    _selectedCargo = ref.read(selectedCargoProvider);
    _selectedBairro = ref.read(selectedBairroProvider);
  }

  @override
  Widget build(BuildContext context) {
    final anosAsync = ref.watch(anosDisponiveisProvider);
    final cargosAsync = ref.watch(cargosDisponiveisProvider);
    final bairrosAsync = ref.watch(bairrosDisponiveisProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _purpleNeon.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.filter_list, color: _purpleNeon),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filtros do Mapa',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Selecione ano e cargo para visualizar',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // Filtro de Ano
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_today, color: _goldNeon, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Ano da Eleição',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      ' *',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                anosAsync.when(
                  loading: () => const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _purpleNeon,
                      ),
                    ),
                  ),
                  error: (error, stack) => Text(
                    'Erro ao carregar anos',
                    style: TextStyle(color: Colors.red.shade300),
                  ),
                  data: (anos) => Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: anos.map((ano) => _buildChip(
                      label: ano.toString(),
                      isSelected: _selectedAno == ano,
                      onTap: () {
                        setState(() {
                          _selectedAno = ano;
                          // Atualiza o provider para recarregar cargos
                          ref.read(selectedYearProvider.notifier).state = ano;
                        });
                      },
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Filtro de Cargo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.how_to_vote, color: _goldNeon, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Cargo',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      ' *',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                cargosAsync.when(
                  loading: () => const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _purpleNeon,
                      ),
                    ),
                  ),
                  error: (error, stack) => Text(
                    'Erro ao carregar cargos',
                    style: TextStyle(color: Colors.red.shade300),
                  ),
                  data: (cargos) {
                    // Se o cargo selecionado não está na lista, seleciona o primeiro
                    if (!cargos.contains(_selectedCargo) && cargos.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {
                          _selectedCargo = cargos.first;
                        });
                      });
                    }
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: cargos.map((cargo) => _buildChip(
                        label: cargo,
                        isSelected: _selectedCargo == cargo,
                        onTap: () {
                          setState(() {
                            _selectedCargo = cargo;
                          });
                        },
                      )).toList(),
                    );
                  },
                ),
              ],
            ),
          ),

          // Filtro de Bairro
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_city, color: _goldNeon, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Bairro',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedBairro != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedBairro = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.close, color: Colors.red, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Limpar',
                                style: TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                bairrosAsync.when(
                  loading: () => const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _purpleNeon,
                      ),
                    ),
                  ),
                  error: (error, stack) => Text(
                    'Erro ao carregar bairros',
                    style: TextStyle(color: Colors.red.shade300),
                  ),
                  data: (bairros) {
                    if (bairros.isEmpty) {
                      return const Text(
                        'Nenhum bairro disponível',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      );
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedBairro,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF2A2A3E),
                          hint: const Text(
                            'Todos os bairros',
                            style: TextStyle(color: Colors.white70),
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down, color: _purpleNeon),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                'Todos os bairros',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                            ...bairros.map((bairro) => DropdownMenuItem<String?>(
                              value: bairro,
                              child: Text(
                                bairro,
                                style: const TextStyle(color: Colors.white),
                              ),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedBairro = value;
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // Botão Aplicar
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purpleNeon,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'APLICAR FILTROS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _purpleNeon : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _purpleNeon : Colors.white24,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _purpleNeon.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _applyFilters() {
    // Atualiza os providers com os valores selecionados
    ref.read(selectedYearProvider.notifier).state = _selectedAno;
    ref.read(selectedCargoProvider.notifier).state = _selectedCargo;
    ref.read(selectedBairroProvider.notifier).state = _selectedBairro;

    // Recarrega os dados do mapa com filtro de bairro
    ref.read(mapStateProvider.notifier).loadResumoGeonexus(
      ano: _selectedAno,
      cargo: _selectedCargo,
      bairro: _selectedBairro,
    );

    // Fecha o bottom sheet
    Navigator.of(context).pop();

    // Callback opcional
    widget.onApply?.call();

    // Feedback visual
    final bairroText = _selectedBairro != null ? ' • $_selectedBairro' : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filtro aplicado: $_selectedCargo $_selectedAno$bairroText'),
        backgroundColor: _purpleNeon,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
