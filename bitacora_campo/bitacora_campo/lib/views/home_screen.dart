import 'package:flutter/material.dart';

import '../database/diary_repository.dart';
import '../models/diary_entry.dart';
import '../routes/app_routes.dart';
import '../services/media_service.dart';
import '../utils/app_exception.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/app_drawer.dart';
import '../widgets/entry_card.dart';

/// Pantalla principal: lista de entradas guardadas.
///
/// Usa un [FutureBuilder] para leer la base de datos de forma asíncrona y
/// manejar los tres estados: cargando, error y datos.
class HomeScreen extends StatefulWidget {
  final DiaryRepository repository;
  final MediaService mediaService;

  const HomeScreen({
    super.key,
    required this.repository,
    required this.mediaService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<DiaryEntry>> _entriesFuture;

  /// Total de entradas, usado para el título dinámico del AppBar.
  int? _count;

  /// Evita mostrar el mismo SnackBar de error en cada rebuild.
  bool _errorNotified = false;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _fetch();
  }

  /// Lee las entradas y actualiza el contador del título.
  Future<List<DiaryEntry>> _fetch() async {
    final entries = await widget.repository.getAll();
    if (mounted) setState(() => _count = entries.length);
    return entries;
  }

  /// Vuelve a ejecutar la consulta y reconstruye el FutureBuilder.
  void _reload() {
    setState(() {
      _errorNotified = false;
      _entriesFuture = _fetch();
    });
  }

  /// Abre el detalle y recarga al volver (la entrada pudo editarse/borrarse).
  Future<void> _openDetail(DiaryEntry entry) async {
    await Navigator.pushNamed(context, AppRoutes.detail, arguments: entry);
    if (mounted) _reload();
  }

  /// Abre el formulario en modo creación y recarga al volver.
  Future<void> _openForm() async {
    await Navigator.pushNamed(context, AppRoutes.form);
    if (mounted) _reload();
  }

  /// Pide confirmación y elimina la entrada (registro + imagen local).
  Future<void> _confirmDelete(DiaryEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar entrada'),
        content: Text(
            '¿Eliminar "${entry.title}"? Esta acción no se puede deshacer.'),
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
      await widget.repository.delete(entry.id!);
      await widget.mediaService.deleteImage(entry.imagePath);
      if (mounted) SnackBarHelper.showInfo(context, 'Entrada eliminada.');
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, e);
    }
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Título dinámico según el número de entradas.
        title: Text(_count == null
            ? 'Mi Bitácora'
            : 'Mi Bitácora ($_count ${_count == 1 ? 'entrada' : 'entradas'})'),
      ),
      drawer: AppDrawer(currentRoute: AppRoutes.home, onReturn: _reload),
      body: FutureBuilder<List<DiaryEntry>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          // 1) Cargando
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2) Error
          if (snapshot.hasError) {
            _notifyErrorOnce(snapshot.error!);
            return _ErrorView(
              message: snapshot.error is AppException
                  ? (snapshot.error as AppException).message
                  : 'Ocurrió un error inesperado.',
              onRetry: _reload,
            );
          }

          // 3) Datos
          final entries = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              try {
                await _entriesFuture;
              } catch (_) {/* el error ya se muestra en la vista */}
            },
            child: entries.isEmpty
                ? const _EmptyView()
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 6, bottom: 90),
                    itemCount: entries.length,
                    itemBuilder: (_, i) {
                      final entry = entries[i];
                      return EntryCard(
                        entry: entry,
                        onTap: () => _openDetail(entry),
                        onDelete: () => _confirmDelete(entry),
                      );
                    },
                  ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Nueva entrada'),
      ),
    );
  }

  /// Muestra un SnackBar con el error una sola vez por carga fallida.
  void _notifyErrorOnce(Object error) {
    if (_errorNotified) return;
    _errorNotified = true;
    // No se puede mostrar un SnackBar durante build; se agenda tras el frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) SnackBarHelper.showError(context, error);
    });
  }
}

/// Estado vacío (scrollable para que funcione el pull-to-refresh).
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        const Icon(Icons.menu_book_outlined, size: 72),
        const SizedBox(height: 12),
        const Center(child: Text('Aún no tienes entradas.')),
        const Center(child: Text('Toca "Nueva entrada" para empezar.')),
      ],
    );
  }
}

/// Vista de error con botón de reintento.
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
