import 'package:flutter/material.dart';
import 'package:yomuyomu/Mangas/models/manga_model.dart';

class DeleteTab extends StatelessWidget {
  final MangaModel manga;
  final VoidCallback onDeleteConfirmed;

  const DeleteTab({
    super.key,
    required this.manga,
    required this.onDeleteConfirmed,
  });

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm delete'),
        content: Text("Are you sure you want to delete ${manga.title}? This action can't be undone"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onDeleteConfirmed(); 
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Manga deleted: ${manga.title}')),
              );
            },
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'Delete "${manga.title}"?',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showConfirmationDialog(context),
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete manga'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
