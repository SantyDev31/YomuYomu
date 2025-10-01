import 'dart:io';
import 'dart:typed_data';
import 'package:yomuyomu/DataBase/firebase_helper.dart';
import 'package:yomuyomu/Mangas/contracts/manga_viewer_contract.dart';
import 'package:yomuyomu/DataBase/database_helper.dart';
import 'package:yomuyomu/Mangas/helpers/event_bus_helpder.dart';
import 'package:yomuyomu/Mangas/models/chapter_model.dart';
import 'package:yomuyomu/Settings/global_settings.dart';

class MangaViewerPresenter {
  final MangaViewerViewContract view;

  MangaViewerPresenter(this.view);

  Future<void> loadChapterImages(Chapter chapter) async {
    view.showLoading();

    final images = <Uint8List>[];
    for (final panel in chapter.panels) {
      final file = File(panel.filePath);
      if (await file.exists()) {
        images.add(await file.readAsBytes());
      }
    }

    view.updateChapter(chapter, images);
    view.hideLoading();
  }

  Future<void> saveProgress(String panelId) async {
    final db = DatabaseHelper.instance;
    final now = DateTime.now().millisecondsSinceEpoch;
     final Map<String, dynamic> userProgressData = {
    'UserID': userId,
    'PanelID': panelId,
    'LastReadDate': now,
  };
    await db.insertUserProgress(userProgressData);
    await FirebaseService().insertUserPogressToFirestore(userProgressData);

    EventBus().fire('progress_saved');
    print("Se ha guardado el userid $userId el panel $panelId");
  }
}
