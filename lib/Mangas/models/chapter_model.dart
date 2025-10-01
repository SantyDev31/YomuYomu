import 'package:yomuyomu/Mangas/models/panel_model.dart';

class Chapter {
  final String id;
  final String mangaId;
  final int chapterNumber;
  final int panelsCount;
  List<Panel> panels;
  final String? title;
  final String? synopsis;
  final String? coverUrl;
  final DateTime? publicationDate;

  Chapter({
    required this.id,
    required this.mangaId,
    required this.chapterNumber,
    required this.panelsCount,
    required this.panels,
    this.title,
    this.synopsis,
    this.coverUrl,
    this.publicationDate,
  });

  Map<String, dynamic> toMap() => {
    'ChapterID': id,
    'MangaID': mangaId,
    'ChapterNumber': chapterNumber,
    'PanelsCount': panelsCount,
    'Title': title,
    'Synopsis': synopsis,
    'CoverImage': coverUrl,
    'PublicationDate': publicationDate?.millisecondsSinceEpoch,
  };

  static Chapter fromMap(Map<String, dynamic> map, {List<Panel>? panels}) => Chapter(
    id: map['ChapterID'],
    mangaId: map['MangaID'],
    chapterNumber: map['ChapterNumber'],
    panelsCount: map['PanelsCount'],
    panels: panels ?? [],
    title: map['Title'],
    synopsis: map['Synopsis'],
    coverUrl: map['CoverImage'],
    publicationDate:
        map['PublicationDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['PublicationDate'])
            : null,
  );
}
