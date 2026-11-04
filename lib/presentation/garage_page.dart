import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import '../l10n/app_text.dart';
import '../domain/models.dart';
import 'vehicle_form.dart';
import 'widgets.dart';
import 'brand_components.dart';
import 'vehicle_portrait.dart';
import 'documents_page.dart';
import 'maintenance_page.dart';

class GaragePage extends StatelessWidget {
  const GaragePage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext c) {
    final t = AppText.of(c);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandSectionHeader(t('cars'), t('yourCars')),
        if (controller.vehicles.isEmpty)
          EmptyGarage(add: () => openVehicleForm(c, controller)),
        ...controller.vehicles.map(
          (v) => Padding(
            key: ValueKey(v.id),
            padding: const EdgeInsets.only(bottom: 18),
            child: Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      VehiclePortrait(controller: controller, vehicle: v),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.name,
                              style: Theme.of(c).textTheme.titleLarge,
                            ),
                            Text('${v.modelYear} · ${t(v.kind.name)}'),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (action) async {
                          if (action == 'edit') {
                            openVehicleForm(c, controller, v);
                          } else if (action == 'removePhoto') {
                            final messenger = ScaffoldMessenger.of(c);
                            try {
                              await controller.removeVehiclePhoto(v.id);
                            } catch (_) {
                              if (c.mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(t('vehiclePhotoError')),
                                  ),
                                );
                              }
                            }
                          } else {
                            final remove = await showDialog<bool>(
                              context: c,
                              builder: (ctx) => AlertDialog(
                                title: Text(t('deleteCar')),
                                content: Text(t('deleteBody')),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(t('cancel')),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(t('delete')),
                                  ),
                                ],
                              ),
                            );
                            if (remove == true) {
                              controller.removeVehicle(v.id);
                            }
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'edit', child: Text(t('edit'))),
                          if (v.photoPath.isNotEmpty)
                            PopupMenuItem(
                              value: 'removePhoto',
                              child: Text(t('removeVehiclePhoto')),
                            ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(t('delete')),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const RoadDivider(),
                  Plate(v.plate),
                  const SizedBox(height: 12),
                  Text(
                    '${states[v.origin]} · ${t('hologram')}: ${holoLabel(c, v.hologram)}',
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${t('validUntil')}: ${v.validUntil == null ? '—' : dateKey(v.validUntil!)}',
                  ),
                  _ValidityStatus(v, controller.now),
                  if (v.lastVerified != null) ...[
                    const SizedBox(height: 5),
                    Text('${t('lastVerified')}: ${dateKey(v.lastVerified!)}'),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          openVehicleDocuments(c, controller, v.id),
                      icon: const Icon(Icons.folder_open_outlined, size: 20),
                      label: Text(
                        t('documentsCount')
                            .replaceAll('{n}', '${v.documents.length}'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.support_agent_outlined, size: 20),
                      label: Text(t('assistanceAndServices')),
                      onPressed: () => _openAssistance(c, v),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(c).push<void>(
                        MaterialPageRoute(
                          builder: (_) => MaintenancePage(
                            controller: controller,
                            vehicleId: v.id,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.build_outlined, size: 20),
                      label: Text(t('maintenance')),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => controller.select(v.id),
                      icon: Icon(
                        controller.active?.id == v.id
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        size: 20,
                      ),
                      label: Text(
                        controller.active?.id == v.id
                            ? t('activeCar')
                            : t('selectCar'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (controller.vehicles.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => openVehicleForm(c, controller),
              icon: const Icon(Icons.add),
              label: Text(t('addCar')),
            ),
          ),
      ],
    );
  }

  Future<void> _openAssistance(BuildContext c, Vehicle v) {
    final t = AppText.of(c);
    return showModalBottomSheet<void>(
      context: c,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheet) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('assistanceAndServices'),
              style: Theme.of(sheet).textTheme.titleLarge,
            ),
            if (v.insurer.isNotEmpty)
              ListTile(title: Text(t('insurer')), subtitle: Text(v.insurer)),
            if (v.policyNumber.isNotEmpty)
              ListTile(
                title: Text(t('policyNumber')),
                subtitle: Text(v.policyNumber),
              ),
            if (v.assistancePhone.isNotEmpty)
              ListTile(
                title: Text(t('callAssistance')),
                subtitle: Text(v.assistancePhone),
                leading: const Icon(Icons.phone_outlined),
                onTap: () => openOfficial(
                  c,
                  Uri(
                    scheme: 'tel',
                    path: v.assistancePhone.replaceAll(RegExp(r'[ ()-]'), ''),
                  ).toString(),
                ),
              ),
            if (v.insurer.isEmpty &&
                v.policyNumber.isEmpty &&
                v.assistancePhone.isEmpty)
              TextButton(
                onPressed: () {
                  Navigator.of(sheet).pop();
                  openVehicleForm(c, controller, v);
                },
                child: Text(t('addAssistance')),
              ),
            if (v.origin == 'CDMX' || v.origin == 'MX') ...[
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: Text(t('verificationAppointment')),
                onTap: () => openOfficial(
                  c,
                  v.origin == 'CDMX'
                      ? 'https://citasverificentros.cdmx.gob.mx/'
                      : 'https://citaverificacion.edomex.gob.mx/RegistroCitas/registroVehiculoParticular?opcion=opcionesCita',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: Text(t('vehicleFees')),
                onTap: () => openOfficial(
                  c,
                  v.origin == 'CDMX'
                      ? 'https://data.finanzas.cdmx.gob.mx/consulta_adeudos'
                      : 'https://pagosytramites.edomex.gob.mx/controlv/Recaudacion/centro.jsp',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado de la vigencia en lenguaje claro: cuántos días faltan o cuánto
/// lleva vencida la constancia. Complementa la fecha cruda.
class _ValidityStatus extends StatelessWidget {
  const _ValidityStatus(this.vehicle, this.now);
  final Vehicle vehicle;
  final DateTime now;
  @override
  Widget build(BuildContext c) {
    final t = AppText.of(c);
    final until = vehicle.validUntil;
    if (until == null && vehicle.hologram == Hologram.none) {
      return const SizedBox.shrink();
    }
    final days = until == null
        ? null
        : civilDate(until).difference(civilDate(now)).inDays;
    final (text, bad) = days == null
        ? (t('validNone'), true)
        : days < 0
        ? (t('validExpired').replaceAll('{n}', '${-days}'), true)
        : days == 0
        ? (t('validToday'), false)
        : (t('validOk').replaceAll('{n}', '$days'), false);
    final scheme = Theme.of(c).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Icon(
            bad ? Icons.error_outline : Icons.check_circle_outline,
            size: 18,
            color: bad ? scheme.error : scheme.primary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: bad ? scheme.error : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
