import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import 'app.dart';
import 'application/app_controller.dart';
import 'data/repositories.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();
  await initializeDateFormatting('es');
  const api = String.fromEnvironment('API_BASE_URL');
  final bundled = BundledRepository();
  final repository = api.isEmpty
      ? bundled
      : ApiRepository(baseUrl: api, fallback: bundled);
  final controller = AppController(repository);
  await controller.initialize();
  runApp(HoyCirculaApp(controller: controller));
}
