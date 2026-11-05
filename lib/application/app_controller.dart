import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/document_store.dart';
import '../data/repositories.dart';
import '../domain/models.dart';
import '../domain/rules_engine.dart';

class AppController extends ChangeNotifier {
  AppController(
    this.repository, {
    this.preview = false,
    DocumentStore? documentStore,
  }) : documentStore = documentStore ?? DocumentStore();
  final DocumentStore documentStore;
  final bool preview;
  String displayName = "";
  bool tutorialComplete = false;
  final CirculationRepository repository;
  final RulesEngine engine = const RulesEngine();
  SharedPreferences? _prefs;
  List<Vehicle> vehicles = [];
  String? selectedId;
  Region region = Region.cdmx;
  ThemeMode themeMode = ThemeMode.system;
  String language = 'es';
  bool reminders = true,
      extraordinary = true,
      circulationNotifications = false,
      loading = false,
      storageWarning = false;
  DataSnapshot? snapshot;
  final _lastUpdates = <Region, DateTime>{};
  DateTime? get lastUpdatedAt => _lastUpdates[region];
  final _photoChanges = <String>{};
  int _request = 0;
  DateTime get now => tz.TZDateTime.now(tz.getLocation('America/Mexico_City'));
  DateTime? _selectedDate;
  DateTime get selectedDate => _selectedDate ?? civilDate(now);
  Vehicle? get active =>
      vehicles.where((v) => v.id == selectedId).firstOrNull ??
      vehicles.firstOrNull;
  CirculationResult? evaluate([DateTime? date, Vehicle? vehicle]) {
    if (snapshot == null || (vehicle ?? active) == null) {
      return null;
    }
    return engine.evaluate(
      vehicle: (vehicle ?? active)!,
      date: date ?? selectedDate,
      policy: snapshot!.policy,
      feed: snapshot!.feed,
      now: now,
    );
  }

  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      for (final area in Region.values) {
        final value = _prefs!.getString('circulation_update_${area.name}');
        final date = value == null ? null : DateTime.tryParse(value);
        if (date != null) _lastUpdates[area] = date;
      }
      final raw = _prefs!.getString('hcmx_state_v1');
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        if (j['schemaVersion'] != 1) {
          throw const FormatException('Unknown storage version');
        }
        vehicles = (j['vehicles'] as List)
            .map((e) => Vehicle.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        displayName = j['displayName'] as String? ?? '';
        tutorialComplete = j['tutorialComplete'] == true;
        selectedId = j['selectedId'];
        region = Region.values.byName(j['region']);
        themeMode = ThemeMode.values.byName(j['theme']);
        language = ['es', 'en'].contains(j['language']) ? j['language'] : 'es';
        reminders = j['reminders'] == true;
        extraordinary = j['extraordinary'] == true;
        circulationNotifications = j['circulationNotifications'] == true;
      }
    } catch (_) {
      storageWarning = true;
    }
    await refresh();
  }

  Future<void> _save() async {
    if (preview) {
      return;
    }
    try {
      final ok = await _prefs?.setString(
        'hcmx_state_v1',
        jsonEncode({
          'schemaVersion': 1,
          'displayName': displayName,
          'tutorialComplete': tutorialComplete,
          'vehicles': vehicles.map((v) => v.toJson()).toList(),
          'selectedId': selectedId,
          'region': region.name,
          'theme': themeMode.name,
          'language': language,
          'reminders': reminders,
          'extraordinary': extraordinary,
          'circulationNotifications': circulationNotifications,
        }),
      );
      storageWarning = ok != true;
    } catch (_) {
      storageWarning = true;
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    final token = ++_request;
    final area = region;
    final date = selectedDate;
    loading = true;
    notifyListeners();
    try {
      final data = await repository.load(area, date);
      if (token == _request) {
        snapshot = data;
        final checked = now;
        if (data.remote && dateKey(date) == dateKey(checked)) {
          _lastUpdates[area] = checked;
          if (!preview) {
            try {
              await _prefs?.setString(
                'circulation_update_${area.name}',
                checked.toUtc().toIso8601String(),
              );
            } catch (_) {
              storageWarning = true;
            }
          }
        }
      }
    } catch (_) {
      if (token == _request) {
        snapshot = null;
      }
    } finally {
      if (token == _request) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> setRegion(Region value) async {
    _request++;
    region = value;
    snapshot = null;
    notifyListeners();
    await _save();
    await refresh();
  }

  Future<void> saveProfile(String name) async {
    displayName = name.trim();
    notifyListeners();
    await _save();
  }

  Future<void> finishTutorial() async {
    tutorialComplete = true;
    notifyListeners();
    await _save();
  }

  Future<void> setDate(DateTime value) async {
    final date = civilDate(value);
    _selectedDate = date == civilDate(now) ? null : date;
    await refresh();
  }

  Future<void> select(String id) async {
    selectedId = id;
    notifyListeners();
    await _save();
  }

  Future<void> saveVehicle(Vehicle value) async {
    final i = vehicles.indexWhere((v) => v.id == value.id);
    if (i < 0) {
      vehicles.add(value);
    } else {
      vehicles[i] = value.withRecords(
        documents: vehicles[i].documents,
        maintenance: vehicles[i].maintenance,
        photoPath: vehicles[i].photoPath,
      );
    }
    selectedId = value.id;
    notifyListeners();
    await _save();
  }

  Vehicle? vehicleById(String id) =>
      vehicles.where((v) => v.id == id).firstOrNull;

  Future<void> saveVehiclePhoto(
    String vehicleId,
    Uint8List bytes,
    String extension,
  ) => _updateVehiclePhoto(vehicleId, bytes, extension);

  Future<void> removeVehiclePhoto(String vehicleId) =>
      _updateVehiclePhoto(vehicleId, null, '');

  Future<void> _updateVehiclePhoto(
    String vehicleId,
    Uint8List? bytes,
    String extension,
  ) async {
    if (vehicleById(vehicleId) == null || preview) return;
    if (!_photoChanges.add(vehicleId)) {
      throw StateError('Vehicle photo is being saved');
    }
    try {
      var path = '';
      if (bytes != null) {
        final imageType = DocumentStore.normalizeExtension(extension);
        if (imageType == null || imageType == 'pdf' || bytes.isEmpty) {
          throw const FormatException('Invalid vehicle photo');
        }
        path = await documentStore.save(
          vehicleId: vehicleId,
          docId: 'photo-${DateTime.now().microsecondsSinceEpoch}',
          extension: imageType,
          bytes: bytes,
        );
      }
      await _setVehiclePhoto(vehicleId, path);
    } finally {
      _photoChanges.remove(vehicleId);
    }
  }

  Future<void> _setVehiclePhoto(String vehicleId, String path) async {
    final index = vehicles.indexWhere((v) => v.id == vehicleId);
    if (index < 0) {
      if (path.isNotEmpty) await documentStore.delete(path);
      return;
    }
    final previous = vehicles[index].photoPath;
    if (previous == path) return;
    vehicles[index] = vehicles[index].withRecords(photoPath: path);
    await _save();
    if (storageWarning) {
      final current = vehicles.indexWhere((v) => v.id == vehicleId);
      if (current >= 0 && vehicles[current].photoPath == path) {
        vehicles[current] = vehicles[current].withRecords(photoPath: previous);
        notifyListeners();
      }
      throw StateError('Could not save vehicle photo');
    }
    if (previous.isNotEmpty) {
      try {
        await documentStore.delete(previous);
      } catch (_) {
        // Una foto reemplazada no debe bloquear el acceso al vehículo.
      }
    }
  }

  Future<void> saveMaintenance(String vehicleId, MaintenanceEntry entry) async {
    final index = vehicles.indexWhere((v) => v.id == vehicleId);
    if (index < 0) return;
    final vehicle = vehicles[index];
    vehicles[index] = vehicle.withRecords(
      maintenance: [
        entry,
        ...vehicle.maintenance.where((item) => item.id != entry.id),
      ],
    );
    notifyListeners();
    await _save();
  }

  Future<void> removeMaintenance(String vehicleId, String entryId) async {
    final index = vehicles.indexWhere((v) => v.id == vehicleId);
    if (index < 0) return;
    final vehicle = vehicles[index];
    vehicles[index] = vehicle.withRecords(
      maintenance: [
        for (final item in vehicle.maintenance)
          if (item.id != entryId) item,
      ],
    );
    notifyListeners();
    await _save();
  }

  /// Guarda una copia del documento en el almacenamiento privado y la asocia
  /// al vehículo. Lanza [FormatException] si el tipo o tamaño no son válidos.
  Future<VehicleDocument> addDocument({
    required String vehicleId,
    required DocumentKind kind,
    required String title,
    required String extension,
    required Uint8List bytes,
    DateTime? expiresOn,
  }) async {
    final i = vehicles.indexWhere((v) => v.id == vehicleId);
    if (i < 0) {
      throw StateError('Vehículo desconocido');
    }
    final docId = DateTime.now().microsecondsSinceEpoch.toString();
    final file = await documentStore.save(
      vehicleId: vehicleId,
      docId: docId,
      extension: extension,
      bytes: bytes,
    );
    final doc = VehicleDocument(
      id: docId,
      kind: kind,
      title: title.trim(),
      file: file,
      addedAt: civilDate(now),
      expiresOn: expiresOn == null ? null : civilDate(expiresOn),
    );
    vehicles[i] = vehicles[i].withDocuments([...vehicles[i].documents, doc]);
    notifyListeners();
    await _save();
    return doc;
  }

  Future<void> removeDocument(String vehicleId, String docId) async {
    final i = vehicles.indexWhere((v) => v.id == vehicleId);
    if (i < 0) {
      return;
    }
    final doc = vehicles[i].documents.where((d) => d.id == docId).firstOrNull;
    if (doc == null) {
      return;
    }
    vehicles[i] = vehicles[i].withDocuments(
      vehicles[i].documents.where((d) => d.id != docId).toList(),
    );
    notifyListeners();
    await _save();
    try {
      await documentStore.delete(doc.file);
    } catch (_) {
      // El archivo huérfano no afecta al usuario; el registro ya se eliminó.
    }
  }

  Future<void> removeVehicle(String id) async {
    try {
      await documentStore.deleteVehicle(id);
    } catch (_) {}
    vehicles.removeWhere((v) => v.id == id);
    if (selectedId == id) {
      selectedId = vehicles.firstOrNull?.id;
    }
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(ThemeMode value) async {
    themeMode = value;
    notifyListeners();
    await _save();
  }

  Future<void> setLanguage(String value) async {
    language = value;
    notifyListeners();
    await _save();
  }

  Future<void> setReminders(bool value) async {
    reminders = value;
    notifyListeners();
    await _save();
  }

  Future<void> setCirculationNotifications(bool value) async {
    circulationNotifications = value;
    await _save();
  }

  Future<void> setExtraordinary(bool value) async {
    extraordinary = value;
    notifyListeners();
    await _save();
  }

  @override
  void dispose() {
    _request++;
    repository.close();
    super.dispose();
  }
}
