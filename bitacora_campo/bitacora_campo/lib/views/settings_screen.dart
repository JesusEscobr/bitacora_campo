import 'package:flutter/material.dart';

/// Pantalla de configuración: información de la app y de los permisos.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        children: const [
          _SectionHeader('Permisos utilizados'),
          ListTile(
            leading: Icon(Icons.photo_camera_outlined),
            title: Text('Cámara y galería'),
            subtitle: Text('Para adjuntar una imagen a cada entrada.'),
          ),
          ListTile(
            leading: Icon(Icons.mic_none),
            title: Text('Micrófono y reconocimiento de voz'),
            subtitle: Text('Para dictar el contenido de la entrada.'),
          ),
          ListTile(
            leading: Icon(Icons.place_outlined),
            title: Text('Ubicación'),
            subtitle: Text('Para registrar dónde se creó la entrada.'),
          ),
          Divider(),
          _SectionHeader('Almacenamiento'),
          ListTile(
            leading: Icon(Icons.storage_outlined),
            title: Text('Datos locales'),
            subtitle: Text(
              'Tus entradas se guardan solo en este dispositivo (SQLite).',
            ),
          ),
          Divider(),
          _SectionHeader('Acerca de'),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Bitácora de Campo'),
            subtitle: Text('Versión 1.0.0'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
