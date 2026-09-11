/// Choosing a profile picture.
///
/// A round glass well with the chosen photo inside it, or a prompt when there is none.
/// Tapping opens a sheet offering the camera and the library, because on a phone the
/// picture somebody wants is about as likely to be one they are about to take as one they
/// already have.
///
/// The widget only produces a file. Uploading it is the caller's job, so this stays usable
/// on any screen that needs a picture.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';
import '../theme/app_glass.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'glass_surface.dart';

class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    required this.file,
    required this.onChanged,
    this.size = 112,
    this.errorText,
    this.enabled = true,
  });

  /// The chosen picture, or null when none has been chosen yet.
  final File? file;

  final ValueChanged<File?> onChanged;
  final double size;

  /// Shown under the well when the field is required and empty.
  final String? errorText;

  final bool enabled;

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    // Resized on the device rather than after upload: a modern phone camera produces
    // several megabytes, and none of that detail survives being shown at 112 points.
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked != null) onChanged(File(picked.path));
  }

  Future<void> _openSheet(BuildContext context) async {
    final colors = context.vocaColors;
    final text = context.vocaText;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(VocaSpacing.md),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.photo_camera_outlined, color: colors.primary),
                  title: Text('Suratga olish', style: text.subtitle),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pick(context, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library_outlined, color: colors.primary),
                  title: Text('Galereyadan tanlash', style: text.subtitle),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pick(context, ImageSource.gallery);
                  },
                ),
                if (file != null)
                  ListTile(
                    leading: Icon(Icons.delete_outline_rounded, color: colors.error),
                    title: Text('Rasmni olib tashlash',
                        style: text.subtitle.copyWith(color: colors.error)),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onChanged(null);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final glass = context.vocaGlass;
    final text = context.vocaText;
    final hasError = errorText != null;

    return Column(
      children: [
        Semantics(
          button: true,
          label: file == null ? 'Profil rasmini tanlash' : 'Profil rasmini almashtirish',
          child: GestureDetector(
            onTap: enabled ? () => _openSheet(context) : null,
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GlassSurface(
                      borderRadius: BorderRadius.circular(size / 2),
                      tint: glass.tint.withValues(alpha: glass.controlOpacity),
                      borderWidth: hasError ? 2 : 1.4,
                      padding: EdgeInsets.zero,
                      child: file == null
                          ? Center(
                              child: Icon(
                                Icons.add_a_photo_outlined,
                                size: size * 0.3,
                                color: hasError ? colors.error : colors.textSecondary,
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(size / 2),
                              child: Image.file(
                                file!,
                                fit: BoxFit.cover,
                                width: size,
                                height: size,
                              ),
                            ),
                    ),
                  ),

                  // A small badge rather than a caption: once a picture is in place the
                  // affordance still has to be visible, without covering the face.
                  if (file != null)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(VocaSpacing.xxs),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.background, width: 2),
                        ),
                        child: Icon(Icons.edit_rounded,
                            size: 14, color: colors.onPrimary),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: VocaSpacing.xs),
        Text(
          errorText ?? (file == null ? 'Profil rasmini qo‘shing' : 'Rasm tanlandi'),
          style: text.caption.copyWith(
            color: hasError ? colors.error : colors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
