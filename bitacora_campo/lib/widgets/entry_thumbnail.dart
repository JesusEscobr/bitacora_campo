import 'dart:io';
import 'package:flutter/material.dart';

/// Miniatura de la imagen de una entrada, envuelta en un [Hero].
///
/// Para que la animación funcione, la lista y el detalle deben usar el
/// MISMO tag; por eso se genera con [heroTag] a partir del id.
class EntryThumbnail extends StatelessWidget {
  final int entryId;
  final String? imagePath;
  final double size;
  final double borderRadius;

  const EntryThumbnail({
    super.key,
    required this.entryId,
    required this.imagePath,
    this.size = 64,
    this.borderRadius = 12,
  });

  /// Tag único por entrada.
  static String heroTag(int entryId) => 'entry-image-$entryId';

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag(entryId),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(width: size, height: size, child: _buildImage(context)),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final placeholder = Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.image_not_supported_outlined),
    );

    final path = imagePath;
    if (path == null) return placeholder;

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      // Si el archivo fue borrado, se muestra el placeholder sin romper la UI.
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}
