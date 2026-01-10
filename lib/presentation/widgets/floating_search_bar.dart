import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../providers/map_providers.dart';

/// Barra de pesquisa flutuante com autocomplete de candidatos
/// 
/// Estilo glassmorphism com sugestões que aparecem após 3 caracteres.
/// Usa a RPC suggest_candidatos do Supabase para buscar candidatos.
class FloatingSearchBar extends ConsumerStatefulWidget {
  final Function(String) onSearch;
  final String? hintText;

  const FloatingSearchBar({
    super.key,
    required this.onSearch,
    this.hintText,
  });

  @override
  ConsumerState<FloatingSearchBar> createState() => _FloatingSearchBarState();
}

class _FloatingSearchBarState extends ConsumerState<FloatingSearchBar> 
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;
  
  // Autocomplete
  List<String> _suggestions = [];
  bool _isLoadingSuggestions = false;
  Timer? _debounceTimer;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      if (_focusNode.hasFocus) {
        _animController.forward();
        if (_suggestions.isNotEmpty) {
          _showOverlay();
        }
      } else {
        _animController.reverse();
        _hideOverlay();
      }
    });
    
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _hideOverlay();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }
  
  /// Callback quando o texto muda (com debounce)
  void _onTextChanged() {
    setState(() {}); // Para atualizar o botão clear
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchSuggestions(_controller.text);
    });
  }
  
  /// Busca sugestões de candidatos
  Future<void> _fetchSuggestions(String termo) async {
    if (termo.length < 3) {
      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
      });
      _hideOverlay();
      return;
    }
    
    setState(() {
      _isLoadingSuggestions = true;
    });
    
    final repository = ref.read(repositoryProvider);
    final ano = ref.read(selectedYearProvider);
    final cargo = ref.read(selectedCargoProvider);
    
    final result = await repository.getSuggestCandidatos(
      termo: termo,
      ano: ano,
      cargo: cargo,
    );
    
    result.fold(
      (error) {
        debugPrint('Erro ao buscar sugestões: $error');
        setState(() {
          _suggestions = [];
          _isLoadingSuggestions = false;
        });
        _hideOverlay();
      },
      (sugestoes) {
        setState(() {
          _suggestions = sugestoes;
          _isLoadingSuggestions = false;
        });
        if (sugestoes.isNotEmpty && _focusNode.hasFocus) {
          _showOverlay();
        } else {
          _hideOverlay();
        }
      },
    );
  }
  
  /// Exibe o overlay de sugestões
  void _showOverlay() {
    _hideOverlay();
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          // GestureDetector with opaque behavior to capture all touch events
          // This prevents touches from passing through to the map underneath
          // NOTE: Only use onPanUpdate (not vertical/horizontal drag) to avoid conflict
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (_) {}, // Captures all drag gestures, blocks map
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.cardDark,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryPurple.withOpacity(0.3),
                  ),
                ),
                child: _isLoadingSuggestions
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryPurple,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];
                          return InkWell(
                            onTap: () => _selectSuggestion(suggestion),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    color: AppTheme.primaryPurple.withOpacity(0.7),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      suggestion,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.north_west,
                                    color: AppTheme.textMuted.withOpacity(0.5),
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }
  
  /// Esconde o overlay de sugestões
  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
  
  /// Seleciona uma sugestão do autocomplete
  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    _hideOverlay();
    _focusNode.unfocus();
    widget.onSearch(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppTheme.cardDark.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFocused 
                  ? AppTheme.primaryPurple.withOpacity(0.5)
                  : AppTheme.textMuted.withOpacity(0.2),
              width: _isFocused ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isFocused
                    ? AppTheme.primaryPurple.withOpacity(0.2)
                    : Colors.black.withOpacity(0.3),
                blurRadius: _isFocused ? 20 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(
                Icons.search,
                color: _isFocused ? AppTheme.accentGold : AppTheme.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? 'Buscar candidato (min. 3 letras)...',
                    hintStyle: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onSubmitted: (value) {
                    _hideOverlay();
                    if (value.trim().isNotEmpty) {
                      widget.onSearch(value.trim());
                    }
                  },
                ),
              ),
              // Loading indicator
              if (_isLoadingSuggestions)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryPurple,
                    ),
                  ),
                ),
              // Clear button
              if (_controller.text.isNotEmpty && !_isLoadingSuggestions)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: AppTheme.textMuted,
                  onPressed: () {
                    _controller.clear();
                    _hideOverlay();
                    widget.onSearch(''); // Recarrega todos os dados
                    setState(() {});
                  },
                ),
              Container(
                height: 24,
                width: 1,
                color: AppTheme.textMuted.withOpacity(0.3),
              ),
              IconButton(
                icon: const Icon(Icons.mic, size: 22),
                color: AppTheme.textMuted,
                onPressed: () {
                  // TODO: Implement voice search
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
