import 'package:flutter_test/flutter_test.dart';
import 'package:al_tiro/domain/models.dart';

void main() {
  final oldVehicle = <String, dynamic>{
    'id': 'old',
    'name': 'Auto guardado',
    'plate': 'ABC-123',
    'modelYear': 2016,
    'origin': 'CDMX',
    'issuer': 'CDMX',
    'hologram': 'one',
    'kind': 'car',
    'validUntil': '2026-12-31',
  };
  test('old saved cars survive without an appearance field', () {
    final v = Vehicle.fromJson(oldVehicle);
    expect(v.displayAppearance, VehicleAppearance.hatchback);
    expect(v.hologram, Hologram.one);
    expect(v.plate, 'ABC-123');
    expect(
      Vehicle.fromJson({...oldVehicle, 'appearance': 'future_value'})
          .displayAppearance,
      VehicleAppearance.hatchback,
    );
  });
  test('artwork survives save and never changes regulatory vehicle kind', () {
    final v = Vehicle.fromJson({...oldVehicle, 'appearance': 'pickup'});
    final restored = Vehicle.fromJson(v.toJson());
    expect(restored.displayAppearance, VehicleAppearance.pickup);
    expect(restored.kind, VehicleKind.car);
    expect(restored.hologram, Hologram.one);
    expect(
      Vehicle.fromJson({...oldVehicle, 'kind': 'motorcycle'}).displayAppearance,
      VehicleAppearance.moto,
    );
  });
}
