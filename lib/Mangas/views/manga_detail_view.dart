import 'dart:io';

import 'package:flutter/material.dart';
import 'package:yomuyomu/Mangas/contracts/manga_detail_contract.dart';
import 'package:yomuyomu/Mangas/models/chapter_model.dart';
import 'package:yomuyomu/Mangas/models/manga_model.dart';
import 'package:yomuyomu/Mangas/presenters/manga_detail_presenter.dart';
import 'package:yomuyomu/Mangas/views/manga_viewer_view.dart';

class MangaDetailView extends StatefulWidget {
  final MangaModel manga;
  const MangaDetailView({super.key, required this.manga});

  @override
  State<MangaDetailView> createState() => _MangaDetailViewState();
}

class _MangaDetailViewState extends State<MangaDetailView>
    implements MangaDetailViewContract {
  late final MangaDetailPresenter _presenter;
  final TextEditingController _searchController = TextEditingController();

  bool _sortTitleAsc = true;

  MangaModel? _currentManga;
  List<Chapter> _availableChapters = [];

  @override
  void initState() {
    super.initState();
    _presenter = MangaDetailPresenter(this);
    _searchController.addListener(_onSearchChanged);
    _presenter.loadMangaDetail(widget.manga.id);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _presenter.loadMangaDetail(widget.manga.id);
    } else {
      _presenter.searchChapter(query);
    }
  }

  void _onChapterSelected(Chapter chapter) {
    _presenter.sortChaptersByTitle(ascending: true);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => MangaViewer(
              chapters: _availableChapters,
              initialChapter: chapter,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _currentManga == null
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 220.0,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(_currentManga!.title),
                      background: _buildCoverImage(),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildSynopsis()),
                  SliverToBoxAdapter(child: _buildChapterSection()),
                  SliverToBoxAdapter(child: _buildChapterSearchField()),
                  _buildChapterList(),
                ],
              ),
    );
  }

  Widget _buildCoverImage() {
    final coverUrl = _currentManga?.coverUrl;
    return coverUrl != null && File(coverUrl).existsSync()
        ? Image.file(File(coverUrl), fit: BoxFit.cover, width: double.infinity)
        : Image.asset(
          'assets/images/placeholder.jpg',
          fit: BoxFit.cover,
          width: double.infinity,
        );
  }

  Widget _buildSynopsis() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        _currentManga?.synopsis ?? 'No synopsis available.',
        style: const TextStyle(fontSize: 15.0, height: 1.5),
      ),
    );
  }

  Widget _buildChapterSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            "Chapters",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: Icon(
            _sortTitleAsc ? Icons.sort_by_alpha : Icons.sort_by_alpha_outlined,
          ),
          tooltip: "Sort by chapter (${_sortTitleAsc ? 'A-Z' : 'Z-A'})",
          onPressed: () {
            setState(() {
              _sortTitleAsc = !_sortTitleAsc;
              _presenter.sortChaptersByTitle(ascending: _sortTitleAsc);
            });
          },
        ),
      ],
    );
  }

  Widget _buildChapterSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: "Find Chapter",
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.search),
        ),
      ),
    );
  }

  Widget _buildChapterList() {
    if (_availableChapters.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text("No chapters found.")),
        ),
      );
    }

    return SliverList.separated(
      itemCount: _availableChapters.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final chapter = _availableChapters[index];
        final cover = chapter.coverUrl;

        return ListTile(
          leading:
              cover != null && File(cover).existsSync()
                  ? Image.file(
                    File(cover),
                    width: 50,
                    height: 70,
                    fit: BoxFit.cover,
                  )
                  : Image.asset(
                    'assets/images/placeholder.jpg',
                    width: 50,
                    height: 70,
                  ),
          title: Text(chapter.title ?? 'No Title'),
          subtitle: Text(
            "Published: ${chapter.publicationDate?.toLocal().toIso8601String().split('T').first ?? 'Unknown'}",
          ),
          onTap: () => _onChapterSelected(chapter),
        );
      },
    );
  }

  @override
  void showManga(MangaModel manga) {
    setState(() {
      _currentManga = manga;
    });
  }

  @override
  void showChapters(List<Chapter> chapters) {
    setState(() {
      _availableChapters = chapters;
    });
  }

  @override
  void showError(String message) {}

  @override
  void hideLoading() {}

  @override
  void showLoading() {}
}
