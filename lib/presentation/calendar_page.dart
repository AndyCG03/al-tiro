import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import '../domain/models.dart';
import '../l10n/app_text.dart';
import 'brand_components.dart';
import 'theme.dart';
import 'widgets.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.controller, required this.add});
  final AppController controller;
  final VoidCallback add;
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime month = DateTime(
    widget.controller.selectedDate.year,
    widget.controller.selectedDate.month,
  );
  @override
  Widget build(BuildContext c) {
    final a = widget.controller,
        t = AppText.of(c),
        scheme = Theme.of(c).colorScheme;
    if (a.active == null) {
      return EmptyGarage(add: widget.add);
    }
    final days = DateTime(month.year, month.month + 1, 0).day;
    final offset = month.weekday - 1;
    final results = List.generate(
      days,
      (i) => a.evaluate(DateTime(month.year, month.month, i + 1)),
    );
    final count = results
        .where((r) => r?.ordinary == Decision.restricted)
        .length;
    final review = results
        .where((r) => r == null || r.ordinary == Decision.review)
        .length;
    final result = a.evaluate();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandSectionHeader(t('yourCalendar'), t('monthBody')),
        VehicleSelector(a),
        const SizedBox(height: 18),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('ordinaryCalendar'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      prettyDate(c, month, 'MMMM yyyy'),
                      style: Theme.of(c).textTheme.titleLarge,
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => setState(
                      () => month = DateTime(month.year, month.month - 1),
                    ),
                    icon: const Icon(Icons.chevron_left),
                    tooltip: MaterialLocalizations.of(c).previousMonthTooltip,
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    onPressed: () => setState(
                      () => month = DateTime(month.year, month.month + 1),
                    ),
                    icon: const Icon(Icons.chevron_right),
                    tooltip: MaterialLocalizations.of(c).nextMonthTooltip,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count ${t('restrictedDays')}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  if (review > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: scheme.outlineVariant),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$review · ${t('reviewDay')}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: List.generate(
                  7,
                  (i) => Expanded(
                    child: Center(
                      child: Text(
                        prettyDate(c, DateTime(2026, 10, 19 + i), 'E'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: offset + days,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 7,
                  crossAxisSpacing: 5,
                  childAspectRatio: .72,
                ),
                itemBuilder: (c, i) {
                  if (i < offset) {
                    return const SizedBox.shrink();
                  }
                  final day = i - offset + 1,
                      date = DateTime(month.year, month.month, i - offset + 1);
                  final status = results[day - 1]?.ordinary ?? Decision.review;
                  final restricted = status == Decision.restricted,
                      pending = status == Decision.review;
                  final selected = dateKey(date) == dateKey(a.selectedDate);
                  final label = t(
                    restricted
                        ? 'rests'
                        : pending
                        ? 'reviewShort'
                        : 'circulates',
                  );
                  final foreground = restricted
                      ? Brand.charcoal
                      : scheme.onSurface;
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: '${prettyDate(c, date)}: $label',
                    child: Tooltip(
                      message: label,
                      excludeFromSemantics: true,
                      child: Material(
                        color: restricted
                            ? Brand.orange
                            : pending
                            ? scheme.surfaceContainerHighest
                            : scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => a.setDate(date),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: selected
                                  ? Border.all(
                                      color: scheme.onSurface,
                                      width: 2.5,
                                    )
                                  : pending
                                  ? Border.all(color: scheme.outlineVariant)
                                  : null,
                            ),
                            child: ExcludeSemantics(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$day',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: foreground,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Icon(
                                    restricted
                                        ? Icons.block_rounded
                                        : pending
                                        ? Icons.help_outline_rounded
                                        : Icons.remove_rounded,
                                    size: restricted || pending ? 17 : 12,
                                    color: foreground,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const RoadDivider(),
              Wrap(
                spacing: 14,
                runSpacing: 10,
                children: [
                  for (final entry in [
                    (Icons.block_rounded, 'rests'),
                    (Icons.remove_rounded, 'circulates'),
                    (Icons.help_outline_rounded, 'reviewShort'),
                  ])
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          entry.$1,
                          size: 16,
                          color: entry.$2 == 'rests'
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 5),
                        Text(t(entry.$2), style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                t('calendarNote'),
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        if (result?.noticesConfirmed != true) ...[
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.cloud_off_outlined, size: 17, color: scheme.primary),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  t('pendingCalendar'),
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 26),
        Text(
          t('selectedDayLabel'),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          prettyDate(c, a.selectedDate),
          style: Theme.of(c).textTheme.titleLarge,
        ),
        const SizedBox(height: 14),
        if (result != null) ResultDetail(result),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => showSources(c, a),
          icon: const Icon(Icons.menu_book_outlined, size: 18),
          label: Text(t('source')),
        ),
      ],
    );
  }
}
