import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Barra de pesquisa com estilo glassmorphism
class MapSearchBar extends StatelessWidget {
  const MapSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassCard,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar bairro, político, candidato...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.accentGold),
          suffixIcon: IconButton(
            icon: const Icon(Icons.mic, color: AppTheme.textMuted),
            onPressed: () {
              // TODO: Implementar busca por voz
            },
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          hintStyle: const TextStyle(color: AppTheme.textMuted),
        ),
        style: const TextStyle(color: AppTheme.textPrimary),
        onSubmitted: (value) {
          // TODO: Implementar busca
        },
      ),
    );
  }
}
