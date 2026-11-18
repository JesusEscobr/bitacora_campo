import 'package:url_launcher/url_launcher.dart';
import '../utils/app_exception.dart';

/// Servicio para abrir una ubicación en Google Maps (app o navegador).
class MapsLauncherService {
  /// Abre las coordenadas dadas en Google Maps.
  Future<void> openInMaps(double latitude, double longitude) async {
    try {
      final uri = Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': '$latitude,$longitude',
      });

      // externalApplication abre la app de Maps si está instalada.
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        throw const AppException('No se pudo abrir Google Maps.');
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('No se pudo abrir Google Maps.', cause: e);
    }
  }
}
