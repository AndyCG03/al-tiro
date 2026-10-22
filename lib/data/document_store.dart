import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Guarda copias de documentos en el almacenamiento privado de la app.
/// Nada se sube a ningún servicio ni se escribe en la galería.
class DocumentStore {
  DocumentStore({Future<Directory> Function()? root})
    : _root = root ?? _defaultRoot;

  static const allowedExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'pdf',
  ];
  static const maxBytes = 15 * 1024 * 1024;

  final Future<Directory> Function() _root;

  static Future<Directory> _defaultRoot() async {
    final base = await getApplicationDocumentsDirectory();
    return Directory('${base.path}${Platform.pathSeparator}al_tiro_docs');
  }

  static String _safe(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');

  /// Extensión normalizada o null si no está permitida.
  static String? normalizeExtension(String? raw) {
    final e = (raw ?? '').toLowerCase().replaceAll('.', '');
    return allowedExtensions.contains(e) ? e : null;
  }

  /// Devuelve la ruta relativa guardada (`vehiculo/documento.ext`).
  Future<String> save({
    required String vehicleId,
    required String docId,
    required String extension,
    required Uint8List bytes,
  }) async {
    final ext = normalizeExtension(extension);
    if (ext == null) {
      throw const FormatException('Tipo de archivo no permitido');
    }
    if (bytes.length > maxBytes) {
      throw const FormatException('Archivo demasiado grande');
    }
    final relative = '${_safe(vehicleId)}/${_safe(docId)}.$ext';
    final file = await resolve(relative);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return relative;
  }

  static final _relative = RegExp(
    r'^[A-Za-z0-9_-]+/[A-Za-z0-9_-]+\.(jpg|jpeg|png|webp|heic|pdf)$',
  );

  /// Resuelve una ruta relativa; rechaza cualquier cosa que no tenga la forma
  /// `vehiculo/documento.ext` para impedir salir de la carpeta privada.
  Future<File> resolve(String relative) async {
    if (!_relative.hasMatch(relative)) {
      throw const FormatException('Ruta inválida');
    }
    final root = await _root();
    return File(
      '${root.path}${Platform.pathSeparator}${relative.replaceAll('/', Platform.pathSeparator)}',
    );
  }

  Future<void> delete(String relative) async {
    final file = await resolve(relative);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> deleteVehicle(String vehicleId) async {
    final root = await _root();
    final dir = Directory(
      '${root.path}${Platform.pathSeparator}${_safe(vehicleId)}',
    );
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
