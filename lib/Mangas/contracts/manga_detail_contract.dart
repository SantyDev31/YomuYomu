import 'package:yomuyomu/Mangas/models/chapter_model.dart';
import 'package:yomuyomu/Mangas/models/manga_model.dart';

abstract class MangaDetailViewContract {
  void showLoading();
  void hideLoading();
  void showError(String message);
  void showManga(MangaModel manga);
  void showChapters(List<Chapter> chapters);
}