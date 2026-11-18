// Configura los archivos nativos generados por `flutter create`:
//   - AndroidManifest.xml  -> permisos y <queries>
//   - build.gradle(.kts)   -> minSdk 24 (requerido por speech_to_text)
//   - Info.plist (iOS)     -> textos de permisos y esquemas consultables
//
// Se ejecuta desde la raíz del proyecto:  dart tool/configure_platforms.dart
// Es idempotente: si ya se aplicó, no vuelve a modificar nada.
import 'dart:io';

const _androidPermissions = '''
    <!-- Bitácora de Campo: permisos de hardware -->
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.INTERNET"/>
    <!-- Requeridos por speech_to_text en Android 12+ -->
    <uses-permission android:name="android.permission.BLUETOOTH"/>
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
''';

const _androidQueryIntents = '''
        <!-- Servicio de reconocimiento de voz (speech_to_text) -->
        <intent>
            <action android:name="android.speech.RecognitionService"/>
        </intent>
        <!-- Abrir enlaces https, p. ej. Google Maps (url_launcher) -->
        <intent>
            <action android:name="android.intent.action.VIEW"/>
            <data android:scheme="https"/>
        </intent>
''';

const _iosKeys = '''
	<key>NSCameraUsageDescription</key>
	<string>Necesitamos la cámara para adjuntar fotos a tus entradas.</string>
	<key>NSPhotoLibraryUsageDescription</key>
	<string>Necesitamos acceder a tu galería para elegir imágenes.</string>
	<key>NSMicrophoneUsageDescription</key>
	<string>Necesitamos el micrófono para dictar el contenido de tus entradas.</string>
	<key>NSSpeechRecognitionUsageDescription</key>
	<string>Usamos reconocimiento de voz para transcribir tu dictado.</string>
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>Guardamos tu ubicación actual al registrar cada entrada.</string>
	<key>LSApplicationQueriesSchemes</key>
	<array>
		<string>https</string>
		<string>comgooglemaps</string>
	</array>
''';

void main() {
  _patchAndroidManifest(File('android/app/src/main/AndroidManifest.xml'));
  _patchGradle();
  _patchInfoPlist(File('ios/Runner/Info.plist'));
  stdout.writeln('Configuración de plataformas terminada.');
}

void _patchAndroidManifest(File file) {
  if (!file.existsSync()) {
    stderr.writeln('No se encontró ${file.path}; se omite Android.');
    return;
  }
  var text = file.readAsStringSync();
  if (text.contains('android.permission.RECORD_AUDIO')) {
    stdout.writeln('AndroidManifest.xml ya estaba configurado.');
    return;
  }

  // 1) Permisos justo después de la etiqueta <manifest ...>.
  text = text.replaceFirstMapped(
    RegExp(r'<manifest[^>]*>'),
    (m) => '${m[0]}\n$_androidPermissions',
  );

  // 2) <queries>: se agrega al bloque existente o se crea uno nuevo.
  if (text.contains('<queries>')) {
    text = text.replaceFirst('<queries>', '<queries>\n$_androidQueryIntents');
  } else {
    text = text.replaceFirst(
      '</manifest>',
      '    <queries>\n$_androidQueryIntents    </queries>\n</manifest>',
    );
  }

  file.writeAsStringSync(text);
  stdout.writeln('AndroidManifest.xml actualizado.');
}

void _patchGradle() {
  for (final path in [
    'android/app/build.gradle.kts',
    'android/app/build.gradle',
  ]) {
    final file = File(path);
    if (!file.existsSync()) continue;

    var text = file.readAsStringSync();
    final original = text;

    // minSdk = flutter.minSdkVersion  ->  minSdk = 24
    text = text.replaceAllMapped(
      RegExp(r'(minSdk(?:Version)?)(\s*=?\s*)flutter\.minSdkVersion'),
      (m) => '${m[1]}${m[2]}24',
    );

    // minSdk con un número menor a 24  ->  24
    text = text.replaceAllMapped(
      RegExp(r'(minSdk(?:Version)?)(\s*=?\s*)(\d+)'),
      (m) => int.parse(m[3]!) < 24 ? '${m[1]}${m[2]}24' : m[0]!,
    );

    if (text != original) {
      file.writeAsStringSync(text);
      stdout.writeln('$path: minSdk ajustado a 24.');
    } else {
      stdout.writeln('$path: sin cambios (minSdk ya es suficiente).');
    }
    return;
  }
  stderr.writeln('No se encontró build.gradle de la app; revisa minSdk a mano.');
}

void _patchInfoPlist(File file) {
  if (!file.existsSync()) {
    stderr.writeln('No se encontró ${file.path}; se omite iOS.');
    return;
  }
  var text = file.readAsStringSync();
  if (text.contains('NSMicrophoneUsageDescription')) {
    stdout.writeln('Info.plist ya estaba configurado.');
    return;
  }

  // Las claves se insertan antes del último </dict> del plist.
  final index = text.lastIndexOf('</dict>');
  if (index == -1) {
    stderr.writeln('Info.plist con formato inesperado; agrega las claves a mano.');
    return;
  }
  text = text.substring(0, index) + _iosKeys + text.substring(index);
  file.writeAsStringSync(text);
  stdout.writeln('Info.plist actualizado.');
}
