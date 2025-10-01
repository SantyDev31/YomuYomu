import 'package:flutter/material.dart';
import 'package:yomuyomu/DataBase/database_helper.dart';
import 'package:yomuyomu/Mangas/models/manga_model.dart';
import 'package:yomuyomu/Mangas/models/genre_model.dart';

class GenresTab extends StatefulWidget {
  final MangaModel manga;
  final VoidCallback? onGenresUpdated;

  const GenresTab({super.key, required this.manga, this.onGenresUpdated});

  @override
  State<GenresTab> createState() => _GenresTabState();
}

class _GenresTabState extends State<GenresTab> {
  final _db = DatabaseHelper.instance;
  List<GenreModel> allGenres = [];
  Set<String> selectedGenreIds = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final genresFromDb = await _db.getAllGenres();
    final selectedIds = await _db.getGenreIdsForManga(widget.manga.id);

    setState(() {
      allGenres = genresFromDb;
      selectedGenreIds = Set<String>.from(selectedIds);
    });
  } 

  Future<void> _saveGenres() async {
    await _db.updateMangaGenres(widget.manga.id, selectedGenreIds.toList());

    if (widget.onGenresUpdated != null) {
      widget.onGenresUpdated!();
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (allGenres.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Choose the genres:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allGenres.map((genre) {
                  final isSelected = selectedGenreIds.contains(genre.genreId);
                  return FilterChip(
                    label: Text(genre.description),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedGenreIds.add(genre.genreId);
                        } else {
                          selectedGenreIds.remove(genre.genreId);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveGenres,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
