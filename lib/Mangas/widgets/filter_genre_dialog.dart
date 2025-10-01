import 'package:flutter/material.dart';
import 'package:yomuyomu/Mangas/models/genre_model.dart';

class GenreFilterDialog extends StatefulWidget {
  final Map<GenreModel, bool> genreFilterStatus;
  final Function(List<String>)  onFilterApplied;

  const GenreFilterDialog({required this.genreFilterStatus, required this.onFilterApplied, super.key});

  @override
  GenreFilterDialogState createState() => GenreFilterDialogState();
}

class GenreFilterDialogState extends State<GenreFilterDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Filter by Genre"),
      content: SingleChildScrollView(
        child: Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: widget.genreFilterStatus.keys.map((genre) {
            final isSelected = widget.genreFilterStatus[genre]!;
            return FilterChip(
              label: Text(genre.description),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  widget.genreFilterStatus[genre] = selected;
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            final selectedGenreIds = widget.genreFilterStatus.entries.where((e) => e.value).map((e) => e.key.genreId).toList();
            widget.onFilterApplied(selectedGenreIds);
            Navigator.pop(context);
          },
          child: const Text("Accept"),
        ),
      ],
    );
  }
}
