import 'package:flutter/material.dart';

import '../database/diary_repository.dart';
import '../models/diary_entry.dart';
import '../services/location_service.dart';
import '../services/maps_launcher_service.dart';
import '../services/media_service.dart';
import '../services/speech_service.dart';
import '../views/detail_screen.dart';
import '../views/form_screen.dart';
import '../views/home_screen.dart';
import '../views/settings_screen.dart';

/// Nombres de ruta centralizados (evita "magic strings" en la app).
class AppRoutes {
  AppRoutes._();

  static const home = '/';
  static const detail = '/detail';
  static const form = '/form';
  static const settings = '/settings';
}

/// Genera las rutas nombradas e inyecta dependencias a cada pantalla.
///
/// - Las pantallas reciben sus dependencias por constructor (DIP), así no
///   crean servicios por su cuenta y son fáciles de probar.
/// - Los argumentos se pasan con `Navigator.pushNamed(..., arguments: x)`:
///     * [AppRoutes.detail] -> `DiaryEntry` (la entrada a mostrar)
///     * [AppRoutes.form]   -> `DiaryEntry?` (null = crear, valor = editar)
class AppRouter {
  final DiaryRepository repository;
  final MediaService mediaService;
  final SpeechService speechService;
  final LocationService locationService;
  final MapsLauncherService mapsLauncherService;

  const AppRouter({
    required this.repository,
    required this.mediaService,
    required this.speechService,
    required this.locationService,
    required this.mapsLauncherService,
  });

  /// Callback para `MaterialApp.onGenerateRoute`.
  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return _buildRoute(
          settings,
          HomeScreen(repository: repository, mediaService: mediaService),
        );

      case AppRoutes.detail:
        // Se recibe la entrada completa para que el Hero tenga destino
        // inmediato; DetailScreen la refresca desde la BD si se edita.
        final entry = settings.arguments;
        if (entry is! DiaryEntry) {
          return _errorRoute(settings, 'Falta la entrada a mostrar.');
        }
        return _buildRoute(
          settings,
          DetailScreen(
            entry: entry,
            repository: repository,
            mediaService: mediaService,
            mapsLauncherService: mapsLauncherService,
          ),
        );

      case AppRoutes.form:
        final args = settings.arguments;
        if (args != null && args is! DiaryEntry) {
          return _errorRoute(
              settings, 'Argumento inválido para el formulario.');
        }
        return _buildRoute(
          settings,
          FormScreen(
            entry: args as DiaryEntry?, // null => modo creación
            repository: repository,
            mediaService: mediaService,
            speechService: speechService,
            locationService: locationService,
          ),
          slideUp: true, // El formulario "sube" desde abajo.
        );

      case AppRoutes.settings:
        return _buildRoute(settings, const SettingsScreen());

      default:
        return _errorRoute(settings, 'Ruta desconocida: ${settings.name}');
    }
  }

  /// Ruta con transición suave (fade + deslizamiento opcional).
  ///
  /// Se usa PageRouteBuilder porque permite animación personalizada y es
  /// totalmente compatible con [Hero].
  Route<dynamic> _buildRoute(
    RouteSettings settings,
    Widget page, {
    bool slideUp = false,
  }) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final faded = FadeTransition(opacity: curved, child: child);
        if (!slideUp) return faded;
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curved),
          child: faded,
        );
      },
    );
  }

  /// Pantalla de error para rutas o argumentos inválidos.
  Route<dynamic> _errorRoute(RouteSettings settings, String message) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error de navegación')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(message, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
