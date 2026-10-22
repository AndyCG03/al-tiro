import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/repositories.dart';
import '../domain/models.dart';
import '../domain/rules_engine.dart';

class AppController extends ChangeNotifier {
  AppController(this.repository, {this.preview = false});
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
      loading = false,
      storageWarning = false;
  DataSnapshot? snapshot;
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
    loading = true;
    notifyListeners();
    try {
      final data = await repository.load(region, selectedDate);
      if (token == _request) {
        snapshot = data;
      }
    } finally {
      if (token == _request) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> setRegion(Region value) async {
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
    _selectedDate = civilDate(value);
    notifyListeners();
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
      vehicles[i] = value;
    }
    selectedId = value.id;
    notifyListeners();
    await _save();
  }

  Future<void> removeVehicle(String id) async {
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
