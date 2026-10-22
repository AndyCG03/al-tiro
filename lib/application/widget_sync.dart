import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../domain/models.dart';
import '../l10n/app_text.dart';
import 'app_controller.dart';

/// Publica un resumen mínimo de hoy para el widget de pantalla de inicio de
/// Android. No guarda placas en ningún servicio: sólo cruza el canal nativo
/// hacia las preferencias privadas de la propia app.
class WidgetSync {
  WidgetSync(this.controller, {MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('mx.sidarta.al_tiro/widget') {
    controller.addListener(_onChange);
    _onChange();
  }

  final AppController controller;
  final MethodChannel _channel;
  Map<String, Object?>? _last;

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void dispose() => controller.removeListener(_onChange);

  /// Datos del widget; separado de la E/S para poder probarlo.
  Map<String, Object?> payload() {
    final t = AppText(controller.language);
    final now = controller.now;
    final today = civilDate(now);
    final endOfDay = DateTime(
      today.year,
      today.month,
      today.day + 1,
    ).millisecondsSinceEpoch;
    final v = controller.active;
    final result = controller.evaluate(today);
    if (v == null || result == null) {
      return {
        'state': 'empty',
        'headline': t('widgetNoVehicle'),
        'pill': t('reviewShort'),
        'plate': '',
        'detail': t('tagline'),
        'date': DateFormat('EEE d MMM', controller.language).format(today),
        'validUntil': endOfDay,
      };
    }
    final minute = now.hour * 60 + now.minute;
    final decision = result.atMinute(minute);
    final state = switch (decision) {
      Decision.allowed => 'allowed',
      Decision.restricted => 'restricted',
      Decision.review => 'review',
    };
    // El estado cambia cuando empieza o termina una ventana horaria.
    var validUntil = endOfDay;
    final midnight = DateTime(today.year, today.month, today.day);
    for (final w in result.windows) {
      for (final edge in [w.startMinute, w.endMinute]) {
        if (edge > minute) {
          final at = midnight.add(Duration(minutes: edge));
          if (at.millisecondsSinceEpoch < validUntil) {
            validUntil = at.millisecondsSinceEpoch;
          }
        }
      }
    }
    String detail = '';
    for (var i = 1; i <= 35; i++) {
      final d = today.add(Duration(days: i));
      if (controller.evaluate(d)?.ordinary == Decision.restricted) {
        detail =
            '${t('widgetNext')}: ${DateFormat('EEE d MMM', controller.language).format(d)}';
        break;
      }
    }
    return {
      'state': state,
      'headline': t(switch (decision) {
        Decision.allowed => 'nowAllowed',
        Decision.restricted => 'nowRestricted',
        Decision.review => 'review',
      }),
      'pill': switch (decision) {
        Decision.allowed => t('widgetAllowedShort'),
        Decision.restricted => t('restrictionShort'),
        Decision.review => t('reviewShort'),
      },
      'plate': v.plate,
      'detail': detail,
      'date': DateFormat('EEE d MMM', controller.language).format(today),
      'validUntil': validUntil,
    };
  }

  Future<void> _onChange() async {
    if (!_supported || controller.preview || controller.snapshot == null) {
      return;
    }
    final next = payload();
    if (mapEquals(next, _last)) {
      return;
    }
    _last = next;
    try {
      await _channel.invokeMethod<void>('update', next);
    } on MissingPluginException {
      // Sin widget nativo (otras plataformas o pruebas).
    } on PlatformException {
      _last = null;
    }
  }
}
