 import 'package:flutter/material.dart';
import 'package:yomuyomu/Mangas/enums/reading_status.dart';
import 'package:yomuyomu/Mangas/models/manga_model.dart';
import 'package:yomuyomu/Mangas/widgets/delete_tab.dart';
import 'package:yomuyomu/Mangas/widgets/genres_tab.dart';
import 'package:yomuyomu/Mangas/widgets/note_tab.dart';
import 'package:yomuyomu/Mangas/widgets/status_tab.dart';

class MangaOptionsDialog extends StatelessWidget {
  final MangaModel manga;
  final Function(ReadingStatus) onStatusChanged;
  final Function() onGenresUpdated;
  final Function() onDeleteConfirmed;

  const MangaOptionsDialog({
    required this.manga,
    required this.onStatusChanged,
    required this.onGenresUpdated,
    required this.onDeleteConfirmed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: const TabBar(
                labelColor: Colors.amber,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.amber,
                tabs: [
                  Tab(text: 'Notes & Stars'),
                  Tab(text: 'Status'),
                  Tab(text: 'Genres'),
                  Tab(text: 'Delete'),
                ],
              ),
            ),
            Flexible(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                height: 350,
                child: TabBarView(
                  children: [
                    NotesTab(manga: manga),
                    StatusTab(
                      manga: manga,
                      onStatusChanged: (status) {
                        onStatusChanged(status);
                      },
                    ),
                    GenresTab(
                      manga: manga,
                      onGenresUpdated: onGenresUpdated,
                    ),
                    DeleteTab(
                      manga: manga,
                      onDeleteConfirmed: () {
                        Navigator.pop(context);
                        onDeleteConfirmed();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
