import '../models/diary_entry.dart';

/// Contrato de acceso a datos del diario.
///
/// Las vistas dependen de esta abstracción y no de sqflite (DIP). Así se
/// podría cambiar el almacenamiento (Hive, API REST) sin tocar la UI, y
/// es fácil de simular (mock) en pruebas.
abstract class DiaryRepository {
  /// Crea una entrada y devuelve el id asignado.
  Future<int> create(DiaryEntry entry);

  /// Devuelve todas las entradas, de la más reciente a la más antigua.
  Future<List<DiaryEntry>> getAll();

  /// Busca una entrada por id; `null` si no existe.
  Future<DiaryEntry?> getById(int id);

  /// Actualiza una entrada existente; devuelve filas afectadas.
  Future<int> update(DiaryEntry entry);

  /// Elimina una entrada por id; devuelve filas afectadas.
  Future<int> delete(int id);
}
