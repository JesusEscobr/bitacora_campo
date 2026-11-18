import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/diary_repository.dart';
import '../models/diary_entry.dart';
import '../routes/app_routes.dart';
import '../services/maps_launcher_service.dart';
import '../services/media_service.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/entry_thumbnail.dart';

/// Vista detallada de una entrada.
///
/// Muestra la imagen con [Hero] (mismo tag que la miniatura de la lista),
/// el contenido, la ubicación y un botón para abrirla en Google Maps.
class DetailScreen extends StatefulWidget {
  final DiaryEntry entry;
  final DiaryRepository repository;
  final MediaService mediaService;
  final MapsLauncherService mapsLauncherService;

  const DetailScreen({
    super.key,
    required this.entry,
    required this.repository,
    required this.mediaService,
    required this.mapsLauncherService,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  /// Copia local de la entrada; se refresca tras editar.
  late DiaryEntry _entry;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
  }

  /// Abre el formulario en modo edición y recarga la entrada al volver.
  Future<void> _edit() async {
    final saved =
        await Navigator.pushNamed(context, AppRoutes.form, arguments: _entry);
    if (saved != true || !mounted) return;

    try {
      final fresh = await widget.repository.getById(_entry.id!);
      if (fresh != null && mounted) setState(() => _entry = fresh);
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, e);
    }
  }

  /// Elimina la entrada y regresa a la lista.
  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar entrada'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.repository.delete(_entry.id!);
      await widget.mediaService.deleteImage(_entry.imagePath);
      if (!mounted) return;
      SnackBarHelper.showInfo(context, 'Entrada eliminada.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, e);
    }
  }

  /// Abre la ubicación guardada en Google Maps.
  Future<void> _openMap() async {
    try {
      await widget.mapsLauncherService
          .openInMaps(_entry.latitude!, _entry.longitude!);
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat("EEEE d 'de' MMMM yyyy, HH:mm", 'es_MX')
        .format(_entry.createdAt);

    return Scaffold(
      appBar: AppBar(
        title: Text(_entry.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _edit,
          ),
          IconButton(
            tooltip: 'Eliminar',
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_entry.imagePath != null) _buildHeroImage(),
            const SizedBox(height: 16),
            Text(_entry.title,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(date,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ),
            const Divider(height: 28),
            SelectableText(
              _entry.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            _buildLocationCard(),
          ],
        ),
      ),
    );
  }

  /// Imagen grande con el mismo tag Hero que la miniatura de la lista.
  Widget _buildHeroImage() {
    return Hero(
      tag: EntryThumbnail.heroTag(_entry.id!),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(_entry.imagePath!),
          width: double.infinity,
          height: 280,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 280,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(
                child: Icon(Icons.broken_image_outlined, size: 48)),
          ),
        ),
      ),
    );
  }

  /// Tarjeta con coordenadas y botón de Google Maps (si hay ubicación).
  Widget _buildLocationCard() {
    if (!_entry.hasLocation) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.location_off_outlined),
          title: Text('Sin ubicación registrada'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.place),
                SizedBox(width: 8),
                Text('Ubicación',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Latitud: ${_entry.latitude!.toStringAsFixed(6)}'),
            Text('Longitud: ${_entry.longitude!.toStringAsFixed(6)}'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openMap,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Abrir en Google Maps'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
