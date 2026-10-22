import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoy_circula_mx/domain/models.dart';
import 'package:hoy_circula_mx/domain/rules_engine.dart';

void main() {
  const engine = RulesEngine();
  final data = jsonDecode(
    File('assets/data/rules.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  RulePolicy policy([Region region = Region.cdmx]) => RulePolicy.fromJson(
    Map<String, dynamic>.from(
      (data['policies'] as List).firstWhere((p) => p['region'] == region.name),
    ),
  );
  Vehicle car({
    String plate = 'A26-BCD',
    Hologram h = Hologram.one,
    String issuer = 'CDMX',
    VehicleKind kind = VehicleKind.car,
    DateTime? expiry,
    bool permit = false,
    int year = 2016,
  }) => Vehicle(
    id: '1',
    name: 'Mi auto',
    plate: plate,
    modelYear: year,
    origin: 'OTHER',
    issuer: issuer,
    hologram: h,
    kind: kind,
    validUntil: expiry ?? DateTime(2026, 12, 31),
    isPermit: permit,
  );
  final now = DateTime.utc(2026, 10, 22, 16);
  CirculationResult evaluate(
    Vehicle v,
    DateTime d, {
    Region region = Region.cdmx,
    bool fresh = true,
    List<OfficialNotice> notices = const [],
  }) => engine.evaluate(
    vehicle: v,
    date: d,
    policy: policy(region),
    now: now,
    feed: NoticeFeed(
      region: region,
      forDate: d,
      complete: fresh,
      checkedAt: now,
      freshUntil: now.add(const Duration(minutes: 30)),
      items: notices,
    ),
  );

  test('uses last digit of first number group only where required', () {
    expect(engine.digitFor('ABC-12-34', firstGroup: true), 2);
    expect(engine.digitFor('ABC-12-34', firstGroup: false), 4);
    expect(engine.digitFor('A26-BCD', firstGroup: true), 6);
    expect(engine.digitFor('ABC', firstGroup: true), 0);
  });
  for (final entry in {
    1: [5, 6],
    2: [7, 8],
    3: [3, 4],
    4: [1, 2],
    5: [9, 0],
  }.entries) {
    for (final digit in entry.value) {
      test('weekday ${entry.key} restricts digit $digit', () {
        final d = DateTime(2026, 10, 18 + entry.key);
        final result = evaluate(car(plate: 'ABC-$digit-X'), d);
        expect(result.ordinary, Decision.restricted);
        expect(result.windows.first.label, '05:00–22:00');
      });
    }
  }
  test('ordinary restriction ends at 22:00 and starts at 05:00', () {
    final r = evaluate(car(), DateTime(2026, 10, 19));
    expect(r.atMinute(299), Decision.allowed);
    expect(r.atMinute(300), Decision.restricted);
    expect(r.atMinute(1319), Decision.restricted);
    expect(r.atMinute(1320), Decision.allowed);
  });
  test('hologram 1 follows both Saturday parity patterns', () {
    for (final day in [3, 17]) {
      expect(
        evaluate(car(plate: 'A25-BCD'), DateTime(2026, 10, day)).ordinary,
        Decision.restricted,
      );
      expect(
        evaluate(car(), DateTime(2026, 10, day)).ordinary,
        Decision.allowed,
      );
    }
    for (final day in [10, 24]) {
      expect(
        evaluate(car(), DateTime(2026, 10, day)).ordinary,
        Decision.restricted,
      );
      expect(
        evaluate(car(plate: 'A25-BCD'), DateTime(2026, 10, day)).ordinary,
        Decision.allowed,
      );
    }
  });
  test('fifth Saturday is explicitly held for official confirmation', () {
    expect(
      evaluate(car(), DateTime(2026, 10, 31)).reason,
      'fifthSaturdayReview',
    );
  });
  test('hologram 2 restricted on all five Saturdays', () {
    for (final day in [3, 10, 17, 24, 31]) {
      expect(
        evaluate(car(h: Hologram.two), DateTime(2026, 10, day)).ordinary,
        Decision.restricted,
      );
    }
  });
  test('Sunday has no ordinary restriction', () {
    expect(
      evaluate(car(h: Hologram.two), DateTime(2026, 10, 25)).ordinary,
      Decision.allowed,
    );
  });
  test('recognized 0, 00 and E exempt ordinary schedule', () {
    for (final h in [Hologram.zero, Hologram.doubleZero, Hologram.exempt]) {
      expect(
        evaluate(car(h: h), DateTime(2026, 10, 19)).ordinary,
        Decision.allowed,
      );
    }
  });
  test('unrecognized verification adds weekday morning restriction', () {
    final r = evaluate(car(issuer: 'OTHER'), DateTime(2026, 10, 20));
    expect(r.windows.single.label, '05:00–11:00');
    expect(r.atMinute(659), Decision.restricted);
    expect(r.atMinute(660), Decision.allowed);
  });
  test('missing hologram does not acquire an exemption from chosen issuer', () {
    expect(
      evaluate(car(h: Hologram.none), DateTime(2026, 10, 20)).reason,
      'foreignMorning',
    );
  });
  test(
    'outside-origin car with recognized voluntary verification is recognized',
    () {
      expect(
        evaluate(car(h: Hologram.zero), DateTime(2026, 10, 19)).ordinary,
        Decision.allowed,
      );
    },
  );
  test('Guanajuato and Michoacan only 0/00 recognized in Toluca agreement', () {
    for (final issuer in ['GTO', 'MIC']) {
      expect(
        evaluate(
          car(h: Hologram.zero, issuer: issuer),
          DateTime(2026, 10, 19),
          region: Region.toluca,
        ).ordinary,
        Decision.allowed,
      );
      expect(
        evaluate(
          car(issuer: issuer),
          DateTime(2026, 10, 20),
          region: Region.toluca,
        ).reason,
        'foreignMorning',
      );
    }
  });
  test('letters-only plate follows Friday / even treatment', () {
    expect(
      evaluate(car(plate: 'ABC'), DateTime(2026, 10, 23)).ordinary,
      Decision.restricted,
    );
  });
  test('model year never assigns a hologram', () {
    expect(
      evaluate(car(year: 2000), DateTime(2026, 10, 22)).ordinary,
      evaluate(car(year: 2026), DateTime(2026, 10, 22)).ordinary,
    );
  });
  test(
    'expired document, uncovered area, old date and permits require review',
    () {
      expect(
        evaluate(
          car(expiry: DateTime(2026, 10, 21)),
          DateTime(2026, 10, 22),
        ).reason,
        'expiredVerification',
      );
      expect(
        evaluate(
          car(),
          DateTime(2026, 10, 22),
          region: Region.valleMexico,
        ).ordinary,
        Decision.review,
      );
      expect(evaluate(car(), DateTime(2027, 1, 1)).ordinary, Decision.review);
      expect(
        evaluate(car(permit: true), DateTime(2026, 10, 22)).ordinary,
        Decision.review,
      );
      expect(
        evaluate(car(kind: VehicleKind.taxi), DateTime(2026, 10, 22)).reason,
        'serviceReview',
      );
    },
  );
  test('without fresh notices a positive ordinary result is never a full authorization', () {
    final r = evaluate(car(), DateTime(2026, 10, 22), fresh: false);
    expect(r.ordinary, Decision.allowed);
    expect(r.atMinute(600), Decision.review);
  });
  test(
    'known ordinary restriction remains visible even if notices unconfirmed',
    () {
      expect(
        evaluate(car(), DateTime(2026, 10, 19), fresh: false).atMinute(600),
        Decision.restricted,
      );
    },
  );
  test(
    'official extraordinary notice can restrict an ordinarily exempt vehicle',
    () {
      final n = OfficialNotice(
        id: 'test',
        region: Region.cdmx,
        from: DateTime(2026, 10, 22),
        until: DateTime(2026, 10, 22),
        title: 'Test',
        url: 'https://www.gob.mx/comisionambiental',
        kind: 'restriction',
        digits: [6],
        holograms: [Hologram.zero],
        startMinute: 300,
        endMinute: 1320,
      );
      final r = evaluate(
        car(h: Hologram.zero),
        DateTime(2026, 10, 22),
        notices: [n],
      );
      expect(r.atMinute(600), Decision.restricted);
      expect(r.windows.single.reason, 'extraordinary');
    },
  );
  test('mismatched notice region or day does not affect result', () {
    final n = OfficialNotice(
      id: 'test',
      region: Region.toluca,
      from: DateTime(2026, 10, 19),
      until: DateTime(2026, 10, 19),
      title: 'Test',
      url: 'https://sma.edomex.gob.mx/',
      kind: 'restriction',
      digits: [],
      holograms: [],
      startMinute: 0,
      endMinute: 1440,
    );
    expect(
      evaluate(car(), DateTime(2026, 10, 22), notices: [n]).ordinary,
      Decision.allowed,
    );
  });
  test('stale, future-dated, or wrong-day feed cannot confirm notices', () {
    for (final feed in [
      NoticeFeed(
        complete: true,
        region: Region.cdmx,
        forDate: DateTime(2026, 10, 22),
        checkedAt: now.subtract(const Duration(hours: 4)),
        freshUntil: now.add(const Duration(hours: 1)),
      ),
      NoticeFeed(
        complete: true,
        region: Region.cdmx,
        forDate: DateTime(2026, 10, 23),
        checkedAt: now,
        freshUntil: now.add(const Duration(hours: 1)),
      ),
    ]) {
      expect(
        engine
            .evaluate(
              vehicle: car(),
              date: DateTime(2026, 10, 22),
              policy: policy(),
              feed: feed,
              now: now,
            )
            .noticesConfirmed,
        false,
      );
    }
  });
}
