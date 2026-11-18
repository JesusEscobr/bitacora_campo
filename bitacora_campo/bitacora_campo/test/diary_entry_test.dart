import 'package:flutter_test/flutter_test.dart';
import 'package:bitacora_campo/models/diary_entry.dart';

void main() {
  group('DiaryEntry', () {
    final date = DateTime(2026, 11, 16, 10, 30);

    test('toMap y fromMap son inversos', () {
      final entry = DiaryEntry(
        id: 1,
        title: 'Título',
        content: 'Contenido',
        imagePath: '/tmp/foto.jpg',
        latitude: 20.9674,
        longitude: -89.5926,
        createdAt: date,
      );

      final restored = DiaryEntry.fromMap(entry.toMap());

      expect(restored.id, 1);
      expect(restored.title, 'Título');
      expect(restored.content, 'Contenido');
      expect(restored.imagePath, '/tmp/foto.jpg');
      expect(restored.latitude, 20.9674);
      expect(restored.longitude, -89.5926);
      expect(restored.createdAt, date);
    });

    test('hasLocation es false sin coordenadas', () {
      final entry = DiaryEntry(title: 'a', content: 'b', createdAt: date);
      expect(entry.hasLocation, isFalse);
    });

    test('copyWith conserva campos y permite quitar la imagen', () {
      final entry = DiaryEntry(
        id: 2,
        title: 'a',
        content: 'b',
        imagePath: '/tmp/x.jpg',
        createdAt: date,
      );

      expect(entry.copyWith(title: 'nuevo').imagePath, '/tmp/x.jpg');
      expect(entry.copyWith(clearImage: true).imagePath, isNull);
    });
  });
}
