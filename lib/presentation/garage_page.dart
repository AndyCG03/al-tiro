import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import '../l10n/app_text.dart';
import '../domain/models.dart';
import 'vehicle_form.dart';
import 'widgets.dart';
import 'brand_components.dart';
import 'vehicle_art.dart';

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
            padding: const EdgeInsets.only(bottom: 18),
            child: Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      VehicleArt(v.displayAppearance, width: 124, height: 82),
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
                  const SizedBox(height: 18),
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
}
