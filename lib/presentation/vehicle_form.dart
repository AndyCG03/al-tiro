import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import '../domain/models.dart';
import '../l10n/app_text.dart';
import 'widgets.dart';
import 'vehicle_art.dart';
import 'hologram_guide.dart';

const states = <String, String>{
  'CDMX': 'Ciudad de México',
  'MX': 'Estado de México',
  'AGU': 'Aguascalientes',
  'BC': 'Baja California',
  'BCS': 'Baja California Sur',
  'CAM': 'Campeche',
  'CHIS': 'Chiapas',
  'CHIH': 'Chihuahua',
  'COAH': 'Coahuila',
  'COL': 'Colima',
  'DGO': 'Durango',
  'GTO': 'Guanajuato',
  'GRO': 'Guerrero',
  'HGO': 'Hidalgo',
  'JAL': 'Jalisco',
  'MIC': 'Michoacán',
  'MOR': 'Morelos',
  'NAY': 'Nayarit',
  'NL': 'Nuevo León',
  'OAX': 'Oaxaca',
  'PUE': 'Puebla',
  'QRO': 'Querétaro',
  'QROO': 'Quintana Roo',
  'SLP': 'San Luis Potosí',
  'SIN': 'Sinaloa',
  'SON': 'Sonora',
  'TAB': 'Tabasco',
  'TAM': 'Tamaulipas',
  'TLAX': 'Tlaxcala',
  'VER': 'Veracruz',
  'YUC': 'Yucatán',
  'ZAC': 'Zacatecas',
  'OTHER': 'Otra entidad / extranjero',
};

Future<void> openVehicleForm(
  BuildContext c,
  AppController a, [
  Vehicle? vehicle,
]) => Navigator.of(c).push<void>(
  MaterialPageRoute(
    builder: (_) => VehicleForm(controller: a, vehicle: vehicle),
  ),
);

class VehicleForm extends StatefulWidget {
  const VehicleForm({super.key, required this.controller, this.vehicle});
  final AppController controller;
  final Vehicle? vehicle;
  @override
  State<VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<VehicleForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.vehicle?.name ?? '');
  late final _plate = TextEditingController(text: widget.vehicle?.plate ?? '');
  late final _year = TextEditingController(
    text: widget.vehicle?.modelYear.toString() ?? '',
  );
  late String origin = widget.vehicle?.origin ?? 'CDMX',
      issuer = widget.vehicle?.issuer ?? 'CDMX';
  late Hologram hologram = widget.vehicle?.hologram ?? Hologram.one;
  late VehicleKind kind = widget.vehicle?.kind ?? VehicleKind.car;
  late VehicleAppearance appearance =
      widget.vehicle?.displayAppearance ?? VehicleAppearance.hatchback;
  late DateTime? validUntil = widget.vehicle?.validUntil,
      lastVerified = widget.vehicle?.lastVerified;
  late bool permit = widget.vehicle?.isPermit ?? false;
  bool saving = false, dateError = false;
  @override
  void dispose() {
    _name.dispose();
    _plate.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> pickDate(bool expiry) async {
    final today = civilDate(widget.controller.now);
    final chosen = await showDatePicker(
      context: context,
      initialDate: (expiry ? validUntil : lastVerified) ?? today,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (chosen != null && mounted) {
      setState(() {
        if (expiry) {
          validUntil = chosen;
          dateError = false;
        } else {
          lastVerified = chosen;
        }
      });
    }
  }

  Future<void> save() async {
    final needsDate =
        !permit && kind == VehicleKind.car && hologram != Hologram.none;
    setState(() => dateError = needsDate && validUntil == null);
    if (!_form.currentState!.validate() || dateError) {
      return;
    }
    setState(() => saving = true);
    final vehicle = Vehicle(
      id:
          widget.vehicle?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      plate: _plate.text.trim().toUpperCase(),
      modelYear: int.parse(_year.text),
      origin: origin,
      issuer: issuer,
      hologram: hologram,
      kind: kind,
      appearance: appearance,
      validUntil: validUntil,
      lastVerified: lastVerified,
      isPermit: permit,
    );
    await widget.controller.saveVehicle(vehicle);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext c) {
    final t = AppText.of(c);
    Widget field(Widget child) =>
        Padding(padding: const EdgeInsets.only(bottom: 18), child: child);
    return Scaffold(
      appBar: AppBar(title: const BrandMark(size: 54), toolbarHeight: 72),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  PageHeading(
                    t(widget.vehicle == null ? 'carForm' : 'editCar'),
                    t('formBody'),
                  ),
                  VehicleArtPicker(
                    value: appearance,
                    onChanged: (v) => setState(() {
                      appearance = v;
                      if (v == VehicleAppearance.moto) {
                        kind = VehicleKind.motorcycle;
                      } else if (kind == VehicleKind.motorcycle) {
                        kind = VehicleKind.car;
                      }
                    }),
                  ),
                  const SizedBox(height: 24),
                  field(
                    TextFormField(
                      controller: _name,
                      maxLength: 35,
                      decoration: InputDecoration(
                        labelText: t('name'),
                        counterText: '',
                        prefixIcon: const Icon(Icons.drive_eta_outlined),
                      ),
                      validator: (s) =>
                          s == null || s.trim().isEmpty ? t('required') : null,
                    ),
                  ),
                  field(
                    TextFormField(
                      controller: _plate,
                      maxLength: 15,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: t('plate'),
                        helperText: t('sample'),
                        counterText: '',
                      ),
                      validator: (s) => s == null || s.trim().isEmpty
                          ? t('required')
                          : !RegExp(r'^[A-Za-z0-9 -]+$').hasMatch(s.trim())
                          ? t('invalidPlate')
                          : null,
                    ),
                  ),
                  field(
                    TextFormField(
                      controller: _year,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: InputDecoration(
                        labelText: t('model'),
                        counterText: '',
                      ),
                      validator: (s) {
                        final n = int.tryParse(s ?? '');
                        return n == null ||
                                n < 1900 ||
                                n > widget.controller.now.year + 1
                            ? t('invalidYear')
                            : null;
                      },
                    ),
                  ),
                  field(
                    DropdownButtonFormField<String>(
                      initialValue: origin,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: t('origin')),
                      items: states.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(
                                e.key == 'OTHER' ? t('allStates') : e.value,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (s) => setState(() => origin = s!),
                    ),
                  ),
                  field(
                    DropdownButtonFormField<VehicleKind>(
                      key: ValueKey(kind),
                      isExpanded: true,
                      initialValue: kind,
                      decoration: InputDecoration(labelText: t('kind')),
                      items: VehicleKind.values
                          .map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Text(t(v.name)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() {
                        kind = v!;
                        if (kind == VehicleKind.motorcycle) {
                          appearance = VehicleAppearance.moto;
                        } else if (appearance == VehicleAppearance.moto) {
                          appearance = VehicleAppearance.hatchback;
                        }
                      }),
                    ),
                  ),
                  field(
                    DropdownButtonFormField<String>(
                      initialValue: issuer,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: t('issuer'),
                        helperText: t('issuerInfo'),
                        helperMaxLines: 3,
                      ),
                      items: states.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(
                                e.key == 'OTHER' ? t('allStates') : e.value,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (s) => setState(() => issuer = s!),
                    ),
                  ),
                  Text(t('hologram'), style: Theme.of(c).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  const SizedBox(height: 12),
                  HologramPicker(
                    value: hologram,
                    onChanged: (h) => setState(() => hologram = h),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => openHologramGuide(
                        c,
                        onSelected: (h) => setState(() => hologram = h),
                      ),
                      icon: const Icon(Icons.auto_stories_outlined, size: 18),
                      label: Text(t('viewGuide')),
                    ),
                  ),
                  field(
                    OutlinedButton.icon(
                      onPressed: () => pickDate(true),
                      icon: const Icon(Icons.event_outlined),
                      label: Text(
                        '${t('validUntil')}: ${validUntil == null ? t('chooseDate') : dateKey(validUntil!)}',
                      ),
                    ),
                  ),
                  if (dateError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        t('validityRequired'),
                        style: TextStyle(color: Theme.of(c).colorScheme.error),
                      ),
                    ),
                  field(
                    OutlinedButton.icon(
                      onPressed: () => pickDate(false),
                      icon: const Icon(Icons.history),
                      label: Text(
                        '${t('lastVerified')}: ${lastVerified == null ? '—' : dateKey(lastVerified!)}',
                      ),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t('permit')),
                    value: permit,
                    onChanged: (v) => setState(() => permit = v),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: saving ? null : save,
                    icon: const Icon(Icons.check),
                    label: Text(t('save')),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
