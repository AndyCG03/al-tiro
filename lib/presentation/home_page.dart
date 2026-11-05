import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../application/app_controller.dart';
import '../domain/models.dart';
import '../l10n/app_text.dart';
import 'theme.dart';
import 'widgets.dart';
import 'brand_components.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.controller,
    required this.add,
    required this.calendar,
  });
  final AppController controller;
  final VoidCallback add, calendar;
  @override
  Widget build(BuildContext c) {
    final t = AppText.of(c), scheme = Theme.of(c).colorScheme;
    final result = controller.evaluate();
    final v = controller.active;
    final officialCheck = controller.snapshot?.feed.checkedAt;
    final sameDay = dateKey(controller.selectedDate) == dateKey(controller.now);
    final digits = controller.snapshot?.cdmxDigits ?? const <int>[];
    final lastUpdate = controller.lastUpdatedAt;
    final lastUpdateCdmx = lastUpdate == null
        ? null
        : tz.TZDateTime.from(lastUpdate, tz.getLocation('America/Mexico_City'));
    final nowDecision = result?.atMinute(
      controller.now.hour * 60 + controller.now.minute,
    );
    DateTime? next;
    if (v != null) {
      for (var i = 1; i <= 35; i++) {
        final d = controller.selectedDate.add(Duration(days: i));
        if (controller.evaluate(d)?.ordinary == Decision.restricted) {
          next = d;
          break;
        }
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandSectionHeader(
          controller.displayName.isEmpty
              ? t('hello')
              : '${t('greeting')} ${controller.displayName}.',
          prettyDate(c, controller.selectedDate),
        ),
        DropdownButtonFormField<Region>(
          key: ValueKey(controller.region),
          initialValue: controller.region,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: t('where'),
            prefixIcon: const Icon(Icons.location_on_outlined),
          ),
          items: Region.values
              .map(
                (r) => DropdownMenuItem(
                  value: r,
                  child: Text(t(regionKey(r)), overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (r) {
            if (r != null) {
              controller.setRegion(r);
            }
          },
        ),
        const SizedBox(height: 18),
        if (v == null)
          EmptyGarage(add: add)
        else ...[
          VehicleSelector(controller),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: controller.loading
                ? null
                : () => controller.setDate(civilDate(controller.now)),
            icon: controller.loading
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: Text(t(controller.loading ? 'checkingToday' : 'checkToday')),
          ),
          const SizedBox(height: 20),
          Surface(
            color: nowDecision == Decision.allowed && sameDay
                ? scheme.primaryContainer
                : Brand.accent(c).withValues(alpha: .10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    nowDecision == Decision.restricted && sameDay
                        ? Icons.block
                        : nowDecision == Decision.allowed && sameDay
                        ? Icons.check_circle_outline
                        : Icons.fact_check_outlined,
                    size: 48,
                    color: nowDecision == Decision.allowed && sameDay
                        ? scheme.onPrimaryContainer
                        : scheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t(
                      sameDay && nowDecision == Decision.restricted
                          ? 'nowRestricted'
                          : sameDay && nowDecision == Decision.allowed
                          ? 'nowAllowed'
                          : 'review',
                    ),
                    style: Theme.of(c).textTheme.headlineLarge?.copyWith(
                      color: nowDecision == Decision.allowed && sameDay
                          ? scheme.onPrimaryContainer
                          : scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t(
                      result?.ordinary == Decision.allowed
                          ? 'ordinaryAllowed'
                          : result?.ordinary == Decision.restricted
                          ? 'ordinaryRestricted'
                          : 'review',
                    ),
                    style: TextStyle(
                      color: nowDecision == Decision.allowed && sameDay
                          ? scheme.onPrimaryContainer
                          : scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (lastUpdateCdmx case final checked?) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${t('lastApiCheck')} ${prettyDate(c, checked, 'yMMMd')} · '
                      '${MaterialLocalizations.of(c).formatTimeOfDay(TimeOfDay.fromDateTime(checked))} (CDMX)',
                      style: TextStyle(
                        fontSize: 12,
                        color: nowDecision == Decision.allowed && sameDay
                            ? scheme.onPrimaryContainer.withValues(alpha: .75)
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (controller.snapshot?.remote == false)
                    Text(t('localCirculationData')),
                  if (result?.noticesConfirmed == true && officialCheck != null)
                    Text(
                      '${t('officialCheckConfirmed')} '
                      '${MaterialLocalizations.of(c).formatTimeOfDay(TimeOfDay.fromDateTime(tz.TZDateTime.from(officialCheck, tz.getLocation('America/Mexico_City'))))} (CDMX)',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (sameDay &&
              controller.snapshot?.cdmxCalendarDate ==
                  dateKey(controller.selectedDate) &&
              digits.isNotEmpty)
            TextButton.icon(
              onPressed: () =>
                  openOfficial(c, 'https://hoynocircula.cdmx.gob.mx/'),
              icon: const Icon(Icons.open_in_new),
              label: Text('${t('cdmxOrdinaryDigits')} ${digits.join(', ')}'),
            ),
          if (result != null && !result.noticesConfirmed)
            Surface(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Brand.accent(c)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('pending'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          t('pendingBody'),
                          style: Theme.of(c).textTheme.bodyMedium,
                        ),
                        if (controller.region == Region.cdmx)
                          OfficialSmsButton(vehicle: v),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (next != null)
            Surface(
              child: Row(
                children: [
                  Icon(
                    Icons.event_busy_outlined,
                    color: Brand.accent(c),
                    size: 30,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('nextRest'),
                          style: Theme.of(c).textTheme.bodyMedium,
                        ),
                        Text(
                          prettyDate(c, next, 'EEEE d MMM'),
                          style: Theme.of(c).textTheme.titleLarge,
                        ),
                        const Text('05:00–22:00'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: calendar,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(t('viewCalendar')),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: () => showSources(c, controller),
                tooltip: t('source'),
                icon: const Icon(Icons.menu_book_outlined),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (result != null) ResultDetail(result),
        ],
        const SizedBox(height: 18),
        TextButton.icon(
          onPressed: () => showSources(c, controller),
          icon: const Icon(Icons.verified_outlined, size: 18),
          label: Text(t('source')),
        ),
        if (controller.storageWarning)
          Text(t('storageWarning'), style: TextStyle(color: Brand.accent(c))),
      ],
    );
  }
}
