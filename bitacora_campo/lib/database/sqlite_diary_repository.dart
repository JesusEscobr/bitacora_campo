import '../models/diary_entry.dart';
import '../utils/app_exception.dart';
import 'database_helper.dart';
import 'diary_repository.dart';

/// Implementación de [DiaryRepository] sobre SQLite (sqflite).
///
/// Cada operación va en un try-catch que traduce cualquier error técnico
/// a una [AppException] legible, para que la UI muestre un SnackBar.
class SqliteDiaryRepository implements DiaryRepository {
  final DatabaseHelper _helper;

  /// Se inyecta el helper (por defecto el singleton) para facilitar pruebas.
  SqliteDiaryRepository({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  @override
  Future<int> create(DiaryEntry entry) async {
    try {
      final db = await _helper.database;
      // Se quita el id para que SQLite lo autogenere.
      final data = entry.toMap()..remove('id');
      return await db.insert(DatabaseHelper.tableEntries, data);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('No se pudo guardar la entrada.', cause: e);
    }
  }

  @override
  Future<List<DiaryEntry>> getAll() async {
    try {
      final db = await _helper.database;
      final rows = await db.query(
        DatabaseHelper.tableEntries,
        orderBy: 'created_at DESC',
      );
      return rows.map(DiaryEntry.fromMap).toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('No se pudieron cargar las entradas.', cause: e);
    }
  }

  @override
  Future<DiaryEntry?> getById(int id) async {
    try {
      final db = await _helper.database;
      final rows = await db.query(
        DatabaseHelper.tableEntries,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return rows.isEmpty ? null : DiaryEntry.fromMap(rows.first);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('No se pudo leer la entrada.', cause: e);
    }
  }

  @override
  Future<int> update(DiaryEntry entry) async {
    if (entry.id == null) {
      throw const AppException(
          'La entrada no tiene id; no se puede actualizar.');
    }
    try {
      final db = await _helper.database;
      return await db.update(
        DatabaseHelper.tableEntries,
        entry.toMap(),
        where: 'id = ?',
        whereArgs: [entry.id],
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('No se pudo actualizar la entrada.', cause: e);
    }
  }

  @override
  Future<int> delete(int id) async {
    try {
      final db = await _helper.database;
      return await db.delete(
        DatabaseHelper.tableEntries,
        where: 'id = ?',
        whereArgs: [id],
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('No se pudo eliminar la entrada.', cause: e);
    }
  }
}
