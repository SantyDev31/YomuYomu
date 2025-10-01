import 'dart:typed_data';
import 'package:yomuyomu/Mangas/models/chapter_model.dart';

abstract class MangaViewerViewContract {
  void showLoading();
  void hideLoading();
  void updateChapter(Chapter chapter, List<Uint8List> images);
  void saveProgress(String panelId);
}
