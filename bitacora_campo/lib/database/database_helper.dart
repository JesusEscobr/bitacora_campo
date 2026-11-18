import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../utils/app_exception.dart';

/// Gestiona la conexión a SQLite y el esquema de la base de datos.
///
/// Responsabilidad única: abrir/crear la BD. Las consultas viven en el
/// repositorio. Se implementa como singleton para tener una sola conexión.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const _dbName = 'bitacora_campo.db';
  static const _dbVersion = 1;

  /// Nombre de tabla compartido con el repositorio.
  static const tableEntries = 'entries';

  Database? _database;

  /// Devuelve la BD abierta; la inicializa la primera vez (lazy).
  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await _initDatabase();
      return _database!;
    } catch (e) {
      throw AppException('No se pudo abrir la base de datos.', cause: e);
    }
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      p.join(dbPath, _dbName),
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  /// Crea el esquema inicial.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableEntries (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        title       TEXT NOT NULL,
        content     TEXT NOT NULL,
        image_path  TEXT,
        latitude    REAL,
        longitude   REAL,
        created_at  TEXT NOT NULL
      )
    ''');
  }

  /// Cierra la conexión (útil en pruebas).
  Future<void> close() async {
    try {
      await _database?.close();
      _database = null;
    } catch (e) {
      throw AppException('No se pudo cerrar la base de datos.', cause: e);
    }
  }
}
