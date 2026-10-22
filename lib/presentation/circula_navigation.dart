import 'package:flutter/material.dart';

import 'brand_components.dart';

class CirculaNavigation extends StatelessWidget {
  const CirculaNavigation({
    super.key,
    required this.selectedIndex,
    required this.destinations,
    required this.onSelected,
  });
  final int selectedIndex;
  final List<(String, IconData, IconData)> destinations;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext c) {
    final scheme = Theme.of(c).colorScheme;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: .55),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .07),
              blurRadius: 22,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        child: Row(
          children: List.generate(destinations.length, (i) {
            final d = destinations[i], selected = selectedIndex == i;
            return Expanded(
              child: Semantics(
                selected: selected,
                button: true,
                label: d.$1,
                child: Tooltip(
                  message: d.$1,
                  excludeFromSemantics: true,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => onSelected(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: ExcludeSemantics(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 46,
                                height: 29,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? scheme.primaryContainer
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: BrandNavGlyph(
                                  i,
                                  color: selected
                                      ? scheme.onPrimaryContainer
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                d.$1,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  height: 1.2,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: selected
                                      ? scheme.onSurface
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
