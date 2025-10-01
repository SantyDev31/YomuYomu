import 'package:yomuyomu/Mangas/enums/reading_status.dart';
import 'package:yomuyomu/Mangas/models/author_model.dart';
import 'package:yomuyomu/Mangas/models/manga_model.dart';

abstract class LibraryViewContract {
  void showLoading();
  void hideLoading();
  void showError(String message);
  void updateMangaList(List<MangaModel> mangas);
  void updateAuthorList(Map<String, Author> authorMap);
}

abstract class LibraryPresenterContract {
  void loadMangas();
  void filterByStatus(List<ReadingStatus> status);
  void filterByIsFavorited();
  void filterByGenres(List<String> genres);
  void sortBy(int criteria);
}
