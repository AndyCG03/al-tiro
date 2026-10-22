import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hoy_circula_mx/data/repositories.dart';
import 'package:hoy_circula_mx/domain/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bundle = jsonDecode(
    File('assets/data/rules.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final policy = (bundle['policies'] as List).firstWhere(
    (p) => p['region'] == 'cdmx',
  );
  final date = DateTime(2026, 10, 22);
  final now = DateTime.now().toUtc();
  Map<String, dynamic> notices({String region = 'cdmx'}) => {
    'schemaVersion': 1,
    'region': region,
    'date': '2026-10-22',
    'coverage': 'complete',
    'checkedAt': now.toIso8601String(),
    'freshUntil': now.add(const Duration(minutes: 30)).toIso8601String(),
    'items': [],
  };
  test(
    'API requests only region and date, validates context and fresh coverage',
    () async {
      final seen = <Uri>[];
      final repo = ApiRepository(
        baseUrl: 'https://api.example.test',
        fallback: BundledRepository(),
        client: MockClient((r) async {
          seen.add(r.url);
          return http.Response(
            jsonEncode(r.url.path.endsWith('/rules') ? policy : notices()),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final result = await repo.load(Region.cdmx, date);
      expect(result.remote, true);
      expect(result.feed.isFresh(date, Region.cdmx, now), true);
      expect(seen.map((u) => u.path).toSet(), {'/v1/rules', '/v1/notices'});
      expect(seen.any((u) => u.query.contains('plate')), false);
      repo.close();
    },
  );
  test('server errors and invalid coverage fall back without claiming no contingency', () async {
    for (final wrongRegion in [false, true]) {
      final repo = ApiRepository(
        baseUrl: 'https://api.example.test',
        fallback: BundledRepository(),
        client: MockClient(
          (r) async => wrongRegion
              ? http.Response(
                  jsonEncode(
                    r.url.path.endsWith('/rules')
                        ? policy
                        : notices(region: 'toluca'),
                  ),
                  200,
                )
              : http.Response('unavailable', 503),
        ),
      );
      final result = await repo.load(Region.cdmx, date);
      expect(result.remote, false);
      expect(result.feed.complete, false);
      repo.close();
    }
  });
  test('rules without legal sources or official URLs are rejected', () {
    final bad = Map<String, dynamic>.from(policy);
    bad['sources'] = [
      {
        'id': 'bad',
        'title': 'Not official',
        'url': 'https://example.com',
        'sections': 'none',
      },
    ];
    expect(() => RulePolicy.fromJson(bad), throwsFormatException);
  });
  test('insecure nonlocal API endpoints are rejected', () {
    expect(
      () => ApiRepository(
        baseUrl: 'http://example.com',
        fallback: BundledRepository(),
      ),
      throwsArgumentError,
    );
  });
}
