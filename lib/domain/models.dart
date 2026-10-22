enum Region { cdmx, toluca, tianguistenco, valleMexico }

enum Hologram { doubleZero, zero, one, two, exempt, none }

enum VehicleKind { car, motorcycle, taxi, cargo, special }

enum VehicleAppearance { hatchback, sedan, suv, pickup, moto }

enum Decision { allowed, restricted, review }

enum DocumentKind { circulationCard, verification, insurance, license, other }

/// Copia local de un documento (foto o PDF) asociada a un vehículo.
/// [file] es una ruta relativa al almacenamiento privado de la app.
class VehicleDocument {
  const VehicleDocument({
    required this.id,
    required this.kind,
    required this.title,
    required this.file,
    required this.addedAt,
    this.expiresOn,
  });
  final String id, title, file;
  final DocumentKind kind;
  final DateTime addedAt;
  final DateTime? expiresOn;
  bool get isPdf => file.toLowerCase().endsWith('.pdf');
  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    'file': file,
    'addedAt': dateKey(addedAt),
    'expiresOn': expiresOn == null ? null : dateKey(expiresOn!),
  };
  factory VehicleDocument.fromJson(Map<String, dynamic> j) => VehicleDocument(
    id: j['id'] as String,
    kind:
        DocumentKind.values.where((k) => k.name == j['kind']).firstOrNull ??
        DocumentKind.other,
    title: j['title'] as String? ?? '',
    file: j['file'] as String,
    addedAt: DateTime.parse(j['addedAt'] as String),
    expiresOn: j['expiresOn'] == null
        ? null
        : DateTime.parse(j['expiresOn'] as String),
  );
}

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
DateTime civilDate(DateTime d) => DateTime(d.year, d.month, d.day);

class Vehicle {
  const Vehicle({
    required this.id,
    required this.name,
    required this.plate,
    required this.modelYear,
    required this.origin,
    required this.issuer,
    required this.hologram,
    required this.kind,
    this.validUntil,
    this.lastVerified,
    this.isPermit = false,
    this.appearance = VehicleAppearance.hatchback,
    this.documents = const [],
  });
  final String id, name, plate, origin, issuer;
  final List<VehicleDocument> documents;
  Vehicle withDocuments(List<VehicleDocument> value) => Vehicle(
    id: id,
    name: name,
    plate: plate,
    modelYear: modelYear,
    origin: origin,
    issuer: issuer,
    hologram: hologram,
    kind: kind,
    validUntil: validUntil,
    lastVerified: lastVerified,
    isPermit: isPermit,
    appearance: appearance,
    documents: value,
  );
  final int modelYear;
  final Hologram hologram;
  final VehicleKind kind;
  final VehicleAppearance appearance;
  VehicleAppearance get displayAppearance => kind == VehicleKind.motorcycle
      ? VehicleAppearance.moto
      : appearance == VehicleAppearance.moto
      ? VehicleAppearance.hatchback
      : appearance;
  final DateTime? validUntil, lastVerified;
  final bool isPermit;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'plate': plate,
    'modelYear': modelYear,
    'origin': origin,
    'issuer': issuer,
    'hologram': hologram.name,
    'kind': kind.name,
    'appearance': appearance.name,
    'validUntil': validUntil == null ? null : dateKey(validUntil!),
    'lastVerified': lastVerified == null ? null : dateKey(lastVerified!),
    'isPermit': isPermit,
    'documents': documents.map((d) => d.toJson()).toList(),
  };
  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
    id: j['id'] as String,
    name: j['name'] as String,
    plate: j['plate'] as String,
    modelYear: j['modelYear'] as int,
    origin: j['origin'] as String,
    issuer: j['issuer'] as String,
    hologram: Hologram.values.byName(j['hologram'] as String),
    kind: VehicleKind.values.byName(j['kind'] as String),
    appearance:
        VehicleAppearance.values
            .where((v) => v.name == j['appearance'])
            .firstOrNull ??
        VehicleAppearance.hatchback,
    validUntil: j['validUntil'] == null
        ? null
        : DateTime.parse(j['validUntil']),
    lastVerified: j['lastVerified'] == null
        ? null
        : DateTime.parse(j['lastVerified']),
    isPermit: j['isPermit'] == true,
    documents: ((j['documents'] as List?) ?? const [])
        .map((e) => VehicleDocument.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );
}

class LegalSource {
  const LegalSource({
    required this.id,
    required this.title,
    required this.url,
    required this.sections,
  });
  final String id, title, url, sections;
  factory LegalSource.fromJson(Map<String, dynamic> j) => LegalSource(
    id: j['id'],
    title: j['title'],
    url: j['url'],
    sections: j['sections'],
  );
}

class RulePolicy {
  RulePolicy({
    required this.version,
    required this.region,
    required this.from,
    required this.through,
    required this.sources,
    required this.weekdays,
    required this.recognized,
    required this.zeroOnly,
    required this.firstNumericGroup,
    required this.fifthSaturdayReview,
    required this.enabled,
  });
  final String version;
  final Region region;
  final DateTime from, through;
  final List<LegalSource> sources;
  final Map<int, List<int>> weekdays;
  final Set<String> recognized, zeroOnly;
  final bool firstNumericGroup, fifthSaturdayReview, enabled;
  factory RulePolicy.fromJson(Map<String, dynamic> j) {
    if (j['schemaVersion'] != 1) {
      throw const FormatException('Unsupported rules schema');
    }
    final from = DateTime.parse(j['reviewFrom']);
    final through = DateTime.parse(j['reviewThrough']);
    if (through.isBefore(from) || (j['sources'] as List).isEmpty) {
      throw const FormatException('Invalid policy validity');
    }
    final sources = (j['sources'] as List)
        .map((e) => LegalSource.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    for (final source in sources) {
      final u = Uri.parse(source.url);
      if (u.scheme != 'https' ||
          !(u.host.endsWith('.gob.mx') || u.host.endsWith('.cdmx.gob.mx'))) {
        throw const FormatException('Non-official legal source');
      }
    }
    final weekdays = (j['weekdayDigits'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(int.parse(k), List<int>.from(v)),
    );
    if (weekdays.length != 5 ||
        weekdays.entries.any(
          (e) => e.key < 1 || e.key > 5 || e.value.any((d) => d < 0 || d > 9),
        ) ||
        weekdays.values.expand((e) => e).toSet().length != 10) {
      throw const FormatException('Invalid weekly calendar');
    }
    return RulePolicy(
      version: j['version'],
      region: Region.values.byName(j['region']),
      from: from,
      through: through,
      sources: sources,
      weekdays: weekdays,
      recognized: Set<String>.from(j['recognizedIssuers']),
      zeroOnly: Set<String>.from(j['zeroOnlyIssuers']),
      firstNumericGroup: j['firstNumericGroup'] == true,
      fifthSaturdayReview: j['fifthSaturdayReview'] == true,
      enabled: j['enabled'] == true,
    );
  }
}

class TimeWindow {
  const TimeWindow(this.startMinute, this.endMinute, this.reason);
  final int startMinute, endMinute;
  final String reason;
  bool contains(int minute) => minute >= startMinute && minute < endMinute;
  String get label => '${_time(startMinute)}–${_time(endMinute)}';
  String _time(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
}

class OfficialNotice {
  OfficialNotice({
    required this.id,
    required this.region,
    required this.from,
    required this.until,
    required this.title,
    required this.url,
    required this.kind,
    required this.digits,
    required this.holograms,
    required this.startMinute,
    required this.endMinute,
  });
  final String id, title, url, kind;
  final Region region;
  final DateTime from, until;
  final List<int> digits;
  final List<Hologram> holograms;
  final int startMinute, endMinute;
  factory OfficialNotice.fromJson(Map<String, dynamic> j) {
    final url = Uri.parse(j['sourceUrl']);
    final start = j['startMinute'] as int, end = j['endMinute'] as int;
    final kind = j['kind'] as String;
    final from = DateTime.parse(j['from']), until = DateTime.parse(j['until']);
    final digits = List<int>.from(j['digits']);
    if (url.scheme != 'https' ||
        !url.host.endsWith('.gob.mx') ||
        start < 0 ||
        end > 1440 ||
        end <= start ||
        !['restriction', 'suspension'].contains(kind) ||
        until.isBefore(from) ||
        digits.any((d) => d < 0 || d > 9)) {
      throw const FormatException('Invalid official notice');
    }
    return OfficialNotice(
      id: j['id'],
      region: Region.values.byName(j['region']),
      from: from,
      until: until,
      title: j['title'],
      url: j['sourceUrl'],
      kind: kind,
      digits: digits,
      holograms: (j['holograms'] as List)
          .map((e) => Hologram.values.byName(e))
          .toList(),
      startMinute: start,
      endMinute: end,
    );
  }
  bool matches(Vehicle v, DateTime date, Region area, int digit) =>
      region == area &&
      !civilDate(date).isBefore(civilDate(from)) &&
      !civilDate(date).isAfter(civilDate(until)) &&
      (digits.isEmpty || digits.contains(digit)) &&
      (holograms.isEmpty || holograms.contains(v.hologram));
}

class NoticeFeed {
  const NoticeFeed({
    this.items = const [],
    this.complete = false,
    this.region,
    this.forDate,
    this.checkedAt,
    this.freshUntil,
  });
  final List<OfficialNotice> items;
  final bool complete;
  final Region? region;
  final DateTime? forDate, checkedAt, freshUntil;
  bool isFresh(DateTime date, Region area, DateTime now) =>
      complete &&
      region == area &&
      forDate != null &&
      dateKey(date) == dateKey(forDate!) &&
      checkedAt != null &&
      !checkedAt!.isAfter(now.toUtc().add(const Duration(minutes: 2))) &&
      freshUntil != null &&
      freshUntil!.isAfter(now.toUtc()) &&
      now.toUtc().difference(checkedAt!) <= const Duration(hours: 3);
}

class CirculationResult {
  const CirculationResult({
    required this.ordinary,
    required this.windows,
    required this.reason,
    required this.policy,
    required this.noticesConfirmed,
    this.noticeTitles = const [],
    this.notices = const [],
  });
  final Decision ordinary;
  final List<TimeWindow> windows;
  final String reason;
  final RulePolicy policy;
  final bool noticesConfirmed;
  final List<String> noticeTitles;
  final List<OfficialNotice> notices;
  Decision atMinute(int minute) => windows.any((w) => w.contains(minute))
      ? Decision.restricted
      : ordinary == Decision.review
      ? Decision.review
      : (!noticesConfirmed ? Decision.review : Decision.allowed);
}
