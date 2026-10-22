import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';

import '../application/app_controller.dart';
import '../data/document_store.dart';
import '../domain/models.dart';
import '../l10n/app_text.dart';
import 'widgets.dart';

/// Los documentos viven en el almacenamiento privado del dispositivo; la web
/// no tiene un equivalente seguro, así que allí se desactivan.
bool get documentsSupported => !kIsWeb;
bool get cameraSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

Future<void> openVehicleDocuments(
  BuildContext c,
  AppController controller,
  String vehicleId,
) => Navigator.of(c).push(
  MaterialPageRoute(
    builder: (_) => DocumentsPage(controller: controller, vehicleId: vehicleId),
  ),
);

IconData documentIcon(DocumentKind k) => switch (k) {
  DocumentKind.circulationCard => Icons.badge_outlined,
  DocumentKind.verification => Icons.verified_outlined,
  DocumentKind.insurance => Icons.shield_outlined,
  DocumentKind.license => Icons.credit_card_outlined,
  DocumentKind.other => Icons.description_outlined,
};

String documentKindKey(DocumentKind k) => switch (k) {
  DocumentKind.circulationCard => 'docCirculationCard',
  DocumentKind.verification => 'docVerification',
  DocumentKind.insurance => 'docInsurance',
  DocumentKind.license => 'docLicense',
  DocumentKind.other => 'docOther',
};

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({
    super.key,
    required this.controller,
    required this.vehicleId,
  });
  final AppController controller;
  final String vehicleId;

  @override
  Widget build(BuildContext c) => AnimatedBuilder(
    animation: controller,
    builder: (c, _) {
      final t = AppText.of(c);
      final v = controller.vehicleById(vehicleId);
      if (v == null) {
        return const Scaffold();
      }
      final today = civilDate(controller.now);
      return Scaffold(
        appBar: AppBar(title: Text(t('documents'))),
        floatingActionButton: documentsSupported
            ? FloatingActionButton.extended(
                onPressed: () => showModalBottomSheet<void>(
                  context: c,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) =>
                      AddDocumentSheet(controller: controller, vehicle: v),
                ),
                icon: const Icon(Icons.add),
                label: Text(t('docsAdd')),
              )
            : null,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                children: [
                  Text(v.name, style: Theme.of(c).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Plate(v.plate),
                  const SizedBox(height: 16),
                  Surface(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lock_outline, size: 22),
                        const SizedBox(width: 12),
                        Expanded(child: Text(t('docsPrivacy'))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!documentsSupported)
                    Text(t('docsWeb'))
                  else if (v.documents.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        t('docsEmpty'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(c).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  for (final d in v.documents)
                    _DocumentTile(
                      controller: controller,
                      vehicle: v,
                      doc: d,
                      expired:
                          d.expiresOn != null &&
                          civilDate(d.expiresOn!).isBefore(today),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.controller,
    required this.vehicle,
    required this.doc,
    required this.expired,
  });
  final AppController controller;
  final Vehicle vehicle;
  final VehicleDocument doc;
  final bool expired;

  Future<void> _open(BuildContext c, AppText t) async {
    final messenger = ScaffoldMessenger.of(c);
    try {
      final file = await controller.documentStore.resolve(doc.file);
      if (!await file.exists()) {
        throw const FileSystemException('missing');
      }
      if (doc.isPdf) {
        final r = await OpenFilex.open(file.path);
        if (r.type != ResultType.done) {
          throw const FileSystemException('open');
        }
      } else if (c.mounted) {
        await showDialog<void>(
          context: c,
          builder: (ctx) => Dialog.fullscreen(
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    maxScale: 5,
                    child: Image.file(file, fit: BoxFit.contain),
                  ),
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: IconButton.filledTonal(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                      tooltip: MaterialLocalizations.of(c).closeButtonTooltip,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(t('docsOpenError'))));
    }
  }

  Future<void> _delete(BuildContext c, AppText t) async {
    final ok = await showDialog<bool>(
      context: c,
      builder: (ctx) => AlertDialog(
        title: Text(t('docsDeleteTitle')),
        content: Text(t('docsDeleteBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('delete')),
          ),
        ],
      ),
    );
    if (ok == true) {
      await controller.removeDocument(vehicle.id, doc.id);
    }
  }

  @override
  Widget build(BuildContext c) {
    final t = AppText.of(c);
    final title = doc.title.isEmpty ? t(documentKindKey(doc.kind)) : doc.title;
    final subtitle = [
      if (doc.title.isNotEmpty) t(documentKindKey(doc.kind)),
      '${t('docsAddedOn')}: ${dateKey(doc.addedAt)}',
      if (doc.expiresOn != null)
        '${expired ? t('docsExpired') : t('docsExpires')}: ${dateKey(doc.expiresOn!)}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Surface(
        padding: const EdgeInsets.all(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _open(c, t),
          child: Row(
            children: [
              _Thumb(controller: controller, doc: doc),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(c).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: expired
                            ? Theme.of(c).colorScheme.error
                            : Theme.of(c).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _delete(c, t),
                icon: const Icon(Icons.delete_outline),
                tooltip: t('delete'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatefulWidget {
  const _Thumb({required this.controller, required this.doc});
  final AppController controller;
  final VehicleDocument doc;
  @override
  State<_Thumb> createState() => _ThumbState();
}

class _ThumbState extends State<_Thumb> {
  late final Future<File?> file = _load();
  Future<File?> _load() async {
    try {
      return await widget.controller.documentStore.resolve(widget.doc.file);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext c) {
    final icon = Icon(
      widget.doc.isPdf
          ? Icons.picture_as_pdf_outlined
          : documentIcon(widget.doc.kind),
      size: 30,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 64,
        height: 64,
        color: Theme.of(c).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: widget.doc.isPdf
            ? icon
            : FutureBuilder<File?>(
                future: file,
                builder: (c, s) => s.data == null
                    ? icon
                    : Image.file(
                        s.data!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        cacheWidth: 160,
                        errorBuilder: (_, _, _) => icon,
                      ),
              ),
      ),
    );
  }
}

class AddDocumentSheet extends StatefulWidget {
  const AddDocumentSheet({
    super.key,
    required this.controller,
    required this.vehicle,
  });
  final AppController controller;
  final Vehicle vehicle;
  @override
  State<AddDocumentSheet> createState() => _AddDocumentSheetState();
}

class _AddDocumentSheetState extends State<AddDocumentSheet> {
  DocumentKind kind = DocumentKind.verification;
  DateTime? expires;
  bool busy = false;
  final name = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final today = civilDate(widget.controller.now);
    final d = await showDatePicker(
      context: context,
      initialDate: expires ?? today,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null && mounted) {
      setState(() => expires = d);
    }
  }

  Future<void> _pick(bool camera) async {
    final t = AppText.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => busy = true);
    try {
      String? ext;
      Uint8List? bytes;
      if (camera) {
        final x = await ImagePicker().pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 2400,
        );
        if (x != null) {
          bytes = await x.readAsBytes();
          ext = DocumentStore.normalizeExtension(
            x.name.contains('.') ? x.name.split('.').last : 'jpg',
          );
        }
      } else {
        final f = await openFile(
          acceptedTypeGroups: [
            XTypeGroup(
              label: t('documents'),
              extensions: DocumentStore.allowedExtensions,
              mimeTypes: const ['image/*', 'application/pdf'],
              uniformTypeIdentifiers: const ['public.image', 'com.adobe.pdf'],
            ),
          ],
        );
        if (f != null) {
          ext = DocumentStore.normalizeExtension(
            f.name.contains('.') ? f.name.split('.').last : null,
          );
          if (ext == null) {
            throw const FormatException('type');
          }
          bytes = await f.readAsBytes();
        }
      }
      if (bytes == null || ext == null) {
        if (mounted) {
          setState(() => busy = false);
        }
        return;
      }
      if (bytes.length > DocumentStore.maxBytes) {
        throw const FormatException('size');
      }
      await widget.controller.addDocument(
        vehicleId: widget.vehicle.id,
        kind: kind,
        title: name.text,
        extension: ext,
        bytes: bytes,
        expiresOn: expires,
      );
      nav.pop();
      messenger.showSnackBar(SnackBar(content: Text(t('docsAdded'))));
    } on FormatException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.message == 'size' ? t('docsTooBig') : t('docsBadType'),
          ),
        ),
      );
      if (mounted) {
        setState(() => busy = false);
      }
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(t('docsError'))));
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext c) {
    final t = AppText.of(c);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(c).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('docsKind'), style: Theme.of(c).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final k in DocumentKind.values)
                  ChoiceChip(
                    label: Text(t(documentKindKey(k))),
                    avatar: Icon(documentIcon(k), size: 18),
                    selected: kind == k,
                    onSelected: (_) => setState(() => kind = k),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: name,
              maxLength: 60,
              decoration: InputDecoration(labelText: t('docsName')),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : _pickExpiry,
                    icon: const Icon(Icons.event_outlined),
                    label: Text(
                      '${t('docsExpires')}: ${expires == null ? t('docsNoExpiry') : dateKey(expires!)}',
                    ),
                  ),
                ),
                if (expires != null)
                  IconButton(
                    onPressed: () => setState(() => expires = null),
                    icon: const Icon(Icons.clear),
                    tooltip: t('docsNoExpiry'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (busy)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (cameraSupported)
                FilledButton.icon(
                  onPressed: () => _pick(true),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(t('docsTakePhoto')),
                ),
              if (cameraSupported) const SizedBox(height: 10),
              if (cameraSupported)
                OutlinedButton.icon(
                  onPressed: () => _pick(false),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(t('docsChooseFile')),
                )
              else
                FilledButton.icon(
                  onPressed: () => _pick(false),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(t('docsChooseFile')),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
