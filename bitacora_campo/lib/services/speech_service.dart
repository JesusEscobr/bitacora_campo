import 'package:speech_to_text/speech_to_text.dart';
import '../utils/app_exception.dart';

/// Servicio de dictado por voz (envuelve `speech_to_text`).
///
/// Aísla el plugin de la UI: el formulario solo llama a [start] y [stop]
/// y recibe el texto reconocido por un callback.
class SpeechService {
  final SpeechToText _speech;
  bool _initialized = false;

  SpeechService({SpeechToText? speech}) : _speech = speech ?? SpeechToText();

  /// `true` mientras el micrófono está escuchando.
  bool get isListening => _speech.isListening;

  /// Inicializa el motor de reconocimiento y solicita permisos.
  Future<void> _ensureInitialized(
      {void Function(String message)? onError}) async {
    if (_initialized) return;
    try {
      final available = await _speech.initialize(
        onError: (e) => onError?.call(e.errorMsg),
      );
      if (!available) {
        throw const AppException(
          'El reconocimiento de voz no está disponible o se negó el permiso.',
        );
      }
      _initialized = true;
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('No se pudo iniciar el dictado por voz.', cause: e);
    }
  }

  /// Empieza a escuchar. [onResult] recibe el texto y si es resultado final.
  Future<void> start({
    required void Function(String text, bool isFinal) onResult,
    void Function(String message)? onError,
    String localeId = 'es_MX',
  }) async {
    await _ensureInitialized(onError: onError);
    try {
      await _speech.listen(
        localeId: localeId,
        onResult: (r) => onResult(r.recognizedWords, r.finalResult),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (e) {
      throw AppException('No se pudo iniciar la grabación.', cause: e);
    }
  }

  /// Detiene la escucha y entrega el último resultado.
  Future<void> stop() async {
    try {
      await _speech.stop();
    } catch (e) {
      throw AppException('No se pudo detener la grabación.', cause: e);
    }
  }

  /// Cancela la escucha descartando el resultado.
  Future<void> cancel() async {
    try {
      await _speech.cancel();
    } catch (e) {
      throw AppException('No se pudo cancelar la grabación.', cause: e);
    }
  }
}
