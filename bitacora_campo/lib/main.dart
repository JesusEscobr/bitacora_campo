import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'database/sqlite_diary_repository.dart';
import 'routes/app_routes.dart';
import 'services/location_service.dart';
import 'services/maps_launcher_service.dart';
import 'services/media_service.dart';
import 'services/speech_service.dart';

/// Punto de entrada de la aplicación.
///
/// Aquí se ensamblan las dependencias (composition root): es el único
/// lugar que conoce las implementaciones concretas.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga los datos de formato de fecha en español (intl).
  await initializeDateFormatting('es_MX');

  final router = AppRouter(
    repository: SqliteDiaryRepository(),
    mediaService: MediaService(),
    speechService: SpeechService(),
    locationService: LocationService(),
    mapsLauncherService: MapsLauncherService(),
  );

  runApp(BitacoraApp(router: router));
}

/// Widget raíz: tema y navegación por rutas nombradas.
class BitacoraApp extends StatelessWidget {
  final AppRouter router;

  const BitacoraApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bitácora de Campo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      initialRoute: AppRoutes.home,
      onGenerateRoute: router.onGenerateRoute,
    );
  }
}
