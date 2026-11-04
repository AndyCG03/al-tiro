import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:al_tiro/application/app_controller.dart';
import 'package:al_tiro/data/document_store.dart';
import 'package:al_tiro/data/repositories.dart';
import 'package:al_tiro/domain/models.dart';

void main() {
  late Directory tmp;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tz_data.initializeTimeZones();
    await initializeDateFormatting('es');
    tmp = await Directory.systemTemp.createTemp('al_tiro_docs_test');
  });
  tearDown(() async {
    if (await tmp.exists()) {
      await tmp.delete(recursive: true);
    }
  });

  const car = Vehicle(
    id: 'v1',
    name: 'Mi auto',
    plate: 'ABC-123',
    modelYear: 2014,
    origin: 'CDMX',
    issuer: 'CDMX',
    hologram: Hologram.one,
    kind: VehicleKind.car,
  );

  testWidgets(
    'a vehicle photo survives editing and is cleaned up on replacement',
    (tester) async {
      final store = DocumentStore(root: () async => tmp);
      final controller = AppController(
        BundledRepository(),
        documentStore: store,
      );
      await tester.runAsync(() async {
        await controller.initialize();
        await controller.saveVehicle(
          Vehicle.fromJson(car.toJson()..remove('photoPath')),
        );
        await controller.saveVehiclePhoto(
          car.id,
          Uint8List.fromList([1, 2, 3]),
          'jpg',
        );
        final first = await store.resolve(
          controller.vehicleById(car.id)!.photoPath,
        );
        await controller.saveVehicle(car);
        final reopened = AppController(
          BundledRepository(),
          documentStore: store,
        );
        await reopened.initialize();
        expect(
          await (await store.resolve(reopened.vehicleById(car.id)!.photoPath))
              .readAsBytes(),
          [1, 2, 3],
        );
        await reopened.saveVehiclePhoto(
          car.id,
          Uint8List.fromList([4, 5]),
          'jpg',
        );
        expect(await first.exists(), isFalse);
        final second = await store.resolve(
          reopened.vehicleById(car.id)!.photoPath,
        );
        await reopened.removeVehiclePhoto(car.id);
        expect(reopened.vehicleById(car.id)!.photoPath, isEmpty);
        expect(await second.exists(), isFalse);
        reopened.dispose();
      });
      controller.dispose();
    },
  );

  testWidgets('maintenance survives vehicle edits and reopening', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final a = AppController(BundledRepository());
      await a.initialize();
      await a.saveVehicle(
        Vehicle.fromJson(car.toJson()..remove('maintenance')),
      );
      await a.saveMaintenance(
        car.id,
        MaintenanceEntry(
          id: 'service',
          title: 'Cambio de aceite',
          date: DateTime(2026, 10, 20),
          odometerKm: 112000,
          costCents: 74550,
          provider: 'Taller',
          nextServiceOn: DateTime(2027, 4, 20),
        ),
      );
      await a.saveVehicle(car);

      final b = AppController(BundledRepository());
      await b.initialize();
      final saved = b.vehicleById(car.id)!.maintenance.single;
      expect(saved.odometerKm, 112000);
      expect(saved.costCents, 74550);
      expect(saved.provider, 'Taller');
      expect(saved.nextServiceOn, DateTime(2027, 4, 20));
      await b.removeMaintenance(car.id, 'service');
      expect(b.vehicleById(car.id)!.maintenance, isEmpty);
    });
  });

  test(
    'store rejects bad extensions, oversize files and path tricks',
    () async {
      final store = DocumentStore(root: () async => tmp);
      expect(DocumentStore.normalizeExtension('EXE'), isNull);
      expect(DocumentStore.normalizeExtension('.JPG'), 'jpg');
      await expectLater(
        store.save(
          vehicleId: 'v1',
          docId: 'd1',
          extension: 'exe',
          bytes: Uint8List(4),
        ),
        throwsFormatException,
      );
      await expectLater(
        store.save(
          vehicleId: 'v1',
          docId: 'd1',
          extension: 'pdf',
          bytes: Uint8List(DocumentStore.maxBytes + 1),
        ),
        throwsFormatException,
      );
      await expectLater(store.resolve('../secret.pdf'), throwsFormatException);
      await expectLater(store.resolve('a/b/c.pdf'), throwsFormatException);
    },
  );

  testWidgets('documents attach to a car, persist and are removed with it', (
    tester,
  ) async {
    final store = DocumentStore(root: () async => tmp);
    final a = AppController(BundledRepository(), documentStore: store);
    await tester.runAsync(() async {
      await a.initialize();
      await a.saveVehicle(car);
      final doc = await a.addDocument(
        vehicleId: 'v1',
        kind: DocumentKind.verification,
        title: ' Constancia ',
        extension: 'JPG',
        bytes: Uint8List.fromList([1, 2, 3]),
        expiresOn: DateTime(2027, 1, 31),
      );
      expect(doc.title, 'Constancia');
      expect(a.vehicleById('v1')!.documents, hasLength(1));
      expect((await store.resolve(doc.file)).existsSync(), isTrue);

      // Editar el auto no debe perder sus documentos al reabrir la app.
      final b = AppController(BundledRepository(), documentStore: store);
      await b.initialize();
      final saved = b.vehicleById('v1')!.documents.single;
      expect(saved.kind, DocumentKind.verification);
      expect(saved.expiresOn, DateTime(2027, 1, 31));

      await a.removeDocument('v1', doc.id);
      expect(a.vehicleById('v1')!.documents, isEmpty);
      expect((await store.resolve(doc.file)).existsSync(), isFalse);

      final doc2 = await a.addDocument(
        vehicleId: 'v1',
        kind: DocumentKind.insurance,
        title: '',
        extension: 'pdf',
        bytes: Uint8List.fromList([9]),
      );
      final path = (await store.resolve(doc2.file)).path;
      await a.removeVehicle('v1');
      expect(File(path).existsSync(), isFalse);
    });
  });
}
