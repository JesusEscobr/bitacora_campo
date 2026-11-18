import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../database/diary_repository.dart';
import '../models/diary_entry.dart';
import '../services/location_service.dart';
import '../services/media_service.dart';
import '../services/speech_service.dart';
import '../utils/app_exception.dart';
import '../utils/snackbar_helper.dart';

/// Acciones del selector de imagen.
enum _ImageAction { camera, gallery, remove }

/// Formulario para crear (entry == null) o editar una entrada.
///
/// Integra cámara/galería, dictado por voz y captura de ubicación al guardar.
class FormScreen extends StatefulWidget {
  final DiaryEntry? entry;
  final DiaryRepository repository;
  final MediaService mediaService;
  final SpeechService speechService;
  final LocationService locationService;

  const FormScreen({
    super.key,
    this.entry,
    required this.repository,
    required this.mediaService,
    required this.speechService,
    required this.locationService,
  });

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;

  String? _imagePath;
  bool _isListening = false;
  bool _isSaving = false;
  bool _saved = false; // Evita borrar la imagen si ya se guardó.

  /// Texto que ya existía antes de empezar a dictar (el dictado se añade).
  String _textBeforeDictation = '';

  bool get _isEditing => widget.entry != null;
  String? get _originalImagePath => widget.entry?.imagePath;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.entry?.title ?? '');
    _contentCtrl = TextEditingController(text: widget.entry?.content ?? '');
    _imagePath = widget.entry?.imagePath;
  }

  @override
  void dispose() {
    // Si el usuario sale sin guardar, se borra la imagen nueva (huérfana).
    if (!_saved && _imagePath != _originalImagePath) {
      widget.mediaService.deleteImage(_imagePath).catchError((_) {});
    }
    widget.speechService.cancel().catchError((_) {});
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Imagen (cámara / galería)
  // ---------------------------------------------------------------------

  /// Muestra el selector de origen de la imagen.
  Future<void> _showImageSheet() async {
    final action = await showModalBottomSheet<_ImageAction>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(ctx, _ImageAction.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(ctx, _ImageAction.gallery),
            ),
            if (_imagePath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Quitar imagen'),
                onTap: () => Navigator.pop(ctx, _ImageAction.remove),
              ),
          ],
        ),
      ),
    );

    switch (action) {
      case _ImageAction.camera:
        await _pickImage(ImageSource.camera);
      case _ImageAction.gallery:
        await _pickImage(ImageSource.gallery);
      case _ImageAction.remove:
        await _discardTemporaryImage();
        if (mounted) setState(() => _imagePath = null);
      case null:
        break; // Cerró el selector sin elegir.
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final path = await widget.mediaService.pickImage(source);
      if (path == null || !mounted) return;
      await _discardTemporaryImage(); // Libera una imagen nueva previa.
      setState(() => _imagePath = path);
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, e);
    }
  }

  /// Borra la imagen actual solo si es nueva (no la original guardada).
  Future<void> _discardTemporaryImage() async {
    if (_imagePath != null && _imagePath != _originalImagePath) {
      try {
        await widget.mediaService.deleteImage(_imagePath);
      } catch (_) {/* limpieza best-effort */}
    }
  }

  // ---------------------------------------------------------------------
  // Dictado por voz
  // ---------------------------------------------------------------------

  Future<void> _toggleDictation() async {
    try {
      if (_isListening) {
        await widget.speechService.stop();
        if (mounted) setState(() => _isListening = false);
        return;
      }

      _textBeforeDictation = _contentCtrl.text.trim();
      setState(() => _isListening = true);

      await widget.speechService.start(
        onResult: _onSpeechResult,
        onError: _onSpeechError,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isListening = false);
      SnackBarHelper.showError(context, e);
    }
  }

  /// Transcribe en vivo al campo de contenido.
  void _onSpeechResult(String words, bool isFinal) {
    if (!mounted) return;
    final base = _textBeforeDictation;
    final text = base.isEmpty ? words : '$base $words';
    setState(() {
      _contentCtrl.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      if (isFinal) _isListening = false;
    });
  }

  void _onSpeechError(String message) {
    if (!mounted) return;
    setState(() => _isListening = false);
    // "no_match" y "timeout" son normales (el usuario no dijo nada).
    if (message.contains('no_match') || message.contains('timeout')) return;
    SnackBarHelper.showError(
        context, AppException('Error de dictado: $message'));
  }

  // ---------------------------------------------------------------------
  // Guardado
  // ---------------------------------------------------------------------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    if (_isListening) {
      try {
        await widget.speechService.cancel();
      } catch (_) {}
      if (mounted) setState(() => _isListening = false);
    }

    setState(() => _isSaving = true);
    String? locationWarning;

    try {
      // Se conserva la ubicación original al editar; si no hay, se captura.
      double? lat = widget.entry?.latitude;
      double? lng = widget.entry?.longitude;
      if (lat == null || lng == null) {
        try {
          final position = await widget.locationService.getCurrentPosition();
          lat = position.latitude;
          lng = position.longitude;
        } catch (e) {
          // La entrada se guarda igual, pero se avisa al usuario.
          locationWarning = e is AppException
              ? e.message
              : 'No se pudo obtener la ubicación.';
        }
      }

      final entry = DiaryEntry(
        id: widget.entry?.id,
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        imagePath: _imagePath,
        latitude: lat,
        longitude: lng,
        createdAt: widget.entry?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await widget.repository.update(entry);
      } else {
        await widget.repository.create(entry);
      }
      _saved = true;

      // Si se reemplazó o quitó la imagen original, se borra el archivo viejo.
      if (_originalImagePath != null && _originalImagePath != _imagePath) {
        try {
          await widget.mediaService.deleteImage(_originalImagePath);
        } catch (_) {/* no debe romper el guardado */}
      }

      if (!mounted) return;
      SnackBarHelper.showInfo(
        context,
        locationWarning == null
            ? 'Entrada guardada.'
            : 'Entrada guardada sin ubicación: $locationWarning',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, e);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Título dinámico según el modo.
        title: Text(_isEditing ? 'Editar entrada' : 'Nueva entrada'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildImagePicker(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Escribe un título.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentCtrl,
              minLines: 6,
              maxLines: 12,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Contenido',
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
                helperText: _isListening ? 'Escuchando… habla ahora' : null,
                // Botón de micrófono para dictar.
                suffixIcon: IconButton(
                  tooltip: _isListening ? 'Detener dictado' : 'Dictar por voz',
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  color: _isListening ? Colors.red : null,
                  onPressed: _toggleDictation,
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Escribe o dicta el contenido.'
                  : null,
            ),
            const SizedBox(height: 12),
            if (!_isEditing || !(widget.entry?.hasLocation ?? false))
              const Row(
                children: [
                  Icon(Icons.place_outlined, size: 18),
                  SizedBox(width: 6),
                  Expanded(
                    child:
                        Text('Al guardar se registrará tu ubicación actual.'),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isSaving ? 'Guardando…' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  /// Vista previa de la imagen (o botón para agregarla).
  Widget _buildImagePicker() {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _showImageSheet,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: _imagePath == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 44),
                  SizedBox(height: 8),
                  Text('Agregar foto (cámara o galería)'),
                ],
              )
            : Image.file(
                File(_imagePath!),
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_outlined, size: 44)),
              ),
      ),
    );
  }
}
