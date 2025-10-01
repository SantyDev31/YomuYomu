import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:yomuyomu/Mangas/models/genre_model.dart';
import 'package:yomuyomu/Mangas/models/manga_model.dart';
import 'package:yomuyomu/Mangas/models/usernote_model.dart';
import 'package:yomuyomu/Settings/global_settings.dart';

class DatabaseHelper {
  static const _databaseName = "yomuyomu.db";
  static const _databaseVersion = 1;

  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _databaseName);
    final db = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    await db.execute('PRAGMA foreign_keys = ON;');
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = ON;');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS User (
        UserID TEXT PRIMARY KEY,
        Email TEXT NOT NULL,
        Username TEXT NOT NULL,
        Icon TEXT,
        CreationDate INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS Author (
        AuthorID TEXT PRIMARY KEY,
        Name TEXT NOT NULL,
        Biography TEXT,
        Icon TEXT,
        BirthDate INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS Manga (
        MangaID TEXT PRIMARY KEY,
        AuthorID TEXT,
        UserID TEXT,
        Title TEXT NOT NULL,
        Synopsis TEXT,
        Rating REAL,
        CoverImage TEXT,
        StartPublicationDate INTEGER NOT NULL,
        NextPublicationDate INTEGER,
        Chapters INTEGER NOT NULL,
        FOREIGN KEY (AuthorID) REFERENCES Author(AuthorID),
        FOREIGN KEY (UserID) REFERENCES User(UserID)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS Chapter (
        ChapterID TEXT PRIMARY KEY,
        MangaID TEXT NOT NULL,
        ChapterNumber INTEGER NOT NULL,
        PanelsCount INTEGER NOT NULL,
        Title TEXT,
        Synopsis TEXT,
        CoverImage TEXT,
        PublicationDate INTEGER,
        FOREIGN KEY (MangaID) REFERENCES Manga(MangaID)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS Panel (
        PanelID TEXT PRIMARY KEY,
        ChapterID TEXT NOT NULL,
        ImagePath TEXT NOT NULL,
        PageNumber INTEGER NOT NULL,
        FOREIGN KEY (ChapterID) REFERENCES Chapter(ChapterID) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS Genre (
        GenreID TEXT PRIMARY KEY,
        Description TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS GenreManga (
        MangaID TEXT,
        GenreID TEXT,
        PRIMARY KEY (MangaID, GenreID),
        FOREIGN KEY (MangaID) REFERENCES Manga(MangaID),
        FOREIGN KEY (GenreID) REFERENCES Genre(GenreID)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS UserProgress (
        UserID TEXT,
        PanelID TEXT,
        LastReadDate INTEGER,
        PRIMARY KEY (UserID, PanelID),
        FOREIGN KEY (UserID) REFERENCES User(UserID),
        FOREIGN KEY (PanelID) REFERENCES Panel(PanelID) 
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS UserNote (
        UserID TEXT,
        MangaID TEXT,
        PersonalComment TEXT,
        PersonalRating REAL,
        IsFavorited INTEGER DEFAULT 0,
        ReadingStatus INTEGER DEFAULT 0,
        LastEdited INTEGER,
        PRIMARY KEY (UserID, MangaID),
        FOREIGN KEY (UserID) REFERENCES User(UserID) ON DELETE CASCADE,
        FOREIGN KEY (MangaID) REFERENCES Manga(MangaID) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS UserSettings (
        UserID TEXT PRIMARY KEY,
        Language INTEGER DEFAULT 0,
        Theme INTEGER DEFAULT 0,
        Orientation INTEGER DEFAULT 0,
        FOREIGN KEY (UserID) REFERENCES User(UserID)
      );
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {}
  }

  Future<void> deleteDatabaseFile() async {
    final path = join(await getDatabasesPath(), _databaseName);
    await deleteDatabase(path);
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return await db.query(table);
  }

  Future<Map<String, dynamic>?> queryById(
    String table,
    String key,
    String id,
  ) async {
    final db = await database;
    final result = await db.query(table, where: '$key = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data,
    String key,
    String id,
  ) async {
    final db = await database;
    return await db.update(table, data, where: '$key = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, String key, String id) async {
    final db = await database;
    return await db.delete(table, where: '$key = ?', whereArgs: [id]);
  }

  Future<void> clearTable(String table) async {
    final db = await database;
    await db.delete(table);
  }

  Future<int> insertUser(Map<String, dynamic> data) => insert('User', data);
  Future<List<Map<String, dynamic>>> getAllUsers() => queryAll('User');
  Future<Map<String, dynamic>?> getUserById(String id) =>
      queryById('User', 'UserID', id);
  Future<int> updateUser(Map<String, dynamic> data, String id) {
    final filteredData = Map<String, dynamic>.from(data)
      ..removeWhere((key, value) => value == null);

    return update('User', filteredData, 'UserID', id);
  }

  Future<int> deleteUser(String id) => delete('User', 'UserID', id);

  Future<int> insertAuthor(Map<String, dynamic> data) => insert('Author', data);
  Future<List<Map<String, dynamic>>> getAllAuthors() => queryAll('Author');
  Future<Map<String, dynamic>?> getAuthorById(String id) =>
      queryById('Author', 'AuthorID', id);
  Future<int> updateAuthor(Map<String, dynamic> data, String id) =>
      update('Author', data, 'AuthorID', id);
  Future<int> deleteAuthor(String id) => delete('Author', 'AuthorID', id);

  Future<int> insertManga(Map<String, dynamic> data) => insert('Manga', data);
  Future<List<Map<String, dynamic>>> getAllMangas() => queryAll('Manga');
  Future<Map<String, dynamic>?> getMangaById(String id) =>
      queryById('Manga', 'MangaID', id);
  Future<int> updateManga(Map<String, dynamic> data, String id) =>
      update('Manga', data, 'MangaID', id);
  Future<int> deleteManga(String id) => delete('Manga', 'MangaID', id);

  Future<int> insertChapter(Map<String, dynamic> data) =>
      insert('Chapter', data);
  Future<List<Map<String, dynamic>>> getAllChapters() => queryAll('Chapter');
  Future<Map<String, dynamic>?> getChapterById(String id) =>
      queryById('Chapter', 'ChapterID', id);
  Future<int> updateChapter(Map<String, dynamic> data, String id) =>
      update('Chapter', data, 'ChapterID', id);
  Future<int> deleteChapter(String id) => delete('Chapter', 'ChapterID', id);

  Future<int> insertPanel(Map<String, dynamic> data) => insert('Panel', data);
  Future<List<Map<String, dynamic>>> getAllPanels() => queryAll('Panel');
  Future<Map<String, dynamic>?> getPanelById(String id) =>
      queryById('Panel', 'PanelID', id);
  Future<int> updatePanel(Map<String, dynamic> data, String id) =>
      update('Panel', data, 'PanelID', id);
  Future<int> deletePanel(String id) => delete('Panel', 'PanelID', id);

  Future<int> insertGenre(Map<String, dynamic> data) => insert('Genre', data);
  Future<Map<String, dynamic>?> getGenreById(String id) =>
      queryById('Genre', 'GenreID', id);
  Future<int> updateGenre(Map<String, dynamic> data, String id) =>
      update('Genre', data, 'GenreID', id);
  Future<int> deleteGenre(String id) => delete('Genre', 'GenreID', id);

  Future<int> insertGenreManga(Map<String, dynamic> data) =>
      insert('GenreManga', data);
  Future<List<Map<String, dynamic>>> getAllGenreManga() =>
      queryAll('GenreManga');

  Future<List<Map<String, dynamic>>> getAllUserProgress() =>
      queryAll('UserProgress');
  Future<Map<String, dynamic>?> getUserProgressById(String id) =>
      queryById('UserProgress', 'UserID', id);
  Future<int> updateUserProgress(Map<String, dynamic> data, String id) =>
      update('UserProgress', data, 'UserID', id);
  Future<int> deleteUserProgress(String id) =>
      delete('UserProgress', 'UserID', id);

  Future<int> insertUserSettings(Map<String, dynamic> data) =>
      insert('UserSettings', data);
  Future<List<Map<String, dynamic>>> getAllUserSettings() =>
      queryAll('UserSettings');
  Future<Map<String, dynamic>?> getUserSettingsById(String id) =>
      queryById('UserSettings', 'UserID', id);
  Future<int> updateUserSettings(Map<String, dynamic> data, String id) =>
      update('UserSettings', data, 'UserID', id);
  Future<int> deleteUserSettings(String id) =>
      delete('UserSettings', 'UserID', id);

  Future<List<Map<String, dynamic>>> getChaptersByMangaId(
    String mangaId,
  ) async {
    final db = await database;
    return await db.query(
      'Chapter',
      where: 'MangaID = ?',
      whereArgs: [mangaId],
      orderBy: 'ChapterNumber ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getPanelsByChapterId(
    String chapterId,
  ) async {
    final db = await database;
    return await db.query(
      'Panel',
      where: 'ChapterID = ?',
      whereArgs: [chapterId],
    );
  }

  Future<void> updateMangaCover(String mangaId, String coverUrl) async {
    final db = await database;
    await db.update(
      'Manga',
      {'CoverImage': coverUrl},
      where: 'MangaID = ?',
      whereArgs: [mangaId],
    );
  }

  Future<void> updateMangaChapterCount(
    String mangaId,
    int chapterCountToAdd,
  ) async {
    final db = await database;

    final result = await db.query(
      'Manga',
      columns: ['Chapters'],
      where: 'MangaID = ?',
      whereArgs: [mangaId],
    );

    if (result.isNotEmpty) {
      final currentCount = result.first['Chapters'] as int;
      final newCount = currentCount + chapterCountToAdd;

      await db.update(
        'Manga',
        {'Chapters': newCount},
        where: 'MangaID = ?',
        whereArgs: [mangaId],
      );
    } else {
      throw Exception("Manga con ID $mangaId no encontrado.");
    }
  }

  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();

    if (status.isGranted) {
      return true;
    } else {
      openAppSettings();
      return false;
    }
  }

  Future<MangaModel?> getMangaByTitle(String title) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'Manga',
      where: 'title = ?',
      whereArgs: [title],
    );

    if (maps.isNotEmpty) {
      return MangaModel.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getLastReadPanelForManga({
    required String userId,
    required String mangaId,
  }) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
    SELECT
      up.PanelID,
      p.ChapterID,
      c.ChapterNumber,
      p.PageNumber,
      up.LastReadDate
    FROM UserProgress up
    JOIN Panel p ON up.PanelID = p.PanelID
    JOIN Chapter c ON p.ChapterID = c.ChapterID
    WHERE up.UserID = ?
      AND c.MangaID = ?
    ORDER BY up.LastReadDate DESC
    LIMIT 1;
  ''',
      [userId, mangaId],
    );

    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'User',
      where: 'Email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<UserNote?> getUserNote(String userId, String mangaId) async {
    final db = await database;
    final maps = await db.query(
      'UserNote',
      where: 'UserID = ? AND MangaID = ?',
      whereArgs: [userId, mangaId],
    );

    if (maps.isNotEmpty) {
      return UserNote.fromMap(maps.first);
    }
    return null;
  }

  Future<List<UserNote>> getUserNotes(String userId) async {
    final db = await database;
    final maps = await db.query(
      'UserNote',
      where: 'UserID = ?',
      whereArgs: [userId],
    );

    return maps.map((map) => UserNote.fromMap(map)).toList();
  }

  Future<void> insertOrUpdateUserNote(UserNote note) async {
    final db = await database;
    await db.insert(
      'UserNote',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertOrUpdateUserNoteMap(
    Map<String, dynamic> userNoteData,
  ) async {
    final db = await database;
    await db.insert(
      'UserNote',
      userNoteData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deletePanelsByChapterId(String chapterId) async {
    final db = await database;

    await db.delete('Panel', where: 'chapterId = ?', whereArgs: [chapterId]);
  }

  Future<List<GenreModel>> getAllGenres() async {
    final db = await database;
    final result = await db.query('Genre');
    return result.map((e) => GenreModel.fromMap(e)).toList();
  }

  Future<void> updateMangaGenres(String mangaId, List<String> genres) async {
    final db = await database;
    await db.delete('GenreManga', where: 'MangaID = ?', whereArgs: [mangaId]);
    for (final genre in genres) {
      await db.insert('GenreManga', {'MangaID': mangaId, 'GenreID': genre});
    }
  }

  Future<List<String>> getGenreIdsForManga(String mangaId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT GenreID FROM GenreManga WHERE MangaID = ?',
      [mangaId],
    );
    return result
        .map((e) => e['GenreID']?.toString())
        .whereType<String>()
        .toList();
  }

  Future<int> updateMangaStatus({
    required String userId,
    required String mangaId,
    required int readingStatus,
  }) async {
    final db = await database;

    return await db.update(
      'UserNote',
      {
        'ReadingStatus': readingStatus,
        'LastEdited': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'UserID = ? AND MangaID = ?',
      whereArgs: [userId, mangaId],
    );
  }

  Future<UserNote?> getUserNoteForManga(String userId, String mangaId) async {
    final db = await database;

    final result = await db.query(
      'UserNote',
      where: 'UserID = ? AND MangaID = ?',
      whereArgs: [userId, mangaId],
    );

    if (result.isNotEmpty) {
      return UserNote.fromMap(result.first);
    }

    return null;
  }

  Future<LastReadChapter?> getLastReadChapterWithDate(
    String userId,
    String mangaId,
  ) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
    SELECT Chapter.ChapterNumber, UserProgress.LastReadDate
    FROM UserProgress
    JOIN Panel ON Panel.PanelID = UserProgress.PanelID
    JOIN Chapter ON Chapter.ChapterID = Panel.ChapterID
    WHERE UserProgress.UserID = ? AND Chapter.MangaID = ?
    ORDER BY UserProgress.LastReadDate DESC
    LIMIT 1;
  ''',
      [userId, mangaId],
    );

    if (result.isNotEmpty) {
      return LastReadChapter(
        chapterNumber: result.first['ChapterNumber'] as int,
        lastReadDate: result.first['LastReadDate'] as int,
      );
    }

    return null;
  }

  Future<List<String>> getFavoriteMangaCovers(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
    SELECT M.CoverImage
    FROM UserNote UN
    INNER JOIN Manga M ON UN.MangaID = M.MangaID
    WHERE UN.UserID = ? AND UN.IsFavorited = 1
    ORDER BY UN.LastEdited DESC
    LIMIT 5
  ''',
      [userId],
    );

    return results
        .map((row) => row['CoverImage'] as String)
        .where((cover) => cover.isNotEmpty)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getAllLocalUserProgress() async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.query(
      'UserProgress',
      where: 'UserID = ?',
      whereArgs: [userId],
    );

    return result;
  }

  Future<List<Map<String, dynamic>>> getAllLocalUserNotes() async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.query(
      'UserNote',
      where: 'UserID = ?',
      whereArgs: [userId],
    );

    return result;
  }

  Future<Set<String>> getAllLocalMangaIDs() async {
    final db = await database;
    final result = await db.query('Manga', columns: ['MangaID']);
    return result.map((row) => row['MangaID'] as String).toSet();
  }

  Future<void> insertUserProgress(Map<String, dynamic> userProgressData) async {
    final db = await database;
    final dataToInsert = Map<String, dynamic>.from(userProgressData)
      ..['UserID'] = userId;

    await db.insert(
      'UserProgress',
      dataToInsert,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Set<String>> getAllLocalPanelIDs() async {
    final db = await database;
    final result = await db.query('Panel', columns: ['PanelID']);
    return result.map((row) => row['PanelID'] as String).toSet();
  }

  Future<String?> getSingleUserID() async {
    final db = await database;
    final result = await db.query('User', columns: ['UserID'], limit: 1);
    if (result.isNotEmpty) {
      return result.first['UserID'] as String;
    }
    return null;
  }
}
