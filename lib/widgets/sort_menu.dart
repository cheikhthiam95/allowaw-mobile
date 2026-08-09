import 'package:flutter/material.dart';
import '../core/theme.dart';

const sortLabels = {
  'hot': 'Pertinence',
  'recent': 'Plus récentes',
  'price_asc': 'Prix ↑',
  'price_desc': 'Prix ↓',
};

/// Bouton "Trier par" — même 4 options que sur le web (Pertinence par
/// défaut, Plus récentes, Prix ↑/↓), ouvre un menu contextuel compact.
class SortMenuButton extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const SortMenuButton({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (context) => sortLabels.entries
          .map((e) => PopupMenuItem(
                value: e.key,
                child: Row(
                  children: [
                    if (e.key == value) const Icon(Icons.check, size: 16, color: AppColors.primary) else const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Text(e.value),
                  ],
                ),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_vert, size: 16, color: AppColors.inkMuted),
            const SizedBox(width: 6),
            Text(sortLabels[value] ?? 'Trier', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
