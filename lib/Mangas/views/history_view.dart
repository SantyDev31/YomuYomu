import 'dart:io';
import 'package:flutter/material.dart';
import 'package:yomuyomu/Mangas/enums/reading_status.dart';
import 'package:yomuyomu/DataBase/database_helper.dart';
import 'package:yomuyomu/Mangas/models/author_model.dart';
import 'package:yomuyomu/Mangas/models/genre_model.dart';
import 'package:yomuyomu/Mangas/models/manga_model.dart';
import 'package:yomuyomu/Mangas/contracts/library_contract.dart';
import 'package:yomuyomu/Mangas/presenters/library_presenter.dart';
import 'package:yomuyomu/Mangas/views/manga_detail_view.dart';
import 'package:yomuyomu/Mangas/widgets/filter_genre_dialog.dart';
import 'package:yomuyomu/Mangas/widgets/filter_status_dialog.dart';
import 'package:yomuyomu/Mangas/widgets/manga_options_dialog.dart';
import 'package:yomuyomu/Mangas/widgets/sort_dialog.dart';

Map<ReadingStatus, bool> filterStatus = {
  for (var status in ReadingStatus.values) status: false,
};

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView>
    implements LibraryViewContract {
  late final LibraryPresenter libraryPresenter;
  late final TextEditingController searchController;

  List<MangaModel> mangas = [];
  Map<String, Author> authors = {};
  List<GenreModel> genreList = [];
  Map<GenreModel, bool> genreFilterStatus = {};

  @override
  void initState() {
    super.initState();
    libraryPresenter = LibraryPresenter(this);
    searchController = TextEditingController();
    libraryPresenter.loadMangas();
      libraryPresenter.sortBy(3);
    _loadGenresAndMangas();
  }

  Future<void> _loadGenresAndMangas() async {
    final db = DatabaseHelper.instance;
    final genres = await db.getAllGenres();
    setState(() {
      genreList = genres;
      genreFilterStatus = {for (var genre in genres) genre: false};
    });
  }

  @override
  void updateMangaList(List<MangaModel> updatedMangas) {
    setState(() {
      mangas = updatedMangas;
    });
  }

  @override
  void updateAuthorList(Map<String, Author> authorMap) {
    setState(() {
      authors = authorMap;
    });
  }

  @override
  void showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showFilterStatusDialog() {
    showDialog(
      context: context,
      builder:
          (context) => FilterStatusDialog(
            filterStatus: filterStatus,
            onFilterApplied: (selectedStatus) {
              selectedStatus.isEmpty
                  ? libraryPresenter.showAll()
                  : libraryPresenter.filterByStatus(selectedStatus);
            },
          ),
    );
  }

  void _showGenreFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => GenreFilterDialog(
            genreFilterStatus: genreFilterStatus,
            onFilterApplied: (selectedGenres) {
              selectedGenres.isEmpty
                  ? libraryPresenter.showAll()
                  : libraryPresenter.filterByGenres(selectedGenres);
            },
          ),
    );
  }

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SortDialog(
            onSortSelected: (sortType) => libraryPresenter.sortBy(sortType),
          ),
    );
  }

  void _showMangaOptionsPopup(MangaModel manga) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder:
          (context) => MangaOptionsDialog(
            manga: manga,
            onStatusChanged: (status) {
              manga.status = status;
              libraryPresenter.updateMangaStatus(manga.id, status);
            },
            onGenresUpdated: () => libraryPresenter.loadMangas(),
            onDeleteConfirmed: () => libraryPresenter.deleteManga(manga.id),
          ),
    );
  }

  void _openMangaDetail(MangaModel selectedManga) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MangaDetailView(manga: selectedManga)),
    );
  }

  void _onSearchChanged(String query) {
    libraryPresenter.filterMangasByTitle(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Library"),
        actions: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SizedBox(
                width: 200,
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'status') _showFilterStatusDialog();
              if (value == 'genre') _showGenreFilterDialog();
              if (value == 'sort') _showSortDialog();
            },
            icon: const Icon(Icons.more_vert),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'status',
                    child: Text('Filter by Status'),
                  ),
                  const PopupMenuItem(
                    value: 'genre',
                    child: Text('Filter by Genre'),
                  ),
                  const PopupMenuItem(value: 'sort', child: Text('Sort')),
                ],
          ),
        ],
      ),
      body: _buildMangaList(),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () async => await libraryPresenter.importCBZFile(isVolume: true),
        tooltip: "Import CBZ Manga",
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMangaList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        return isWide
            ? GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.8,
              ),
              padding: const EdgeInsets.all(12),
              itemCount: mangas.length,
              itemBuilder: (_, index) => _buildMangaCard(mangas[index]),
            )
            : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: mangas.length,
              itemBuilder: (_, index) => _buildMangaCard(mangas[index]),
            );
      },
    );
  }

  Widget _buildMangaCard(MangaModel manga) {
    final genreDescriptions = manga.genres
        .map(
          (id) => genreList.firstWhere(
            (genre) => genre.genreId == id,
            orElse: () => GenreModel(genreId: id, description: id),
          ),
        )
        .map((g) => g.description)
        .take(3)
        .join(" • ");
    final authorName = authors[manga.authorId]?.name ?? manga.authorId;
    final lastRead =
        manga.lastReadDate != null ? (manga.lastReadDate) : "Unknown";

    return GestureDetector(
      onTap: () => _openMangaDetail(manga),
      onLongPress: () => _showMangaOptionsPopup(manga),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    manga.coverUrl != null
                        ? Image.file(
                          File(manga.coverUrl!),
                          width: 80,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) =>
                                  const Icon(Icons.broken_image, size: 48),
                        )
                        : const Icon(Icons.book, size: 64),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manga.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      authorName,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      genreDescriptions,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.menu_book, size: 16),
                        const SizedBox(width: 4),
                        Text("Ch: ${manga.totalChaptersAmount}"),
                        const SizedBox(width: 16),
                        const Icon(Icons.auto_stories, size: 16),
                        const SizedBox(width: 4),
                        Text("Pg: ${manga.lastChapterRead}"),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Last read: $lastRead",
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  manga.isFavorited ? Icons.star : Icons.star_border,
                  color: manga.isFavorited ? Colors.amber : Colors.grey,
                ),
                onPressed: () async {
                  await libraryPresenter.toggleFavoriteStatus(manga);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void showLoading() {}

  @override
  void hideLoading() {}
}
