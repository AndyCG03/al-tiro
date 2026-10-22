import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import '../domain/models.dart';
import '../l10n/app_text.dart';
import 'theme.dart';
import 'widgets.dart';

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
    final sameDay = dateKey(controller.selectedDate) == dateKey(controller.now);
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
        PageHeading(t('hello'), prettyDate(c, controller.selectedDate)),
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
          const SizedBox(height: 20),
          Surface(
            color: nowDecision == Decision.allowed && sameDay
                ? Brand.green
                : Brand.pink.withValues(alpha: .10),
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
                        ? Colors.white
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
                          ? Colors.white
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
                          ? Colors.white
                          : scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (sameDay) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${controller.now.hour.toString().padLeft(2, '0')}:${controller.now.minute.toString().padLeft(2, '0')} · ${t('asOf')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: nowDecision == Decision.allowed && sameDay
                            ? Colors.white70
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (result != null && !result.noticesConfirmed)
            Surface(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Brand.pink),
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
                  const Icon(
                    Icons.event_busy_outlined,
                    color: Brand.pink,
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
          Text(t('storageWarning'), style: const TextStyle(color: Brand.pink)),
      ],
    );
  }
}
