import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/diary_entry.dart';
import 'entry_thumbnail.dart';

/// Tarjeta de una entrada en la lista de `HomeScreen`.
///
/// Solo presenta datos y delega las acciones mediante callbacks, así no
/// conoce la navegación ni la base de datos (responsabilidad única).
class EntryCard extends StatelessWidget {
  final DiaryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const EntryCard({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final date =
        DateFormat('dd MMM yyyy, HH:mm', 'es_MX').format(entry.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(10),
        // Las entradas guardadas siempre tienen id; se usa para el tag Hero.
        leading: EntryThumbnail(entryId: entry.id!, imagePath: entry.imagePath),
        title: Text(
          entry.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.content, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule, size: 14),
                const SizedBox(width: 4),
                Text(date, style: Theme.of(context).textTheme.bodySmall),
                if (entry.hasLocation) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.place, size: 14),
                ],
              ],
            ),
          ],
        ),
        trailing: IconButton(
          tooltip: 'Eliminar',
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
