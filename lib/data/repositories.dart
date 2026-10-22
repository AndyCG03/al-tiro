import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../domain/models.dart';

class DataSnapshot {
  const DataSnapshot(this.policy, this.feed, {required this.remote});
  final RulePolicy policy;
  final NoticeFeed feed;
  final bool remote;
}

abstract interface class CirculationRepository {
  Future<DataSnapshot> load(Region region, DateTime date);
  void close();
}

class BundledRepository implements CirculationRepository {
  Map<String, dynamic>? _bundle;
  @override
  Future<DataSnapshot> load(Region region, DateTime date) async {
    _bundle ??= jsonDecode(
      await rootBundle.loadString('assets/data/rules.json'),
    ) as Map<String, dynamic>;
    final policy = RulePolicy.fromJson(
      Map<String, dynamic>.from(
        (_bundle!['policies'] as List).firstWhere(
          (p) => p['region'] == region.name,
        ),
      ),
    );
    return DataSnapshot(policy, const NoticeFeed(), remote: false);
  }

  @override
  void close() {}
}

/// API-first when configured, with explicit unconfirmed state on fallback.
class ApiRepository implements CirculationRepository {
  ApiRepository({
    required this.baseUrl,
    required this.fallback,
    http.Client? client,
  }) : _client = client ?? http.Client() {
    final uri = Uri.parse(baseUrl);
    final loopback = ['localhost', '127.0.0.1', '::1'].contains(uri.host);
    if (uri.scheme != 'https' &&
        !(kDebugMode && loopback && uri.scheme == 'http')) {
      throw ArgumentError('API_BASE_URL must be HTTPS');
    }
  }
  final String baseUrl;
  final CirculationRepository fallback;
  final http.Client _client;
  Uri endpoint(String path, Map<String, String> query) =>
      Uri.parse('${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/v1/$path')
          .replace(queryParameters: query);
  @override
  Future<DataSnapshot> load(Region region, DateTime date) async {
    try {
      final responses = await Future.wait([
        _client
            .get(
              endpoint('rules', {'region': region.name}),
              headers: {'Accept': 'application/json'},
            )
            .timeout(const Duration(seconds: 10)),
        _client
            .get(
              endpoint('notices', {
                'region': region.name,
                'date': dateKey(date),
              }),
              headers: {'Accept': 'application/json'},
            )
            .timeout(const Duration(seconds: 10)),
      ]);
      if (responses.any(
        (r) => r.statusCode != 200 || r.bodyBytes.length > 1000000,
      )) {
        throw const FormatException('Invalid API response');
      }
      final policy = RulePolicy.fromJson(
        jsonDecode(utf8.decode(responses[0].bodyBytes)) as Map<String, dynamic>,
      );
      final j = jsonDecode(
        utf8.decode(responses[1].bodyBytes),
      ) as Map<String, dynamic>;
      if (j['schemaVersion'] != 1 ||
          j['region'] != region.name ||
          j['date'] != dateKey(date) ||
          policy.region != region) {
        throw const FormatException('Mismatched query context');
      }
      final feed = NoticeFeed(
        items: (j['items'] as List)
            .map((n) => OfficialNotice.fromJson(Map<String, dynamic>.from(n)))
            .toList(),
        complete: j['coverage'] == 'complete',
        region: region,
        forDate: DateTime.parse(j['date']),
        checkedAt: DateTime.parse(j['checkedAt']).toUtc(),
        freshUntil: DateTime.parse(j['freshUntil']).toUtc(),
      );
      return DataSnapshot(policy, feed, remote: true);
    } catch (_) {
      // Never reuse a previously positive decision when the API cannot be checked.
      return fallback.load(region, date);
    }
  }

  @override
  void close() {
    _client.close();
    fallback.close();
  }
}
