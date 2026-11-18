# 📔 Bitácora de Campo

Aplicación móvil en **Flutter** para registrar momentos o entradas diarias con soporte multimedia y datos contextuales: foto (cámara o galería), dictado por voz y ubicación GPS, todo guardado localmente en SQLite.

## 🏗️ Arquitectura

Arquitectura limpia por capas. Las dependencias apuntan hacia abstracciones y se ensamblan en un único lugar (`main.dart`, el *composition root*).

| Capa | Responsabilidad | Depende de |
|---|---|---|
| `views` | Pantallas y flujo de interacción | `database` (interfaz), `services`, `widgets`, `models` |
| `widgets` | Componentes visuales reutilizables | `models` |
| `services` | Acceso a hardware (cámara, micrófono, GPS, mapas) | `utils` |
| `database` | Persistencia SQLite | `models`, `utils` |
| `models` | Entidades de dominio (`DiaryEntry`) | — |
| `utils` | `AppException` y `SnackBarHelper` | — |

### Principios SOLID aplicados

- **S (responsabilidad única):** `DatabaseHelper` solo abre la conexión; `SqliteDiaryRepository` solo hace consultas; cada servicio envuelve un único plugin.
- **O (abierto/cerrado):** se puede añadir una nueva fuente de datos implementando `DiaryRepository` sin modificar las vistas.
- **L (sustitución de Liskov):** cualquier implementación de `DiaryRepository` es intercambiable.
- **I (segregación de interfaces):** cada servicio expone solo los métodos que su consumidor necesita.
- **D (inversión de dependencias):** las vistas reciben `DiaryRepository` y los servicios por constructor; no crean instancias concretas.

---

## 📁 Estructura del proyecto

```
bitacora_campo/
├── android/app/src/main/AndroidManifest.xml
├── ios/Runner/Info.plist
├── assets/images/profile.png
├── test/diary_entry_test.dart
├── tool/configure_platforms.dart   # permisos Android/iOS y minSdk
├── setup.sh · setup.bat            # preparan el proyecto
├── pubspec.yaml
└── lib/
    ├── main.dart
    ├── routes/
    │   └── app_routes.dart
    ├── models/
    │   └── diary_entry.dart
    ├── database/
    │   ├── database_helper.dart
    │   ├── diary_repository.dart
    │   └── sqlite_diary_repository.dart
    ├── services/
    │   ├── media_service.dart
    │   ├── speech_service.dart
    │   ├── location_service.dart
    │   └── maps_launcher_service.dart
    ├── utils/
    │   ├── app_exception.dart
    │   └── snackbar_helper.dart
    ├── views/
    │   ├── home_screen.dart
    │   ├── detail_screen.dart
    │   ├── form_screen.dart
    │   └── settings_screen.dart
    └── widgets/
        ├── app_drawer.dart
        ├── entry_card.dart
        └── entry_thumbnail.dart
```

## 🚀 Instalación y ejecución

### Opción rápida (proyecto en .zip)

El zip incluye el código (`lib/`), `pubspec.yaml`, los recursos y las pruebas. Las carpetas nativas `android/` e `ios/` las genera Flutter, y un script les aplica los permisos y el `minSdk` necesarios.

```bash
# Windows
cd bitacora_campo-main
cd bitacora_campo
.\setup.bat
```

El script hace lo siguiente: respalda `lib/`, `test/` y `pubspec.yaml`, ejecuta `flutter create`, restaura tus archivos, aplica los permisos con `dart tool/configure_platforms.dart` y corre `flutter pub get`. Después conecta un dispositivo y ejecuta `flutter run`.

### Opción manual

```bash
# 1. Clonar el repositorio
git clone <url-del-repositorio>
cd bitacora_campo

# 2. Instalar dependencias
flutter pub get

# 3. (Solo macOS) instalar pods de iOS
cd ios && pod install && cd ..

# 4. Verificar el entorno
flutter doctor

# 5. Ejecutar en un dispositivo conectado
flutter run
```

> Usa preferentemente un **dispositivo físico**: el micrófono y el GPS no funcionan de forma fiable en muchos emuladores.

Para generar un APK de prueba:

```bash
flutter build apk --release
```



