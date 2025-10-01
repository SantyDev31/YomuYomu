import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yomuyomu/Mangas/contracts/library_contract.dart';
import 'package:yomuyomu/Mangas/enums/reading_status.dart';
import 'package:yomuyomu/Mangas/helpers/event_bus_helpder.dart';
import 'package:yomuyomu/Mangas/models/author_model.dart';
import 'package:yomuyomu/Mangas/models/chapter_model.dart';
import 'package:yomuyomu/Mangas/models/manga_model.dart';
import 'package:yomuyomu/DataBase/database_helper.dart';
import 'package:yomuyomu/Mangas/models/panel_model.dart';
import 'package:yomuyomu/Mangas/models/usernote_model.dart';
import 'package:yomuyomu/Settings/global_settings.dart';

class LibraryPresenter implements LibraryPresenterContract {
  final LibraryViewContract view;
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<MangaModel> _allMangas = [];
  List<MangaModel> _filtered = [];
  List<Author> _allAuthor = [];

  StreamSubscription<String>? _eventSub;

  LibraryPresenter(this.view) {
    startListeningEvents();
  }

  @override
  Future<void> loadMangas() async {
    try {
      view.showLoading();

      final mangaData = await _db.getAllMangas();

      _allMangas = await Future.wait(
        mangaData.map((map) async {
          final mangaId = map['MangaID'] as String;

          final genresFuture = _db.getGenreIdsForManga(mangaId);
          final userNoteFuture = _db.getUserNoteForManga(userId, mangaId);
          final lastReadChapterFuture = _db.getLastReadChapterWithDate(
            userId,
            mangaId,
          );

          final genres = await genresFuture;
          final userNote = await userNoteFuture;
          final lastReadChapter = await lastReadChapterFuture;

          if (lastReadChapter != null) {
            return MangaModel.fromMap(
              map,
              lastReadDate: DateTime.fromMillisecondsSinceEpoch(
                lastReadChapter.lastReadDate,
              ),
              lastChapterRead: lastReadChapter.chapterNumber,
              genres: genres.toList(),
              status: userNote?.readingStatus,
              isFavorited: userNote?.isFavorited ?? false,
              rating: userNote?.personalRating ?? 0,
            );
          }
          return MangaModel.fromMap(
            map,
            genres: genres.toList(),
            status: userNote?.readingStatus,
            isFavorited: userNote?.isFavorited ?? false,
            rating: userNote?.personalRating ?? 0,
          );
        }),
      );

      _filtered = _allMangas;
      _allAuthor = (await _db.getAllAuthors()).map(Author.fromMap).toList();

      view.updateMangaList(_allMangas);
      view.updateAuthorList({for (var a in _allAuthor) a.authorId: a});
    } catch (e) {
      view.showError("Error al cargar biblioteca: $e");
    } finally {
      view.hideLoading();
    }
  }

  @override
  void filterByStatus(List<ReadingStatus> statusList) {
    _filtered = _allMangas.where((m) => statusList.contains(m.status)).toList();
    view.updateMangaList(_filtered);
  }

  @override
  void filterByIsFavorited() {
    _filtered = _allMangas.where((m) => m.isFavorited).toList();
    view.updateMangaList(_filtered);
  }

  @override
  void filterByGenres(List<String> genres) {
    _filtered = _allMangas.where((m) => m.genres.any(genres.contains)).toList();
    view.updateMangaList(_filtered);
  }

  void filterMangasByTitle(String query) {
    final lower = query.toLowerCase();
    _filtered =
        _allMangas
            .where(
              (m) =>
                  m.title.toLowerCase().contains(lower) ||
                  m.authorId.toLowerCase().contains(lower),
            )
            .toList();

    view.updateMangaList(_filtered.isEmpty ? _allMangas : _filtered);
  }

  @override
  void sortBy(int criteria) {
    final source = _filtered.isNotEmpty ? _filtered : _allMangas;
    List<MangaModel> sorted = [...source];

    switch (criteria) {
      case 0:
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 1:
        sorted.sort(
          (a, b) => b.totalChaptersAmount.compareTo(a.totalChaptersAmount),
        );
        break;
      case 2:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 3:
        sorted.sort((a,b) => b.lastReadDate!.compareTo(a.lastReadDate!));
        break;
    }

    view.updateMangaList(sorted);
  }

  void showAll() {
    _filtered = _allMangas;
    view.updateMangaList(_filtered);
  }

  Future<void> updateMangaStatus(String mangaId, ReadingStatus status) async {
    await _db.updateMangaStatus(
      userId: userId,
      mangaId: mangaId,
      readingStatus: status.value,
    );
    await loadMangas();
  }

  Future<void> toggleFavoriteStatus(MangaModel manga) async {
    final newStatus = !manga.isFavorited;

    // Actualizar en la base de datos
    final existingNote = await _db.getUserNote(userId, manga.id);

    final note = UserNote(
      userId: userId,
      mangaId: manga.id,
      isFavorited: newStatus,
      readingStatus: existingNote?.readingStatus ?? ReadingStatus.toRead,
      personalComment: existingNote?.personalComment,
      personalRating: existingNote?.personalRating,
      lastEdited: DateTime.now(),
    );

    await _db.insertOrUpdateUserNote(note);

    manga.isFavorited = newStatus;
    view.updateMangaList(_filtered);
  }

  Future<void> deleteManga(String mangaId) async {
    try {
      view.showLoading();

      final chapters = await _db.getChaptersByMangaId(mangaId);
      for (var chapter in chapters) {
        final chapterId = chapter['ChapterID'];
        await _db.deletePanelsByChapterId(chapterId);
        await _db.deleteChapter(chapterId);
      }

      await _db.deleteManga(mangaId);
      await _deleteCBZFiles(mangaId);
      await loadMangas();
    } catch (e) {
      view.showError("Error al eliminar manga: $e");
    } finally {
      view.hideLoading();
    }
  }

  Future<void> importCBZFile({required bool isVolume}) async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.any);
    if (picked == null || picked.files.isEmpty) return;

    final cbz = File(picked.files.single.path!);
    final cbzPath = cbz.path;
    final cbzName = basename(cbzPath);

    String title = basenameWithoutExtension(cbzName);
    int? volume;
    DateTime? publicationDate;
    List<String> genres = [];
    final regex = RegExp(
      r'^(.*?)\s+v(\d+)\s+\((\d{4})\)\s+\((.*?)\)\s+\((.*?)\)\.cbz$',
      caseSensitive: false,
    );
    final match = regex.firstMatch(cbzName);

    if (isVolume && match != null) {
      title = match.group(1)!.trim();
      volume = int.tryParse(match.group(2)!);
      publicationDate = DateTime.tryParse('${match.group(3)}-01-01');
      genres = match.group(5)!.split(',').map((e) => e.trim()).toList();
    }

    MangaModel? mangaModel = await _db.getMangaByTitle(title);
    String mangaId;

    if (mangaModel == null) {
      mangaId = title.replaceAll(' ', '_').toLowerCase();

      final manga = MangaModel(
        id: mangaId,
        title: title,
        authorId: 'unknown',
        userId: userId,
        genres: genres,
        synopsis: 'Descripción no disponible.',
        rating: 0.0,
        startPublicationDate: publicationDate ?? DateTime.now(),
        totalChaptersAmount: 0,
      );

      await _db.insertManga(manga.toMap());

      final note = await _db.getUserNote(userId, manga.id);
      if (note == null) {
        await _db.insertOrUpdateUserNote(
          UserNote(
            userId: userId,
            mangaId: manga.id,
            isFavorited: false,
            readingStatus: ReadingStatus.toRead,
            lastEdited: DateTime.fromMicrosecondsSinceEpoch(0),
          ),
        );
      }

      mangaModel = manga;
    } else {
      mangaId = mangaModel.id;
    }

    final archive = ZipDecoder().decodeBuffer(InputFileStream(cbzPath));
    final chapters = await _extractAndSavePanels(
      archive,
      mangaId: mangaId,
      title: title,
      volume: volume,
      publicationDate: publicationDate,
      isVolume: isVolume,
    );

    await _db.updateMangaChapterCount(mangaId, chapters.length);
    await loadMangas();
  }

  Future<List<Chapter>> _extractAndSavePanels(
    Archive archive, {
    required String mangaId,
    required String title,
    int? volume,
    DateTime? publicationDate,
    required bool isVolume,
  }) async {
    final cbzDir = Directory(
      join((await getApplicationDocumentsDirectory()).path, 'yomu yomu', 'cbz'),
    );
    final extractBasePath = join(cbzDir.path, mangaId);
    final regex = RegExp(
      r' - c(\d+)\s+\(v\d+\)\s+-\s+p(\d+)(?:-p(\d+))?.*\.(jpg|jpeg|png)$',
      caseSensitive: false,
    );

    final Map<String, List<Panel>> chapterPanels = {};
    String? volumeCoverPath;

    for (final f in archive.files.where((f) => f.isFile)) {
      final match = isVolume ? regex.firstMatch(f.name) : null;
      if (isVolume && match == null) continue;

      final chapterNum = isVolume ? match!.group(1)! : '1';
      final panelNum = isVolume ? match!.group(2)! : f.name.hashCode.toString();

      final chapterId = '${mangaId}_c$chapterNum';
      final chapterPath = join(extractBasePath, 'c$chapterNum');
      final outPath = join(chapterPath, basename(f.name));
      final outFile = File(outPath)..createSync(recursive: true);
      await outFile.writeAsBytes(f.content as List<int>);

      if (f.name.contains('p000') && volumeCoverPath == null) {
        volumeCoverPath = outPath;
        await _db.updateMangaCover(mangaId, volumeCoverPath);
      }

      chapterPanels
          .putIfAbsent(chapterId, () => [])
          .add(
            Panel(
              id: '${chapterId}_p$panelNum',
              chapterId: chapterId,
              index: int.tryParse(panelNum) ?? 0,
              filePath: outPath,
            ),
          );
    }

    final chapters = <Chapter>[];
    for (final entry in chapterPanels.entries) {
      final panels = entry.value..sort((a, b) => a.index.compareTo(b.index));
      final chapterNum =
          int.tryParse(
            RegExp(r'c(\d+)$').firstMatch(entry.key)?.group(1) ?? '1',
          ) ??
          1;

      final chapter = Chapter(
        id: entry.key,
        mangaId: mangaId,
        chapterNumber: chapterNum,
        panelsCount: panels.length,
        panels: panels,
        title:
            isVolume
                ? 'Vol. ${volume ?? 1} - Chapter $chapterNum'
                : 'Chapter $chapterNum',
        publicationDate: publicationDate,
        coverUrl: isVolume ? volumeCoverPath : panels.first.filePath,
      );

      await _db.insertChapter(chapter.toMap());
      for (var panel in panels) {
        await _db.insertPanel(panel.toMap());
      }

      chapters.add(chapter);
    }

    return chapters;
  }

  Future<void> _deleteCBZFiles(String mangaId) async {
    final dir = Directory(
      join((await getApplicationDocumentsDirectory()).path, 'yomu yomu', 'cbz'),
    );

    final mangaDir = Directory(join(dir.path, mangaId));
    final cbzFile = File(join(dir.path, '$mangaId.cbz'));

    if (await mangaDir.exists()) await mangaDir.delete(recursive: true);
    if (await cbzFile.exists()) await cbzFile.delete();
  }


  void startListeningEvents() {
    _eventSub = EventBus().stream.listen((event) {
      if (event == 'progress_saved') {
        loadMangas();
      }
    });
  }

  void dispose() {
    _eventSub?.cancel();
  }
}
