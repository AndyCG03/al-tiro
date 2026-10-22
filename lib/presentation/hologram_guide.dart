import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../l10n/app_text.dart';
import 'widgets.dart';
import 'brand_components.dart';

String hologramNameKey(Hologram h) => switch (h) {
  Hologram.doubleZero => 'holoDoubleZero',
  Hologram.zero => 'holoZero',
  Hologram.one => 'holoOne',
  Hologram.two => 'holoTwo',
  Hologram.exempt => 'holoExempt',
  Hologram.none => 'holoNone',
};
String hologramAsset(Hologram h) =>
    'assets/images/hologram_${switch (h) {
      Hologram.doubleZero => 'double_zero',
      Hologram.zero => 'zero',
      Hologram.one => 'one',
      Hologram.two => 'two',
      _ => 'exempt',
    }}.png';

class HologramExample extends StatelessWidget {
  const HologramExample(this.value, {super.key, this.height = 84});
  final Hologram value;
  final double height;
  @override
  Widget build(BuildContext c) => SizedBox(
    height: height,
    child: value == Hologram.none
        ? Center(
            child: Icon(
              Icons.hide_image_outlined,
              size: height * .5,
              color: Theme.of(c).colorScheme.onSurfaceVariant,
            ),
          )
        : Image.asset(
            hologramAsset(value),
            fit: BoxFit.contain,
            semanticLabel:
                '${AppText.of(c)('illustrative')}: ${AppText.of(c)(hologramNameKey(value))}',
          ),
  );
}

Future<void> openHologramGuide(
  BuildContext c, {
  ValueChanged<Hologram>? onSelected,
}) => Navigator.of(c).push<void>(
  MaterialPageRoute(
    builder: (_) => Scaffold(
      appBar: AppBar(title: Text(AppText.of(c)('guide'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: HologramGuide(onSelected: onSelected),
      ),
    ),
  ),
);

class HologramGuide extends StatelessWidget {
  const HologramGuide({super.key, this.onSelected});
  final ValueChanged<Hologram>? onSelected;
  @override
  Widget build(BuildContext c) {
    final t = AppText.of(c), scheme = Theme.of(c).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandSectionHeader(t('guideTitle'), t('guideSubtitle')),
        Surface(
          color: scheme.primaryContainer,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.description_outlined,
                color: scheme.onPrimaryContainer,
                size: 30,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('guideWhere'),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t('guideWhereBody'),
                      style: TextStyle(color: scheme.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(t('guideIntro')),
        const SizedBox(height: 10),
        Text(
          t('guideIllustration'),
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 22),
        for (final h in Hologram.values) ...[
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(width: 112, child: HologramExample(h)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t(hologramNameKey(h)),
                            style: Theme.of(c).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            holoLabel(c, h),
                            style: TextStyle(
                              color: scheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(t('${hologramNameKey(h)}Body')),
                if (onSelected != null) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      onSelected!(h);
                      Navigator.of(c).pop();
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: Text(t('useHologram')),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        Text(t('guideScope'), style: TextStyle(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => openOfficial(
            c,
            'https://sedema.cdmx.gob.mx/programas/programa/verificacion-vehicular',
          ),
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
          label: Text(t('officialGuide')),
        ),
      ],
    );
  }
}

class HologramPicker extends StatelessWidget {
  const HologramPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final Hologram value;
  final ValueChanged<Hologram> onChanged;
  @override
  Widget build(BuildContext c) {
    final t = AppText.of(c), scheme = Theme.of(c).colorScheme;
    return LayoutBuilder(
      builder: (c, box) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: Hologram.values.map((h) {
          final selected = value == h;
          return SizedBox(
            width: (box.maxWidth - 16) / 3,
            child: Semantics(
              button: true,
              selected: selected,
              label: t(hologramNameKey(h)),
              child: Material(
                color: selected ? scheme.primaryContainer : scheme.surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => onChanged(h),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? scheme.primary
                            : scheme.outlineVariant,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: ExcludeSemantics(
                      child: Column(
                        children: [
                          HologramExample(h, height: 50),
                          const SizedBox(height: 6),
                          Text(
                            holoLabel(c, h),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
