import 'models.dart';

/// Pure civil-date rules. No network, localization or device time-zone assumptions.
class RulesEngine {
  const RulesEngine();
  int digitFor(String plate, {required bool firstGroup}) {
    final groups = RegExp(r'\d+').allMatches(plate).toList();
    if (groups.isEmpty) {
      return 0;
    } // Letters-only plates: blue / even.
    final group = (firstGroup ? groups.first : groups.last).group(0)!;
    return int.parse(group[group.length - 1]);
  }

  CirculationResult evaluate({
    required Vehicle vehicle,
    required DateTime date,
    required RulePolicy policy,
    NoticeFeed feed = const NoticeFeed(),
    required DateTime now,
  }) {
    final d = civilDate(date);
    final confirmed = feed.isFresh(d, policy.region, now);
    CirculationResult result(
      Decision decision,
      String reason, [
      List<TimeWindow> windows = const [],
      List<OfficialNotice> notices = const [],
    ]) => CirculationResult(
      ordinary: decision,
      windows: windows,
      reason: reason,
      policy: policy,
      noticesConfirmed: confirmed,
      noticeTitles: notices.map((n) => n.title).toList(),
      notices: notices,
    );
    if (!policy.enabled ||
        d.isBefore(policy.from) ||
        d.isAfter(policy.through)) {
      return result(Decision.review, 'policyReview');
    }
    if (vehicle.isPermit || vehicle.kind == VehicleKind.special) {
      return result(Decision.review, 'specialReview');
    }
    if (vehicle.kind == VehicleKind.taxi || vehicle.kind == VehicleKind.cargo) {
      return result(Decision.review, 'serviceReview');
    }
    final digit = digitFor(vehicle.plate, firstGroup: policy.firstNumericGroup);
    final notices = confirmed
        ? feed.items
              .where((n) => n.matches(vehicle, d, policy.region, digit))
              .toList()
        : <OfficialNotice>[];
    if (notices.any((n) => n.kind == 'suspension') &&
        notices.any((n) => n.kind == 'restriction')) {
      return result(Decision.review, 'conflictingNotices', [], notices);
    }
    if (notices.any((n) => n.kind == 'suspension')) {
      // Only a full-day suspension may clear the ordinary calendar automatically.
      if (notices.any((n) => n.startMinute != 0 || n.endMinute != 1440)) {
        return result(Decision.review, 'specialReview', [], notices);
      }
      return result(Decision.allowed, 'officialSuspension', [], notices);
    }
    final extra = notices
        .where((n) => n.kind == 'restriction')
        .map((n) => TimeWindow(n.startMinute, n.endMinute, 'extraordinary'))
        .toList();
    if (vehicle.kind == VehicleKind.motorcycle) {
      return result(
        extra.isEmpty ? Decision.allowed : Decision.restricted,
        'motorcycleExempt',
        extra,
        notices,
      );
    }
    if (vehicle.hologram != Hologram.none &&
        (vehicle.validUntil == null ||
            d.isAfter(civilDate(vehicle.validUntil!)))) {
      // Distinguir tres situaciones para poder explicarlas al usuario:
      // sin vigencia capturada, constancia ya vencida hoy, o vencimiento
      // futuro anterior a la fecha consultada.
      final reason = vehicle.validUntil == null
          ? 'missingValidity'
          : civilDate(vehicle.validUntil!).isBefore(civilDate(now))
          ? 'expiredVerification'
          : 'validityEnds';
      return result(Decision.review, reason, extra, notices);
    }
    final recognized =
        policy.recognized.contains(vehicle.issuer) ||
        (policy.zeroOnly.contains(vehicle.issuer) &&
            [Hologram.doubleZero, Hologram.zero].contains(vehicle.hologram));
    final foreign = vehicle.hologram == Hologram.none || !recognized;
    if (!foreign &&
        [
          Hologram.zero,
          Hologram.doubleZero,
          Hologram.exempt,
        ].contains(vehicle.hologram)) {
      return result(
        extra.isEmpty ? Decision.allowed : Decision.restricted,
        'hologramExempt',
        extra,
        notices,
      );
    }
    final windows = <TimeWindow>[...extra];
    var reason = 'ordinaryAllowed';
    if (policy.weekdays[d.weekday]?.contains(digit) == true) {
      windows.add(const TimeWindow(300, 1320, 'weekday'));
      reason = 'weekday';
    }
    if (d.weekday == DateTime.saturday) {
      final ordinal = ((d.day - 1) ~/ 7) + 1;
      if (foreign || vehicle.hologram == Hologram.two) {
        windows.add(const TimeWindow(300, 1320, 'everySaturday'));
        reason = 'everySaturday';
      } else if (ordinal == 5 && policy.fifthSaturdayReview) {
        return result(Decision.review, 'fifthSaturdayReview', extra, notices);
      } else if (ordinal < 5 && (digit.isOdd == ordinal.isOdd)) {
        windows.add(const TimeWindow(300, 1320, 'alternateSaturday'));
        reason = 'alternateSaturday';
      }
    }
    if (foreign &&
        d.weekday <= DateTime.friday &&
        !windows.any((w) => w.startMinute <= 300 && w.endMinute >= 660)) {
      windows.add(const TimeWindow(300, 660, 'foreignMorning'));
      reason = 'foreignMorning';
    }
    windows.sort((a, b) => a.startMinute.compareTo(b.startMinute));
    return result(
      windows.isEmpty ? Decision.allowed : Decision.restricted,
      extra.isNotEmpty ? 'extraordinary' : reason,
      windows,
      notices,
    );
  }
}
