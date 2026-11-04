import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../application/app_controller.dart';
import '../domain/models.dart';
import '../l10n/app_text.dart';

class MaintenancePage extends StatelessWidget {
  const MaintenancePage({
    super.key,
    required this.controller,
    required this.vehicleId,
  });

  final AppController controller;
  final String vehicleId;

  Future<void> _edit(BuildContext context, [MaintenanceEntry? entry]) async {
    final receipts =
        controller
            .vehicleById(vehicleId)
            ?.documents
            .where((doc) => doc.kind == DocumentKind.receipt)
            .toList() ??
        const <VehicleDocument>[];
    final result = await showDialog<MaintenanceEntry>(
      context: context,
      builder: (_) => _MaintenanceForm(
        today: civilDate(controller.now),
        entry: entry,
        receipts: receipts,
      ),
    );
    if (result != null) await controller.saveMaintenance(vehicleId, result);
  }

  Future<void> _remove(BuildContext context, MaintenanceEntry entry) async {
    final t = AppText.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('maintenanceDelete')),
        content: Text(entry.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('delete')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.removeMaintenance(vehicleId, entry.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppText.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final vehicle = controller.vehicleById(vehicleId);
        final entries = [...?vehicle?.maintenance]
          ..sort((a, b) => b.date.compareTo(a.date));
        final dates = MaterialLocalizations.of(context);
        final now = controller.now;
        final monthlyCost = entries
            .where((e) => e.date.year == now.year && e.date.month == now.month)
            .fold(0, (total, e) => total + (e.costCents ?? 0));
        final money = NumberFormat.simpleCurrency(
          locale: Localizations.localeOf(context).toLanguageTag(),
          name: 'MXN',
          decimalDigits: 2,
        );
        return Scaffold(
          appBar: AppBar(title: Text(t('maintenance'))),
          body: vehicle == null
              ? null
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      vehicle.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (entries.any(
                      (e) =>
                          e.costCents != null &&
                          e.date.year == now.year &&
                          e.date.month == now.month,
                    ))
                      Text(
                        '${t('monthlyCost')} · ${money.format(monthlyCost / 100)} MXN',
                      ),
                    FilledButton.icon(
                      onPressed: () => _edit(context),
                      icon: const Icon(Icons.add),
                      label: Text(t('maintenanceAdd')),
                    ),
                    const SizedBox(height: 12),
                    if (entries.isEmpty) Text(t('maintenanceEmpty')),
                    for (final entry in entries)
                      ListTile(
                        title: Text(entry.title),
                        leading: Icon(
                          entry.isFuel
                              ? Icons.local_gas_station_outlined
                              : Icons.build_outlined,
                        ),
                        subtitle: Text(
                          [
                            dates.formatMediumDate(entry.date),
                            if (entry.odometerKm case final km?)
                              '${dates.formatDecimal(km)} km',
                            if (entry.costCents case final cost?)
                              '${money.format(cost / 100)} MXN',
                            if (entry.provider.isNotEmpty) entry.provider,
                            if (vehicle.documents.any(
                              (doc) => doc.id == entry.receiptId,
                            ))
                              t('receiptLinked'),
                            if (entry.nextServiceOn case final next?)
                              '${t('nextService')} ${dates.formatMediumDate(next)}',
                          ].join(' · '),
                        ),
                        onTap: () => _edit(context, entry),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: t('delete'),
                          onPressed: () => _remove(context, entry),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _MaintenanceForm extends StatefulWidget {
  const _MaintenanceForm({
    required this.today,
    this.entry,
    required this.receipts,
  });

  final DateTime today;
  final MaintenanceEntry? entry;
  final List<VehicleDocument> receipts;

  @override
  State<_MaintenanceForm> createState() => _MaintenanceFormState();
}

class _MaintenanceFormState extends State<_MaintenanceForm> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.entry?.title);
  late final _km = TextEditingController(
    text: widget.entry?.odometerKm?.toString(),
  );
  late DateTime _date = widget.entry?.date ?? widget.today;
  late DateTime? _next = widget.entry?.nextServiceOn;
  late bool _fuel = widget.entry?.isFuel ?? false;
  late String _provider = widget.entry?.provider ?? '';
  late int? _cost = widget.entry?.costCents;
  late String _receiptId =
      widget.receipts.any((doc) => doc.id == widget.entry?.receiptId)
      ? widget.entry!.receiptId!
      : '';

  String get _costText {
    final cents = _cost;
    return cents == null ? '' : (cents / 100).toStringAsFixed(2);
  }

  int? _parseCost(String value) {
    final parts = value.trim().replaceAll(',', '.').split('.');
    if (!RegExp(r'^\d{1,7}([.,]\d{1,2})?$').hasMatch(value.trim())) return null;
    return int.parse(parts.first) * 100 +
        (parts.length == 2 ? int.parse(parts.last.padRight(2, '0')) : 0);
  }

  @override
  void dispose() {
    _title.dispose();
    _km.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppText.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(
        t(widget.entry == null ? 'maintenanceAdd' : 'maintenanceEdit'),
      ),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t('fuelRecord')),
              value: _fuel,
              onChanged: (value) => setState(() => _fuel = value),
            ),
            TextFormField(
              controller: _title,
              maxLength: 80,
              decoration: InputDecoration(
                labelText: t(_fuel ? 'fuelDescription' : 'maintenanceService'),
              ),
              validator: (value) =>
                  value!.trim().isEmpty ? t('maintenanceRequired') : null,
            ),
            TextFormField(
              controller: _km,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              decoration: InputDecoration(labelText: t('maintenanceOdometer')),
            ),
            TextFormField(
              initialValue: _costText,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: t('serviceCost')),
              validator: (value) =>
                  value!.trim().isNotEmpty && _parseCost(value) == null
                  ? t('invalidCost')
                  : null,
              onSaved: (value) => _cost = _parseCost(value ?? ''),
            ),
            TextFormField(
              initialValue: _provider,
              maxLength: 80,
              decoration: InputDecoration(
                labelText: t(_fuel ? 'fuelStation' : 'serviceShop'),
              ),
              onSaved: (value) => _provider = value?.trim() ?? '',
            ),
            if (widget.receipts.isNotEmpty)
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _receiptId,
                decoration: InputDecoration(labelText: t('docReceipt')),
                items: [
                  DropdownMenuItem(value: '', child: Text(t('noReceipt'))),
                  for (final doc in widget.receipts)
                    DropdownMenuItem(
                      value: doc.id,
                      child: Text(
                        doc.title.isEmpty
                            ? '${t('docReceipt')} · ${dateKey(doc.addedAt)}'
                            : doc.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => _receiptId = value ?? '',
              ),
            TextButton.icon(
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                MaterialLocalizations.of(context).formatMediumDate(_date),
              ),
              onPressed: () async {
                final value = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(1900),
                  lastDate: _date.isAfter(widget.today) ? _date : widget.today,
                );
                if (mounted && value != null) setState(() => _date = value);
              },
            ),
            if (!_fuel)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t('nextService')),
                subtitle: _next == null
                    ? null
                    : Text(
                        MaterialLocalizations.of(context)
                            .formatMediumDate(_next!),
                      ),
                trailing: _next == null
                    ? const Icon(Icons.event_outlined)
                    : IconButton(
                        tooltip: t('clearNextService'),
                        onPressed: () => setState(() => _next = null),
                        icon: const Icon(Icons.clear),
                      ),
                onTap: () async {
                  final first = _date.add(const Duration(days: 1));
                  final last = DateTime(widget.today.year + 20);
                  final current = _next ?? widget.today;
                  final value = await showDatePicker(
                    context: context,
                    firstDate: first,
                    lastDate: last,
                    initialDate: current.isBefore(first) ? first : current,
                  );
                  if (mounted && value != null) setState(() => _next = value);
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t('cancel')),
        ),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            _form.currentState!.save();
            if (!_fuel && _next != null && !_next!.isAfter(_date)) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(t('invalidNextService'))));
              return;
            }
            Navigator.pop(
              context,
              MaintenanceEntry(
                id:
                    widget.entry?.id ??
                    DateTime.now().microsecondsSinceEpoch.toString(),
                title: _title.text.trim(),
                date: _date,
                odometerKm: int.tryParse(_km.text),
                costCents: _cost,
                provider: _provider,
                nextServiceOn: _fuel ? null : _next,
                isFuel: _fuel,
                receiptId: _receiptId.isEmpty ? null : _receiptId,
              ),
            );
          },
          child: Text(t('save')),
        ),
      ],
    );
  }
}
