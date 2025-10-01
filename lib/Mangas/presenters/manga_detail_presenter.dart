import 'package:yomuyomu/Mangas/contracts/manga_detail_contract.dart';
import 'package:yomuyomu/DataBase/database_helper.dart';
import 'package:yomuyomu/Mangas/models/chapter_model.dart';
import 'package:yomuyomu/Mangas/models/manga_model.dart';
import 'package:yomuyomu/Mangas/models/panel_model.dart';

class MangaDetailPresenter {
  final MangaDetailViewContract _view;
  MangaModel? _manga;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  MangaDetailPresenter(this._view);
  Future<void> loadMangaDetail(String mangaID) async {
    try {
      final mangaData = await _databaseHelper.getMangaById(mangaID);
      if (mangaData == null) {
        _view.showError("Manga no encontrado");
        return;
      }

      final manga = MangaModel.fromMap(mangaData);
      final chapters = await _loadChapters(mangaID);
      _manga = manga;
      manga.chapters = chapters;

      _view.showManga(manga);
      _view.showChapters(manga.chapters ?? []);
    } catch (e) {
      _view.showError("Error al cargar el manga: $e");
    }
  }

  Future<List<Chapter>> _loadChapters(String mangaID) async {
    try {
      final chaptersData = await _databaseHelper.getChaptersByMangaId(mangaID);

      final List<Chapter> chapters = [];

      for (final chapterData in chaptersData) {
        final chapter = Chapter.fromMap(chapterData);
        final panelsData = await _databaseHelper.getPanelsByChapterId(
          chapter.id,
        );
        chapter.panels =
            panelsData.map((panelData) => Panel.fromMap(panelData)).toList();
        chapters.add(chapter);
      }

      return chapters;
    } catch (e) {
      _view.showError("Error al cargar los capítulos: $e");
      return [];
    }
  }

  void searchChapter(String query) {
    final chapters = _manga?.chapters;
    if (chapters == null || chapters.isEmpty) {
      _view.showChapters([]);
      return;
    }

    final results =
        chapters
            .where(
              (c) =>
                  c.title?.toLowerCase().contains(query.toLowerCase()) ?? false,
            )
            .toList();

    _view.showChapters(results);
  }

  void sortChaptersByTitle({required bool ascending}) {
  final chapters = _manga?.chapters;
  if (chapters == null || chapters.isEmpty) return;

  chapters.sort((a, b) {
    final aTitle = a.title ?? '';
    final bTitle = b.title ?? '';
    return ascending ? aTitle.compareTo(bTitle) : bTitle.compareTo(aTitle);
  });

  _view.showChapters(List<Chapter>.from(chapters));
}
}
