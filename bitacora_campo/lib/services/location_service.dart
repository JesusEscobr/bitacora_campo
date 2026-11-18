import 'package:geolocator/geolocator.dart';
import '../utils/app_exception.dart';

/// Servicio de geolocalización (envuelve `geolocator`).
///
/// Valida que el GPS esté activo y que existan permisos antes de pedir la
/// posición, con mensajes de error específicos para cada caso.
class LocationService {
  /// Obtiene la posición actual del dispositivo.
  Future<Position> getCurrentPosition() async {
    try {
      // 1) ¿Servicio de ubicación activado?
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        throw const AppException('Activa el GPS para guardar la ubicación.');
      }

      // 2) ¿Permiso concedido?
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw const AppException('Permiso de ubicación denegado.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw const AppException(
          'El permiso de ubicación está bloqueado. Habilítalo en Ajustes.',
        );
      }

      // 3) Obtener la posición con un tiempo máximo de espera.
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('No se pudo obtener la ubicación actual.', cause: e);
    }
  }
}
