# 📔 Bitácora de Campo

Aplicación móvil en **Flutter** para registrar momentos o entradas diarias con soporte multimedia y datos contextuales: foto (cámara o galería), dictado por voz y ubicación GPS, todo guardado localmente en SQLite.

> **Proyecto académico** · Desarrollo de aplicaciones móviles con Flutter
> **Autor:** _Tu nombre_ · **Matrícula:** _XXXXXXX_ · **Materia:** _Nombre de la materia_ · **Profesor:** _Nombre_ · **Fecha:** _DD/MM/AAAA_

---

## 📑 Contenido

1. [Características](#-características)
2. [Cumplimiento de requerimientos](#-cumplimiento-de-requerimientos)
3. [Capturas de pantalla](#-capturas-de-pantalla)
4. [Arquitectura](#-arquitectura)
5. [Estructura del proyecto](#-estructura-del-proyecto)
6. [Tecnologías y dependencias](#-tecnologías-y-dependencias)
7. [Permisos nativos](#-permisos-nativos)
8. [Instalación y ejecución](#-instalación-y-ejecución)
9. [Pruebas](#-pruebas-automáticas)
10. [Manejo de errores](#-manejo-de-errores)
11. [Historial de commits](#-historial-de-commits)
12. [Problemas frecuentes](#-problemas-frecuentes)
13. [Mejoras futuras](#-mejoras-futuras)

---

## ✨ Características

- **Lista de entradas** con miniatura, fecha, indicador de ubicación, pull-to-refresh y eliminación con confirmación.
- **Detalle de entrada** con imagen a pantalla ancha (animación `Hero`), contenido seleccionable y tarjeta de ubicación.
- **Formulario** para crear o editar entradas, con validación.
- **Cámara y galería** mediante `image_picker`; la imagen se copia al almacenamiento persistente de la app.
- **Dictado por voz** mediante `speech_to_text`; el texto se transcribe en vivo al campo de contenido.
- **Geolocalización** mediante `geolocator`: se captura latitud y longitud al guardar.
- **Google Maps** mediante `url_launcher`: botón para abrir la ubicación guardada.
- **Drawer personalizado** con foto de perfil, header y navegación.
- **Transiciones suaves** (fade y slide) entre pantallas.

---

## ✅ Cumplimiento de requerimientos

| Requerimiento | Implementación | Archivo(s) |
|---|---|---|
| `Scaffold`, `AppBar` con título dinámico | Título con contador de entradas en Home; "Nueva/Editar entrada" en el formulario | `home_screen.dart`, `form_screen.dart` |
| `Drawer` con foto, header y enlaces | `UserAccountsDrawerHeader` + `CircleAvatar` + 3 enlaces | `app_drawer.dart` |
| Rutas nombradas y `Navigator` | `onGenerateRoute` con inyección de dependencias y argumentos tipados | `app_routes.dart`, `main.dart` |
| `HomeScreen`, `DetailScreen`, `FormScreen` | Tres vistas principales más `SettingsScreen` | `views/` |
| Transiciones suaves | `PageRouteBuilder` con `FadeTransition` y `SlideTransition` | `app_routes.dart` |
| `Hero` en la miniatura | Mismo tag (`EntryThumbnail.heroTag`) en lista y detalle | `entry_thumbnail.dart`, `detail_screen.dart` |
| Persistencia con `sqflite` | Tabla `entries` (título, contenido, ruta de imagen, latitud, longitud, fecha) | `database/` |
| `FutureBuilder` en Home | Estados: cargando, error y datos | `home_screen.dart` |
| `try-catch` + `SnackBar` | Todo CRUD y servicio lanza `AppException`; la UI la muestra con `SnackBarHelper` | `utils/`, `database/`, `services/` |
| Cámara y galería | `MediaService` con `image_picker` | `media_service.dart` |
| Dictado por voz | `SpeechService` con `speech_to_text` y botón de micrófono | `speech_service.dart`, `form_screen.dart` |
| Geolocalización al guardar | `LocationService` con `geolocator` | `location_service.dart`, `form_screen.dart` |
| Abrir Google Maps | `MapsLauncherService` con `url_launcher` | `maps_launcher_service.dart`, `detail_screen.dart` |
| Arquitectura por capas | `/models`, `/services`, `/views`, `/widgets`, `/database` | `lib/` |
| SOLID y código documentado | Interfaces, inyección por constructor y comentarios `///` | Todo el proyecto |
| Puntos de commit | Ver [Historial de commits](#-historial-de-commits) | — |

---

## 📸 Capturas de pantalla

> Reemplaza las rutas con tus propias capturas (guárdalas en `docs/screenshots/`).

| Lista | Detalle (Hero) | Formulario |
|:---:|:---:|:---:|
| ![Lista](docs/screenshots/home.png) | ![Detalle](docs/screenshots/detail.png) | ![Formulario](docs/screenshots/form.png) |

| Drawer | Dictado por voz | Google Maps |
|:---:|:---:|:---:|
| ![Drawer](docs/screenshots/drawer.png) | ![Voz](docs/screenshots/voice.png) | ![Mapas](docs/screenshots/maps.png) |

---

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

---

## 📦 Tecnologías y dependencias

| Paquete | Versión | Uso |
|---|---|---|
| `sqflite` | ^2.3.3 | Base de datos SQLite local |
| `path` | ^1.9.0 | Construcción de rutas |
| `path_provider` | ^2.1.4 | Directorio de documentos de la app |
| `image_picker` | ^1.1.2 | Cámara y galería |
| `speech_to_text` | ^7.0.0 | Dictado por voz |
| `geolocator` | ^13.0.1 | Latitud y longitud |
| `url_launcher` | ^6.3.0 | Abrir Google Maps |
| `intl` | ^0.19.0 | Formato de fechas en español |

**Requisitos:** Flutter 3.22 o superior · Android `minSdkVersion 24` · iOS 12 o superior.

---

## 🔐 Permisos nativos

### Android (`AndroidManifest.xml`)

| Permiso | Motivo |
|---|---|
| `CAMERA` | Tomar fotos |
| `RECORD_AUDIO` | Dictado por voz |
| `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` | Registrar la ubicación |
| `INTERNET` | Abrir Google Maps en navegador |
| `BLUETOOTH` / `BLUETOOTH_CONNECT` | Requeridos por `speech_to_text` en Android 12+ |

Además se declaran `<queries>` para el servicio de reconocimiento de voz y para abrir URLs `https` (Android 11+).

### iOS (`Info.plist`)

| Clave | Motivo |
|---|---|
| `NSCameraUsageDescription` | Cámara |
| `NSPhotoLibraryUsageDescription` | Galería |
| `NSMicrophoneUsageDescription` | Micrófono |
| `NSSpeechRecognitionUsageDescription` | Reconocimiento de voz |
| `NSLocationWhenInUseUsageDescription` | Ubicación |
| `LSApplicationQueriesSchemes` | Abrir Google Maps |

---

## 🚀 Instalación y ejecución

### Opción rápida (proyecto en .zip)

El zip incluye el código (`lib/`), `pubspec.yaml`, los recursos y las pruebas. Las carpetas nativas `android/` e `ios/` las genera Flutter, y un script les aplica los permisos y el `minSdk` necesarios.

```bash
# Linux / macOS
bash setup.sh

# Windows
setup.bat
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

---

## 🧪 Pruebas automáticas

```bash
flutter test
```

`test/diary_entry_test.dart` verifica la serialización `toMap`/`fromMap`, `hasLocation` y `copyWith` del modelo.

## 🧪 Guía de pruebas manuales

| Requisito | Qué probar | Resultado esperado |
|---|---|---|
| CRUD | Crear, editar y eliminar entradas | La lista se actualiza al volver |
| `FutureBuilder` | Abrir la app sin datos y con datos; pull-to-refresh | Estados vacío, cargando y lista |
| `Hero` | Tocar una entrada con foto | La miniatura se anima hacia la imagen grande |
| Cámara/galería | Tomar foto, cambiarla, quitarla | La vista previa se actualiza |
| Imágenes huérfanas | Elegir foto y salir sin guardar | El archivo temporal se elimina |
| Voz | Dictar dos veces seguidas | El texto se acumula, no se reemplaza |
| Geolocalización | Guardar con y sin GPS activo | Con GPS guarda coordenadas; sin GPS guarda y avisa |
| Google Maps | Botón en el detalle | Abre la app de Maps o el navegador |
| Permisos | Negar cada permiso | SnackBar con mensaje claro, sin cierres |

---

## 🛡️ Manejo de errores

1. La capa de datos y los servicios capturan cualquier excepción técnica con `try-catch`.
2. La relanzan como `AppException` con un mensaje legible (y la causa original para depuración).
3. Las vistas capturan la excepción y llaman a `SnackBarHelper.showError(context, e)`.

Casos cubiertos: BD inaccesible, permisos denegados (incluido "denegado para siempre"), GPS apagado, tiempo de espera agotado, reconocimiento de voz no disponible, archivo de imagen inexistente y fallo al abrir Google Maps.

---

## 🧾 Historial de commits

Puntos de confirmación sugeridos (usa [Conventional Commits](https://www.conventionalcommits.org/)):

| # | Mensaje | Contenido |
|---|---|---|
| 1 | `chore: estructura de carpetas, dependencias y permisos nativos` | `pubspec.yaml`, manifiestos |
| 2 | `feat(models): DiaryEntry, AppException y SnackBarHelper` | `models/`, `utils/` |
| 3 | `feat(database): DatabaseHelper, DiaryRepository y CRUD con manejo de errores` | `database/` |
| 4 | `feat(services): media, voz, ubicación y lanzador de mapas` | `services/` |
| 5 | `feat(routes): main.dart, named routes con onGenerateRoute y transiciones` | `main.dart`, `routes/` |
| 6 | `feat(widgets): AppDrawer, EntryThumbnail (Hero) y EntryCard` | `widgets/` |
| 7 | `feat(views): HomeScreen con FutureBuilder, pull-to-refresh y eliminación` | `home_screen.dart` |
| 8 | `feat(views): DetailScreen con Hero, ubicación y apertura en Google Maps` | `detail_screen.dart` |
| 9 | `feat(views): FormScreen con cámara, galería, dictado por voz y geolocalización` | `form_screen.dart` |
| 10 | `feat(views): SettingsScreen y cierre de la versión 1.0` | `settings_screen.dart`, README |

---

## 🧰 Problemas frecuentes

| Problema | Solución |
|---|---|
| `minSdkVersion` demasiado bajo | Subir a 24 en `android/app/build.gradle` |
| El dictado no inicia en Android | Verificar que el dispositivo tenga Google Speech Services y el `<queries>` de `RecognitionService` |
| El dictado falla en el emulador | Probar en dispositivo físico |
| `surfaceContainerHighest` no existe | Actualizar Flutter o usar `surfaceVariant` |
| El Drawer no muestra la foto | Verificar `assets/images/profile.png` y la sección `assets:` en `pubspec.yaml` (hay icono de respaldo) |
| Google Maps no abre | Revisar `<queries>` en Android y `LSApplicationQueriesSchemes` en iOS |
| Fechas en inglés | Confirmar que `initializeDateFormatting('es_MX')` se ejecuta antes de `runApp` |

---

## 🔮 Mejoras futuras

- Búsqueda y filtros por fecha o ubicación.
- Varias imágenes por entrada.
- Mapa embebido en el detalle.
- Exportar entradas a PDF.
- Modo oscuro y selector de tema en Configuración.
- Pruebas unitarias del repositorio con un `DiaryRepository` simulado.

---

## 📄 Licencia

Proyecto de uso académico. _Agrega aquí la licencia que prefieras (MIT, etc.)._
