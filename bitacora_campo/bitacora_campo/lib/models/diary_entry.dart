/// Modelo de dominio de una entrada del diario.
///
/// Es inmutable; para modificarlo se usa [copyWith]. Conoce su propia
/// (de)serialización hacia/desde el `Map` que usa sqflite.
class DiaryEntry {
  final int? id; // null mientras no se ha guardado en la BD.
  final String title;
  final String content;
  final String? imagePath; // Ruta local de la imagen (opcional).
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  const DiaryEntry({
    this.id,
    required this.title,
    required this.content,
    this.imagePath,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  /// Indica si la entrada tiene coordenadas válidas.
  bool get hasLocation => latitude != null && longitude != null;

  /// Convierte la entrada a un mapa para insertarla en SQLite.
  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'image_path': imagePath,
        'latitude': latitude,
        'longitude': longitude,
        'created_at': createdAt.toIso8601String(),
      };

  /// Construye una entrada a partir de una fila de SQLite.
  factory DiaryEntry.fromMap(Map<String, Object?> map) => DiaryEntry(
        id: map['id'] as int?,
        title: map['title'] as String,
        content: map['content'] as String,
        imagePath: map['image_path'] as String?,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  /// Copia la entrada cambiando solo los campos indicados.
  ///
  /// Para dejar un campo opcional en `null` usa los flags `clear*`.
  DiaryEntry copyWith({
    int? id,
    String? title,
    String? content,
    String? imagePath,
    bool clearImage = false,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
  }) =>
      DiaryEntry(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        imagePath: clearImage ? null : (imagePath ?? this.imagePath),
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        createdAt: createdAt ?? this.createdAt,
      );
}
