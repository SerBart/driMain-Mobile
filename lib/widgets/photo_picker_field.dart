import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Uniwersalny widget do wyboru / podglądu zdjęcia w formularzach.
/// Użycie:
/// PhotoPickerField(
///   base64: _photoBase64,
///   onChanged: (b64) => setState(() => _photoBase64 = b64),
/// )
class PhotoPickerField extends StatefulWidget {
  final String? base64;
  final ValueChanged<String?> onChanged;
  final double thumbSize;
  final double maxWidth;
  final int imageQuality;
  final bool showRemove;

  const PhotoPickerField({
    super.key,
    required this.base64,
    required this.onChanged,
    this.thumbSize = 80,
    this.maxWidth = 1600,
    this.imageQuality = 80,
    this.showRemove = true,
  });

  @override
  State<PhotoPickerField> createState() => _PhotoPickerFieldState();
}

class _PhotoPickerFieldState extends State<PhotoPickerField> {
  bool _picking = false;

  Future<void> _pick({required bool camera}) async {
    if (_picking) return;
    _picking = true;
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: widget.maxWidth,
        imageQuality: widget.imageQuality,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        widget.onChanged(base64Encode(bytes));
      }
    } finally {
      _picking = false;
    }
  }

  void _showBig() {
    final b64 = widget.base64;
    if (b64 == null) return;
    late final Image image;
    try {
      image = Image.memory(base64Decode(b64), fit: BoxFit.contain);
    } catch (_) {
      return;
    }
    showDialog(
      context: context,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(16),
          child: InteractiveViewer(child: image),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final has = widget.base64 != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: has ? _showBig : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: widget.thumbSize,
            height: widget.thumbSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(.4),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: has
                ? Image.memory(
                    base64Decode(widget.base64!),
                    fit: BoxFit.cover,
                  )
                : Icon(
                    Icons.image,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(.4),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.photo),
              onPressed: () => _pick(camera: false),
              label: Text(has ? 'Zmień zdjęcie' : 'Wybierz zdjęcie'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt_outlined),
                  onPressed: () => _pick(camera: true),
                  label: const Text('Aparat'),
                ),
                if (has && widget.showRemove) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => widget.onChanged(null),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      'Usuń',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ]
              ],
            ),
          ],
        )
      ],
    );
  }
}