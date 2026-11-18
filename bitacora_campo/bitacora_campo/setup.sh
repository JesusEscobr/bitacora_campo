#!/usr/bin/env bash
# Prepara el proyecto: genera las carpetas android/ e ios/, aplica permisos
# y descarga dependencias. Uso:  bash setup.sh
set -e
cd "$(dirname "$0")"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter no está en el PATH. Instálalo desde https://docs.flutter.dev/get-started/install"
  exit 1
fi

# 1) Respaldo de los archivos propios (flutter create podría sobrescribirlos).
BACKUP="$(mktemp -d)"
cp -R lib "$BACKUP/lib"
cp -R test "$BACKUP/test"
cp pubspec.yaml "$BACKUP/pubspec.yaml"

# 2) Genera las plataformas nativas.
flutter create --project-name bitacora_campo --org com.example --platforms android,ios .

# 3) Restaura el código propio.
rm -rf lib test
cp -R "$BACKUP/lib" lib
cp -R "$BACKUP/test" test
cp "$BACKUP/pubspec.yaml" pubspec.yaml
rm -rf "$BACKUP"

# 4) Permisos Android/iOS y minSdk.
dart tool/configure_platforms.dart

# 5) Dependencias.
flutter pub get

echo
echo "Listo. Conecta un dispositivo y ejecuta:  flutter run"
