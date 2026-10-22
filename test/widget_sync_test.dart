import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:al_tiro/application/app_controller.dart';
import 'package:al_tiro/application/widget_sync.dart';
import 'package:al_tiro/data/repositories.dart';
import 'package:al_tiro/domain/models.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tz_data.initializeTimeZones();
    await initializeDateFormatting('es');
  });

  testWidgets('el widget sin autos pide agregar uno', (tester) async {
    final a = AppController(BundledRepository());
    await tester.runAsync(() => a.initialize());
    final data = WidgetSync(a).payload();
    expect(data['state'], 'empty');
    expect(data['headline'], 'Agrega tu auto');
    expect(data['plate'], '');
  });

  testWidgets('el widget resume hoy con símbolo, placa y vigencia', (
    tester,
  ) async {
    final a = AppController(BundledRepository());
    await tester.runAsync(() => a.initialize());
    await tester.runAsync(
      () => a.saveVehicle(
        const Vehicle(
          id: 'v1',
          name: 'Mi auto',
          plate: 'ABC-123',
          modelYear: 2014,
          origin: 'CDMX',
          issuer: 'CDMX',
          hologram: Hologram.one,
          kind: VehicleKind.car,
        ),
      ),
    );
    final data = WidgetSync(a).payload();
    expect(['allowed', 'restricted', 'review'], contains(data['state']));
    expect(data['plate'], 'ABC-123');
    expect((data['headline'] as String).isNotEmpty, isTrue);
    expect(
      (data['validUntil'] as int) > a.now.millisecondsSinceEpoch,
      isTrue,
      reason:
          'El dato debe caducar en el futuro (fin de día o cambio de horario)',
    );
    a.language = 'en';
    expect(WidgetSync(a).payload()['pill'], isNot('Circula'));
  });
}
