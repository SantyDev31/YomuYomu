import 'package:uuid/uuid.dart';
import 'package:yomuyomu/DataBase/database_helper.dart';
import 'package:yomuyomu/Settings/global_settings.dart';

Future<void> insertBaseData() async {
  final db = DatabaseHelper();
  final uuid = Uuid();

  final existingUser = await db.getUserById(userId);
  if (existingUser == null) {
    await db.insertUser({
      'UserID': userId,
      'Email': "local@local.a",
      'Username': "local",
      'Icon': null,
      'CreationDate': DateTime.now().millisecondsSinceEpoch,
    });
    print('✅ Usuario insertado con el id $userId');
  }

  // Autor por defecto
  final unknownAuthor = await db.getAuthorById('unknown');
  if (unknownAuthor == null) {
    await db.insertAuthor({
      'AuthorID': 'unknown',
      'Name': 'unknown',
      'Biography': 'unknown',
      'Icon': null,
      'BirthDate': DateTime(1980, 1, 1).millisecondsSinceEpoch,
    });
  }

  // Géneros predeterminados
  final existingGenres = await db.getAllGenres();
  if (existingGenres.isEmpty) {
    const genres = [
      'Action', 'Adventure', 'Comedy', 'Drama', 'Ecchi', 'Fantasy', 'Horror',
      'Isekai', 'Josei', 'Martial Arts', 'Mecha', 'Music', 'Mystery',
      'Psychological', 'Romance', 'School', 'Sci-Fi', 'Seinen', 'Shoujo',
      'Shoujo Ai', 'Shounen', 'Shounen Ai', 'Slice of Life', 'Sports',
      'Supernatural', 'Thriller', 'Tragedy', 'Yaoi', 'Yuri', 'Historical',
      'Dementia', 'Parody', 'Magic', 'Military', 'Demons', 'Gangster', 'Game',
      'Survival', 'Samurai',
    ];

    for (var genre in genres.toSet()) {
      final genreId = uuid.v4();
      await db.insertGenre({'GenreID': genreId, 'Description': genre});
    }
  }

  // Configuración de usuario
  final settings = await db.getUserSettingsById(userId);
  if (settings == null) {
    await db.insertUserSettings({
      'UserID': userId,
      'Language': 1,
      'Theme': 0,
      'Orientation': 0,
    });
    print('✅ UserSettings insertado con el id $userId');
  }
}
