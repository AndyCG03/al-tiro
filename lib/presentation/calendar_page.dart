import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import '../domain/models.dart';
import '../l10n/app_text.dart';
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
    final result = a.evaluate();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(t('yourCalendar'), t('monthBody')),
        VehicleSelector(a),
        const SizedBox(height: 20),
        Surface(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(
                      () => month = DateTime(month.year, month.month - 1),
                    ),
                    icon: const Icon(Icons.chevron_left),
                    tooltip: MaterialLocalizations.of(c).previousMonthTooltip,
                  ),
                  Expanded(
                    child: Text(
                      prettyDate(c, month, 'MMMM yyyy'),
                      textAlign: TextAlign.center,
                      style: Theme.of(c).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(
                      () => month = DateTime(month.year, month.month + 1),
                    ),
                    icon: const Icon(Icons.chevron_right),
                    tooltip: MaterialLocalizations.of(c).nextMonthTooltip,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(
                  7,
                  (i) => Expanded(
                    child: Center(
                      child: Text(
                        prettyDate(c, DateTime(2026, 10, 19 + i), 'E'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: offset + days,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                  childAspectRatio: .83,
                ),
                itemBuilder: (c, i) {
                  if (i < offset) {
                    return const SizedBox.shrink();
                  }
                  final date = DateTime(
                        month.year,
                        month.month,
                        i - offset + 1,
                      ),
                      r = a.evaluate(
                        DateTime(month.year, month.month, i - offset + 1),
                      );
                  final selected = dateKey(date) == dateKey(a.selectedDate);
                  final status = r?.ordinary ?? Decision.review;
                  final color = status == Decision.restricted
                      ? Brand.pink
                      : scheme.primary;
                  final label = t(
                    status == Decision.restricted
                        ? 'rests'
                        : status == Decision.allowed
                        ? 'circulates'
                        : 'reviewShort',
                  );
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: '${prettyDate(c, date)}: $label',
                    child: Tooltip(
                      message: label,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => a.setDate(date),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color.withValues(
                              alpha: status == Decision.restricted ? .15 : .05,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: selected
                                ? Border.all(color: scheme.primary, width: 2)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${date.day}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Icon(
                                status == Decision.restricted
                                    ? Icons.block
                                    : status == Decision.allowed
                                    ? Icons.check_circle_outline
                                    : Icons.help_outline,
                                size: 15,
                                color: color,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  for (final pair in [
                    (Icons.check_circle_outline, 'circulates'),
                    (Icons.block, 'rests'),
                    (Icons.help_outline, 'reviewShort'),
                  ])
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          pair.$1,
                          size: 15,
                          color: pair.$2 == 'rests'
                              ? Brand.pink
                              : scheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(t(pair.$2), style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          prettyDate(c, a.selectedDate),
          style: Theme.of(c).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
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
