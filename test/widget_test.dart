import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:intl/date_symbol_data_local.dart';
import 'package:hoy_circula_mx/app.dart';
import 'package:hoy_circula_mx/application/app_controller.dart';
import 'package:hoy_circula_mx/data/repositories.dart';
import 'package:hoy_circula_mx/domain/models.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tz_data.initializeTimeZones();
    await initializeDateFormatting('es');
  });
  testWidgets('welcome and form work at mobile width', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final a = AppController(BundledRepository());
    await tester.runAsync(() => a.initialize());
    await tester.pumpWidget(HoyCirculaApp(controller: a));
    await tester.pumpAndSettle();
    expect(find.text('Hoy Circula MX'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'Welcome layout');
    await tester.ensureVisible(find.text('Agregar mi auto'));
    await tester.tap(find.text('Agregar mi auto'));
    await tester.pumpAndSettle();
    expect(find.text('Nombre de tu auto'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    a.dispose();
  });
  testWidgets('English and dark theme persist while vehicles survive restart', (
    tester,
  ) async {
    final a = AppController(BundledRepository());
    await tester.runAsync(() => a.initialize());
    await tester.runAsync(
      () => a.saveVehicle(
        Vehicle(
          id: '1',
          name: 'My car',
          plate: 'A26-BCD',
          modelYear: 2016,
          origin: 'CDMX',
          issuer: 'CDMX',
          hologram: Hologram.one,
          kind: VehicleKind.car,
          validUntil: DateTime(2026, 12, 31),
        ),
      ),
    );
    await tester.runAsync(() => a.setLanguage('en'));
    await tester.runAsync(() => a.setTheme(ThemeMode.dark));
    final b = AppController(BundledRepository());
    await tester.runAsync(() => b.initialize());
    expect(b.active!.plate, 'A26-BCD');
    expect(b.themeMode, ThemeMode.dark);
    expect(b.language, 'en');
    await tester.pumpWidget(HoyCirculaApp(controller: b));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Confirmation needed'), findsWidgets);
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    a.dispose();
    b.dispose();
  });
}
