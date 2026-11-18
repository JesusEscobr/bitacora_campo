/// Excepción propia de la aplicación.
///
/// Las capas de datos y servicios capturan errores técnicos (SQLite,
/// plugins, permisos) y los relanzan como [AppException] con un mensaje
/// legible. La UI solo conoce este tipo, así no depende de detalles
/// de implementación (principio de inversión de dependencias).
class AppException implements Exception {
  /// Mensaje amigable para mostrar al usuario.
  final String message;

  /// Error original, útil para depuración.
  final Object? cause;

  const AppException(this.message, {this.cause});

  @override
  String toString() =>
      'AppException: $message${cause != null ? ' (causa: $cause)' : ''}';
}
