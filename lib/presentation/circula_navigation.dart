import 'package:flutter/material.dart';

import 'brand_components.dart';

class CirculaNavigation extends StatelessWidget {
  const CirculaNavigation({
    super.key,
    required this.selectedIndex,
    required this.destinations,
    required this.onSelected,
    this.guidedNextIndex,
  });
  final int selectedIndex;
  final int? guidedNextIndex;
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
            final suggested = guidedNextIndex == i;
            final enabled = guidedNextIndex == null || i <= guidedNextIndex!;
            return Expanded(
              child: Semantics(
                selected: selected,
                enabled: enabled,
                button: true,
                label: d.$1,
                child: Tooltip(
                  message: d.$1,
                  excludeFromSemantics: true,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: enabled ? () => onSelected(i) : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: ExcludeSemantics(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (guidedNextIndex != null)
                                SizedBox(
                                  height: 16,
                                  child: suggested
                                      ? Icon(
                                          Icons.arrow_downward_rounded,
                                          size: 15,
                                          color: scheme.primary,
                                        )
                                      : null,
                                ),
                              Container(
                                width: 46,
                                height: 29,
                                decoration: BoxDecoration(
                                  color: selected || suggested
                                      ? scheme.primaryContainer
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: suggested
                                      ? Border.all(
                                          color: scheme.primary,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: BrandNavGlyph(
                                  i,
                                  color: selected || suggested
                                      ? scheme.onPrimaryContainer
                                      : scheme.onSurfaceVariant.withValues(
                                          alpha: enabled ? 1 : .35,
                                        ),
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
                                  fontWeight: selected || suggested
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: selected || suggested
                                      ? scheme.onSurface
                                      : scheme.onSurfaceVariant.withValues(
                                          alpha: enabled ? 1 : .35,
                                        ),
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
