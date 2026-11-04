import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../application/app_controller.dart';
import '../domain/models.dart';
import '../l10n/app_text.dart';
import 'documents_page.dart' show cameraSupported;
import 'vehicle_art.dart';

class VehiclePortrait extends StatefulWidget {
  const VehiclePortrait({
    super.key,
    required this.controller,
    required this.vehicle,
  });

  final AppController controller;
  final Vehicle vehicle;

  @override
  State<VehiclePortrait> createState() => _VehiclePortraitState();
}

class _VehiclePortraitState extends State<VehiclePortrait> {
  Future<File>? _photo;
  bool _takingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  @override
  void didUpdateWidget(covariant VehiclePortrait oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehicle.photoPath != widget.vehicle.photoPath) _loadPhoto();
  }

  void _loadPhoto() {
    final path = widget.vehicle.photoPath;
    _photo = kIsWeb || path.isEmpty
        ? null
        : widget.controller.documentStore.resolve(path);
  }

  Future<void> _takePhoto() async {
    final controller = widget.controller;
    final vehicleId = widget.vehicle.id;
    final t = AppText.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _takingPhoto = true);
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
        requestFullMetadata: false,
      );
      if (photo == null) return;
      final extension = photo.name.contains('.')
          ? photo.name.split('.').last
          : 'jpg';
      await controller.saveVehiclePhoto(
        vehicleId,
        await photo.readAsBytes(),
        extension,
      );
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(t('vehiclePhotoError'))));
      }
    } finally {
      if (mounted) setState(() => _takingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const width = 124.0, height = 82.0;
    final t = AppText.of(context);
    final fallback = VehicleArt(
      widget.vehicle.displayAppearance,
      width: width,
      height: height,
    );
    final photo = _photo;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photo == null)
            fallback
          else
            FutureBuilder<File>(
              key: ValueKey(widget.vehicle.photoPath),
              future: photo,
              builder: (_, snapshot) {
                final file = snapshot.data;
                if (file == null) return fallback;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    file,
                    fit: BoxFit.cover,
                    cacheWidth: 512,
                    semanticLabel: t('vehiclePhotoOf')
                        .replaceAll('{name}', widget.vehicle.name),
                    errorBuilder: (_, _, _) => fallback,
                  ),
                );
              },
            ),
          if (cameraSupported && !widget.controller.preview)
            Positioned(
              right: 0,
              bottom: 0,
              child: IconButton.filledTonal(
                onPressed: _takingPhoto ? null : _takePhoto,
                tooltip: t(
                  photo == null ? 'takeVehiclePhoto' : 'retakeVehiclePhoto',
                ),
                icon: const Icon(Icons.photo_camera_outlined, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}
