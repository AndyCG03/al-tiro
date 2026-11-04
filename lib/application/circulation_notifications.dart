import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';
import '../l10n/app_text.dart';
import 'app_controller.dart';

class CirculationNotifications {
  CirculationNotifications(this.controller) {
    controller.addListener(_onChange);
    _onChange();
  }

  static const _channel = MethodChannel(
    'mx.sidarta.al_tiro/circulation_alerts',
  );
  static const _lastNotice = 'al_tiro_last_circulation_alert';
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  final AppController controller;
  bool _sending = false;

  static Future<bool> requestPermission() async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('requestPermission') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<void> clear() async {
    if (!supported) return;
    try {
      await _channel.invokeMethod<void>('clear');
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  void _onChange() {
    if (supported &&
        !_sending &&
        controller.circulationNotifications &&
        !controller.loading) {
      unawaited(_sendIfChanged());
    }
  }

  Future<void> _sendIfChanged() async {
    final car = controller.active;
    final now = controller.now;
    if (car == null || dateKey(now) != dateKey(controller.selectedDate)) return;
    final result = controller.evaluate(now, car);
    final decision = notificationDecision(result, now);
    final region = controller.region;
    final context = '${dateKey(now)}|${region.name}|${car.id}|';
    final key = '$context${decision.name}';
    final checkedAt = controller.lastCheckedAt;
    final t = AppText(controller.language);
    _sending = true;
    try {
      final preferences = await SharedPreferences.getInstance();
      final previous = preferences.getString(_lastNotice) ?? '';
      if (previous == key) return;
      if (!controller.circulationNotifications ||
          controller.loading ||
          controller.lastCheckedAt != checkedAt ||
          controller.region != region ||
          controller.active?.id != car.id ||
          dateKey(controller.selectedDate) != dateKey(now)) {
        return;
      }
      final title = t(switch (decision) {
        Decision.allowed => 'circulationNotificationAllowed',
        Decision.restricted => 'circulationNotificationRestricted',
        Decision.review => 'circulationNotificationReview',
      });
      final posted = await _channel.invokeMethod<bool>('post', {
        'title': title,
        'body': t('circulationNotificationBody').replaceAll('{name}', car.name),
        'channelName': t('circulationNotifications'),
        'timeoutMs': notificationLifetime(
          result,
          controller.snapshot?.feed.freshUntil,
          now,
        ).inMilliseconds,
      });
      if (posted == true) await preferences.setString(_lastNotice, key);
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    } finally {
      _sending = false;
    }
  }
}

Decision notificationDecision(CirculationResult? result, DateTime now) =>
    result?.noticesConfirmed == true
    ? result!.atMinute(now.hour * 60 + now.minute)
    : Decision.review;

Duration notificationLifetime(
  CirculationResult? result,
  DateTime? freshUntil,
  DateTime now,
) {
  if (notificationDecision(result, now) == Decision.review ||
      freshUntil == null) {
    return const Duration(minutes: 30);
  }
  final minute = now.hour * 60 + now.minute;
  final nextChange = [
    for (final window in result!.windows) ...[
      window.startMinute,
      window.endMinute,
    ],
  ].where((boundary) => boundary > minute).fold(1440, math.min);
  final windowMs = Duration(
    minutes: nextChange - minute,
    seconds: -now.second,
  ).inMilliseconds;
  final freshMs = freshUntil.difference(now).inMilliseconds;
  return Duration(milliseconds: math.max(1, math.min(windowMs, freshMs)));
}
