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
