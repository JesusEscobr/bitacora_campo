import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../utils/app_exception.dart';

/// Servicio de multimedia: cámara y galería.
///
/// La imagen elegida se COPIA al directorio de documentos de la app, porque
/// la ruta que devuelve image_picker es temporal y el sistema puede borrarla.
class MediaService {
  final ImagePicker _picker;

  MediaService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// Abre la cámara o la galería según [source].
  /// Devuelve la ruta local persistente, o `null` si el usuario cancela.
  Future<String?> pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600, // Reduce el peso de la imagen.
        imageQuality: 85,
      );
      if (picked == null) return null; // Usuario canceló.
      return await _persistImage(picked);
    } catch (e) {
      final origin = source == ImageSource.camera ? 'la cámara' : 'la galería';
      throw AppException(
        'No se pudo acceder a $origin. Revisa los permisos.',
        cause: e,
      );
    }
  }

  /// Copia el archivo a /entry_images dentro de documentos de la app.
  Future<String> _persistImage(XFile file) async {
    final docs = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(docs.path, 'entry_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}';
    final saved = await File(file.path).copy(p.join(imagesDir.path, fileName));
    return saved.path;
  }

  /// Elimina una imagen local (al borrar una entrada o reemplazar la foto).
  Future<void> deleteImage(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      throw AppException('No se pudo eliminar la imagen.', cause: e);
    }
  }
}
