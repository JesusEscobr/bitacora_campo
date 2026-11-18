import 'package:flutter/material.dart';
import 'app_exception.dart';

/// Utilidad para mostrar errores al usuario mediante [SnackBar].
class SnackBarHelper {
  SnackBarHelper._(); // No instanciable.

  /// Muestra un SnackBar de error a partir de cualquier excepción.
  static void showError(BuildContext context, Object error) {
    final message =
        error is AppException ? error.message : 'Ocurrió un error inesperado.';
    _show(context, message, isError: true);
  }

  /// Muestra un SnackBar informativo (éxito, avisos).
  static void showInfo(BuildContext context, String message) {
    _show(context, message, isError: false);
  }

  static void _show(BuildContext context, String message,
      {required bool isError}) {
    // Evita usar un contexto que ya no está montado.
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade700 : null,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
