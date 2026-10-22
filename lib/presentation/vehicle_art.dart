import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../l10n/app_text.dart';

String vehicleAsset(VehicleAppearance appearance) => switch (appearance) {
  VehicleAppearance.hatchback => 'assets/images/carro_sidarta.png',
  _ => 'assets/images/vehicle_${appearance.name}.png',
};

class VehicleArt extends StatelessWidget {
  const VehicleArt(
    this.appearance, {
    super.key,
    this.width = 104,
    this.height = 68,
  });
  final VehicleAppearance appearance;
  final double width, height;
  @override
  Widget build(BuildContext c) => Container(
    width: width,
    height: height,
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Image.asset(
      vehicleAsset(appearance),
      fit: BoxFit.contain,
      semanticLabel: AppText.of(c)(appearance.name),
    ),
  );
}

class VehicleArtPicker extends StatelessWidget {
  const VehicleArtPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final VehicleAppearance value;
  final ValueChanged<VehicleAppearance> onChanged;
  @override
  Widget build(BuildContext c) {
    final t = AppText.of(c), scheme = Theme.of(c).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('vehicleAppearance'), style: Theme.of(c).textTheme.titleMedium),
        const SizedBox(height: 5),
        Text(
          t('appearanceBody'),
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 126,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: VehicleAppearance.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (c, i) {
              final item = VehicleAppearance.values[i],
                  selected = item == value;
              return Semantics(
                selected: selected,
                button: true,
                label: t(item.name),
                child: Material(
                  color: selected ? scheme.primaryContainer : scheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: () => onChanged(item),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 112,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected
                              ? scheme.primary
                              : scheme.outlineVariant,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          ExcludeSemantics(
                            child: VehicleArt(item, width: 94, height: 68),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (selected) ...[
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Flexible(
                                child: Text(
                                  t(item.name),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: selected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
