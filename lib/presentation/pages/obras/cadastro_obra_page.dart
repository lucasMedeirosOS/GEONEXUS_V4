import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/map_providers.dart';
import '../../providers/obras_providers.dart';
import '../../providers/dashboard_providers.dart';
import '../../../data/models/obra_acao_model.dart';
import '../../../domain/entities/obra_acao.dart';

/// Página de cadastro/edição de obras/ações
/// 
/// Disponível apenas para perfis Standard e Premium.
/// 
/// Se [obraParaEditar] for fornecido, entra em modo de edição.
class CadastroObraPage extends ConsumerStatefulWidget {
  /// Obra a ser editada (null para criar nova)
  final ObraAcao? obraParaEditar;

  const CadastroObraPage({
    super.key,
    this.obraParaEditar,
  });

  @override
  ConsumerState<CadastroObraPage> createState() => _CadastroObraPageState();
}

class _CadastroObraPageState extends ConsumerState<CadastroObraPage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _vereadorController = TextEditingController();
  final _prefeitoController = TextEditingController();
  final _familiasController = TextEditingController();
  final _pessoasController = TextEditingController();
  final _ruaController = TextEditingController();

  final List<String> _ruasAtendidas = [];
  double? _latitude;
  double? _longitude;
  ObraStatus _status = ObraStatus.pendente;
  bool _isLoading = false;
  bool _isCapturingLocation = false;

  /// Retorna true se estamos editando uma obra existente
  bool get _isEditMode => widget.obraParaEditar != null;

  // Cores Neon
  static const Color _purpleNeon = Color(0xFFBB86FC);
  static const Color _goldNeon = Color(0xFFFFD700);
  static const Color _greenSuccess = Color(0xFF10B981);
  static const Color _orangeNeon = Color(0xFFFF6B35);

  @override
  void initState() {
    super.initState();
    _initializeFromEditData();
  }

  /// Preenche os campos se estivermos editando uma obra existente
  void _initializeFromEditData() {
    final obra = widget.obraParaEditar;
    if (obra == null) return;

    _tituloController.text = obra.titulo;
    _descricaoController.text = obra.descricao ?? '';
    _vereadorController.text = obra.padrinhoVereador ?? '';
    _prefeitoController.text = obra.padrinhoPrefeito ?? '';
    _familiasController.text = obra.familiasBeneficiadas?.toString() ?? '';
    _pessoasController.text = obra.pessoasBeneficiadas?.toString() ?? '';
    _ruasAtendidas.addAll(obra.ruasAtendidas);
    _latitude = obra.latitude;
    _longitude = obra.longitude;
    _status = obra.status;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _vereadorController.dispose();
    _prefeitoController.dispose();
    _familiasController.dispose();
    _pessoasController.dispose();
    _ruaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditMode ? 'EDITAR OBRA' : 'CADASTRAR OBRA',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 24),

                // Título
                _buildTextField(
                  controller: _tituloController,
                  label: 'Título da Obra *',
                  hint: 'Ex: Pavimentação da Rua das Flores',
                  icon: Icons.title,
                  validator: (v) => v!.isEmpty ? 'Título obrigatório' : null,
                ),
                const SizedBox(height: 16),

                // Status (apenas em modo edição)
                if (_isEditMode) ...[
                  _buildStatusDropdown(),
                  const SizedBox(height: 16),
                ],

                // Descrição
                _buildTextField(
                  controller: _descricaoController,
                  label: 'Descrição',
                  hint: 'Descreva a obra ou ação realizada...',
                  icon: Icons.description,
                  maxLines: 4,
                ),
                const SizedBox(height: 24),

                // Ruas Atendidas
                _buildRuasSection(),
                const SizedBox(height: 24),

                // Padrinhos
                _buildSectionTitle('Padrinhos Políticos'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _vereadorController,
                  label: 'Vereador Autor',
                  hint: 'Nome do vereador responsável',
                  icon: Icons.person,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _prefeitoController,
                  label: 'Apoio Prefeito',
                  hint: 'Nome do prefeito (se houver)',
                  icon: Icons.account_balance,
                ),
                const SizedBox(height: 24),

                // Métricas
                _buildSectionTitle('Métricas de Impacto'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _familiasController,
                        label: 'Famílias',
                        hint: '0',
                        icon: Icons.family_restroom,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _pessoasController,
                        label: 'Pessoas',
                        hint: '0',
                        icon: Icons.people,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Localização
                _buildLocationSection(),
                const SizedBox(height: 32),

                // Botão Salvar
                _buildSaveButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final iconColor = _isEditMode ? _orangeNeon : _purpleNeon;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [iconColor.withOpacity(0.2), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isEditMode ? Icons.edit : Icons.construction,
              color: iconColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditMode ? 'Editar Obra' : 'Registrar Ação/Obra',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isEditMode 
                      ? 'Atualize os dados da obra cadastrada'
                      : 'Documente obras e ações realizadas na sua região',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Status da Obra'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ObraStatus>(
              value: _status,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E1E2E),
              icon: const Icon(Icons.keyboard_arrow_down, color: _purpleNeon),
              style: const TextStyle(color: Colors.white),
              items: ObraStatus.values.map((status) {
                Color statusColor;
                switch (status) {
                  case ObraStatus.pendente:
                    statusColor = Colors.grey;
                    break;
                  case ObraStatus.emAndamento:
                    statusColor = Colors.blue;
                    break;
                  case ObraStatus.concluida:
                    statusColor = _greenSuccess;
                    break;
                  case ObraStatus.cancelada:
                    statusColor = Colors.red;
                    break;
                }

                return DropdownMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(status.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _status = value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: _goldNeon,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: icon != null ? Icon(icon, color: _purpleNeon, size: 20) : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _purpleNeon, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildRuasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Ruas Atendidas'),
        const SizedBox(height: 12),
        
        // Campo + Botão Adicionar
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _ruaController,
                label: 'Nome da Rua',
                hint: 'Ex: Rua das Flores',
                icon: Icons.add_road,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: _greenSuccess.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: _greenSuccess),
                onPressed: _addRua,
              ),
            ),
          ],
        ),
        
        // Lista de ruas
        if (_ruasAtendidas.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ruasAtendidas.map((rua) => _buildRuaChip(rua)).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildRuaChip(String rua) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _goldNeon.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _goldNeon.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rua,
            style: const TextStyle(color: _goldNeon, fontSize: 13),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeRua(rua),
            child: Icon(Icons.close, size: 16, color: _goldNeon.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Localização'),
        const SizedBox(height: 12),
        
        // Status da localização
        if (_latitude != null && _longitude != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _greenSuccess.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _greenSuccess.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: _greenSuccess, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Localização capturada',
                        style: TextStyle(color: _greenSuccess, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white38),
                  onPressed: () => setState(() {
                    _latitude = null;
                    _longitude = null;
                  }),
                ),
              ],
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isCapturingLocation ? null : _captureLocation,
                  icon: _isCapturingLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.my_location, size: 18),
                  label: Text(_isCapturingLocation ? 'Capturando...' : 'Minha Localização'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purpleNeon.withOpacity(0.2),
                    foregroundColor: _purpleNeon,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: _purpleNeon.withOpacity(0.5)),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveObra,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isEditMode ? _orangeNeon : _greenSuccess,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_isEditMode ? Icons.check : Icons.save),
                const SizedBox(width: 8),
                Text(
                  _isEditMode ? 'ATUALIZAR OBRA' : 'SALVAR OBRA',
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
    );
  }

  void _addRua() {
    final rua = _ruaController.text.trim();
    if (rua.isNotEmpty && !_ruasAtendidas.contains(rua)) {
      setState(() {
        _ruasAtendidas.add(rua);
        _ruaController.clear();
      });
    }
  }

  void _removeRua(String rua) {
    setState(() {
      _ruasAtendidas.remove(rua);
    });
  }

  Future<void> _captureLocation() async {
    setState(() => _isCapturingLocation = true);

    try {
      // Verifica permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permissão de localização negada');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permissão de localização permanentemente negada');
      }

      // Captura posição
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📍 Localização capturada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isCapturingLocation = false);
    }
  }

  Future<void> _saveObra() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final obra = ObraAcaoModel(
        id: widget.obraParaEditar?.id,
        userId: widget.obraParaEditar?.userId,
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim().isEmpty
            ? null
            : _descricaoController.text.trim(),
        ruasAtendidas: _ruasAtendidas,
        padrinhoVereador: _vereadorController.text.trim().isEmpty
            ? null
            : _vereadorController.text.trim(),
        padrinhoPrefeito: _prefeitoController.text.trim().isEmpty
            ? null
            : _prefeitoController.text.trim(),
        familiasBeneficiadas: _familiasController.text.isEmpty
            ? null
            : int.tryParse(_familiasController.text),
        pessoasBeneficiadas: _pessoasController.text.isEmpty
            ? null
            : int.tryParse(_pessoasController.text),
        latitude: _latitude,
        longitude: _longitude,
        status: _status,
      );

      final repository = ref.read(repositoryProvider);
      
      final result = _isEditMode
          ? await repository.updateObra(obra)
          : await repository.createObra(obra);

      result.fold(
        (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (savedObra) {
          // Invalida providers para atualizar dados
          ref.invalidate(obrasPinsProvider);
          ref.invalidate(dashboardStatsProvider);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditMode 
                  ? '✅ Obra atualizada com sucesso!'
                  : '✅ Obra cadastrada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Retorna true para indicar sucesso
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
