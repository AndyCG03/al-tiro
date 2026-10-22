import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:al_tiro/app.dart';
import 'package:al_tiro/application/app_controller.dart';
import 'package:al_tiro/data/repositories.dart';
import 'package:al_tiro/domain/models.dart';
import 'package:al_tiro/presentation/hologram_guide.dart';
import 'package:al_tiro/presentation/vehicle_art.dart';

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
    await tester.pumpWidget(AlTiroApp(controller: a));
    await tester.pumpAndSettle();
    expect(find.text('Al Tiro'), findsOneWidget);
    await tester.tap(find.text('Comenzar recorrido'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe al menos 2 caracteres.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('profile-name')), 'Ana');
    await tester.tap(find.text('Comenzar recorrido'));
    await tester.pumpAndSettle();
    expect(find.text('Recorrido interactivo'), findsOneWidget);
    expect(
      a.vehicles,
      isEmpty,
      reason: 'Tutorial demo must never become a saved car',
    );
    expect(
      find.text(
        'Para avanzar, toca «Calendario» en la barra inferior o usa el botón de abajo.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Alertas'));
    await tester.pumpAndSettle();
    expect(find.text('Tu día, de un vistazo'), findsOneWidget);
    await tester.tap(find.text('Ir a Calendario'));
    await tester.pumpAndSettle();
    expect(find.text('Tu calendario'), findsOneWidget);
    expect(find.text('Descubre tus días'), findsOneWidget);
    await tester.ensureVisible(find.text('1').first);
    await tester.tap(find.text('1').first);
    await tester.pumpAndSettle();
    final firstDay = DateTime(a.now.year, a.now.month, 1);
    expect(
      find.text(DateFormat('EEEE d MMMM', 'es').format(firstDay)),
      findsOneWidget,
    );

    await tester.tap(find.text('Mis autos'));
    await tester.pumpAndSettle();
    expect(find.text('Demo'), findsOneWidget);
    expect(a.vehicles, isEmpty);
    await tester.tap(find.text('Ir a Alertas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Listo, ir a mi app'));
    await tester.pumpAndSettle();
    expect(a.tutorialComplete, isTrue);
    expect(a.displayName, 'Ana');
    expect(a.vehicles, isEmpty);

    expect(tester.takeException(), isNull, reason: 'Welcome layout');
    await tester.ensureVisible(find.text('Agregar mi auto'));
    await tester.tap(find.text('Agregar mi auto'));
    await tester.pumpAndSettle();
    expect(find.text('Nombre de tu auto'), findsOneWidget);
    expect(find.byType(VehicleArtPicker), findsOneWidget);
    await tester.ensureVisible(find.text('SUV'));
    await tester.tap(find.text('SUV'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<VehicleArtPicker>(find.byType(VehicleArtPicker)).value,
      VehicleAppearance.suv,
    );
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
          appearance: VehicleAppearance.suv,
          validUntil: DateTime(2026, 12, 31),
        ),
      ),
    );
    await tester.runAsync(() => a.saveProfile('Ana'));
    await tester.runAsync(() => a.finishTutorial());
    await tester.runAsync(() => a.setLanguage('en'));
    await tester.runAsync(() => a.setTheme(ThemeMode.dark));
    final b = AppController(BundledRepository());
    await tester.runAsync(() => b.initialize());
    expect(b.displayName, 'Ana');
    expect(b.tutorialComplete, isTrue);
    expect(b.active!.plate, 'A26-BCD');
    expect(b.active!.displayAppearance, VehicleAppearance.suv);
    expect(b.themeMode, ThemeMode.dark);
    expect(b.language, 'en');
    await tester.pumpWidget(AlTiroApp(controller: b));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Confirmation needed'), findsWidgets);
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Guide'), findsNothing);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Know your verification sticker'));
    await tester.tap(find.text('Know your verification sticker'));
    await tester.pumpAndSettle();
    expect(find.text('Know your verification sticker'), findsOneWidget);
    expect(find.byType(HologramExample), findsNWidgets(6));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    a.dispose();
    b.dispose();
  });
}
