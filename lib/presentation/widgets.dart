import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../application/app_controller.dart';
import '../domain/models.dart';
import '../l10n/app_text.dart';
import 'theme.dart';

String prettyDate(
  BuildContext c,
  DateTime d, [
  String pattern = 'EEEE d MMMM',
]) => DateFormat(pattern, Localizations.localeOf(c).languageCode).format(d);
String regionKey(Region region) => region.name;
String holoLabel(BuildContext c, Hologram h) => switch (h) {
  Hologram.doubleZero => '00',
  Hologram.zero => '0',
  Hologram.one => '1',
  Hologram.two => '2',
  Hologram.exempt => AppText.of(c)('exempt'),
  Hologram.none => AppText.of(c)('none'),
};

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44, this.wordmark = true});
  final double size;
  final bool wordmark;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * .08),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * .24),
        ),
        child: Image.asset(
          Brand.logo,
          fit: BoxFit.contain,
          semanticLabel: 'Al Tiro',
        ),
      ),
      if (wordmark) ...[
        const SizedBox(width: 10),
        const Flexible(
          child: Text(
            'Al Tiro',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -.5,
            ),
          ),
        ),
      ],
    ],
  );
}

class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext c) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? Theme.of(c).colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: Theme.of(c).colorScheme.outlineVariant.withValues(alpha: .45),
      ),
    ),
    child: Material(type: MaterialType.transparency, child: child),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.subtitle, {super.key, this.action});
  final String title, subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(c).textTheme.headlineMedium),
              const SizedBox(height: 7),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(c).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        ?action,
      ],
    ),
  );
}

class Plate extends StatelessWidget {
  const Plate(this.value, {super.key});
  final String value;
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
    decoration: BoxDecoration(
      color: Theme.of(c).colorScheme.surface,
      border: Border.all(color: Theme.of(c).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      value,
      style: const TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
      ),
    ),
  );
}

class EmptyGarage extends StatelessWidget {
  const EmptyGarage({super.key, required this.add});
  final VoidCallback add;
  @override
  Widget build(BuildContext c) {
    final t = AppText.of(c);
    return Surface(
      child: Column(
        children: [
          const SizedBox(height: 14),
          const BrandMark(size: 140, wordmark: false),
          const SizedBox(height: 24),
          Text(
            t('noCars'),
            style: Theme.of(c).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Text(t('noCarsBody'), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: add,
            icon: const Icon(Icons.add_rounded),
            label: Text(t('addCar')),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class VehicleSelector extends StatelessWidget {
  const VehicleSelector(this.controller, {super.key});
  final AppController controller;
  @override
  Widget build(BuildContext c) => DropdownButtonFormField<String>(
    key: ValueKey(controller.active?.id),
    initialValue: controller.active?.id,
    decoration: const InputDecoration(
      prefixIcon: Icon(Icons.directions_car_outlined),
    ),
    isExpanded: true,
    items: controller.vehicles
        .map(
          (v) => DropdownMenuItem(
            value: v.id,
            child: Text(
              '${v.name} · ${v.plate}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList(),
    onChanged: (id) {
      if (id != null) {
        controller.select(id);
      }
    },
  );
}

class ResultDetail extends StatelessWidget {
  const ResultDetail(this.result, {super.key});
  final CirculationResult result;
  @override
  Widget build(BuildContext c) {
    final t = AppText.of(c);
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('selectedDay'), style: Theme.of(c).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                result.ordinary == Decision.restricted
                    ? Icons.block
                    : result.ordinary == Decision.allowed
                    ? Icons.check_circle_outline
                    : Icons.help_outline,
                color: result.ordinary == Decision.restricted
                    ? Brand.accent(c)
                    : Theme.of(c).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t(
                    result.ordinary == Decision.restricted
                        ? 'ordinaryRestricted'
                        : result.ordinary == Decision.allowed
                        ? 'ordinaryAllowed'
                        : 'review',
                  ),
                  style: Theme.of(c).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (t(result.reason) !=
              t(
                result.ordinary == Decision.restricted
                    ? 'ordinaryRestricted'
                    : result.ordinary == Decision.allowed
                    ? 'ordinaryAllowed'
                    : 'review',
              ))
            Text(t(result.reason)),
          if (result.windows.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...result.windows.map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text(
                  '${w.label} · ${t(w.reason)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
          if (!result.noticesConfirmed) ...[
            const Divider(),
            Text(
              t('pending'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(t('pendingBody'), style: Theme.of(c).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

Future<void> openOfficial(BuildContext c, String url) async {
  try {
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      throw StateError('launch');
    }
  } catch (_) {
    if (c.mounted) {
      ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(url)));
    }
  }
}

void showSources(BuildContext c, AppController controller) {
  final t = AppText.of(c);
  showModalBottomSheet<void>(
    context: c,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * .85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t('sourcesTitle'),
                style: Theme.of(ctx).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(t('sourcesBody')),
              const SizedBox(height: 16),
              if (controller.snapshot != null) ...[
                Text(
                  '${t('policyVersion')}: ${controller.snapshot!.policy.version}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${t('reviewRange')}: ${dateKey(controller.snapshot!.policy.from)} / ${dateKey(controller.snapshot!.policy.through)}',
                ),
                const SizedBox(height: 20),
                ...controller.snapshot!.policy.sources.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Surface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.title,
                            style: Theme.of(ctx).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(s.sections),
                          TextButton.icon(
                            onPressed: () => openOfficial(ctx, s.url),
                            icon: const Icon(Icons.open_in_new, size: 18),
                            label: Text(t('officialLink')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              Text(t('sourceDate'), style: Theme.of(ctx).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    ),
  );
}
