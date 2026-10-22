import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import '../domain/models.dart';
import '../l10n/app_text.dart';
import 'vehicle_form.dart';
import 'widgets.dart';

class GaragePage extends StatelessWidget {
  const GaragePage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext c) {
    final t = AppText.of(c);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(t('cars'), t('yourCars')),
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
                      if (v.kind == VehicleKind.motorcycle)
                        Icon(
                          Icons.two_wheeler,
                          size: 46,
                          color: Theme.of(c).colorScheme.primary,
                        )
                      else
                        Container(
                          width: 92,
                          height: 68,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Image.asset(
                            'assets/images/carro.png',
                            fit: BoxFit.contain,
                            semanticLabel: t('car'),
                          ),
                        ),
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
                  const SizedBox(height: 18),
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
