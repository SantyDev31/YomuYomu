import 'package:yomuyomu/Mangas/enums/reading_status.dart';
import 'package:yomuyomu/Mangas/models/chapter_model.dart';

class MangaModel {
  final String id;
  String title;
  String authorId;
  String userId;
  String? synopsis;
  double rating;
  DateTime startPublicationDate;
  DateTime? nextPublicationDate;
  DateTime? lastReadDate;
  List<String> genres;
  ReadingStatus status;
  int totalChaptersAmount;
  int lastChapterRead;
  bool isFavorited;
  String? coverUrl;
  String? folderId;
  List<Chapter>? chapters;

  MangaModel({
    required this.id,
    required this.title,
    required this.authorId,
    this.synopsis,
    required this.userId,
    this.rating = 0.0,
    required this.startPublicationDate,
    this.nextPublicationDate,
    this.lastReadDate,
    List<String>? genres,
    this.status = ReadingStatus.toRead,
    required this.totalChaptersAmount,
    this.lastChapterRead = 0,
    this.isFavorited = false,
    this.coverUrl,
    this.folderId,
    this.chapters,
  }) : genres = (genres ?? []) {
    if (rating < 0 || rating > 5) {
      throw ArgumentError('Rating must be between 0 and 5');
    }
    if (nextPublicationDate != null &&
        nextPublicationDate!.isBefore(startPublicationDate)) {
      throw ArgumentError('Next publication date must be after start date');
    }
    if (lastReadDate != null && lastReadDate!.isBefore(startPublicationDate)) {
      throw ArgumentError('Last read date cannot be before start date');
    }
  }

  Map<String, dynamic> toMap() => {
    'MangaID': id,
    'AuthorID': authorId,
    'UserID': userId,
    'Title': title,
    'Synopsis': synopsis,
    'Rating': rating,
    'StartPublicationDate': startPublicationDate.millisecondsSinceEpoch,
    'NextPublicationDate': nextPublicationDate?.millisecondsSinceEpoch,
    'Chapters': totalChaptersAmount,
    'CoverImage': coverUrl,
  };

  factory MangaModel.fromMap(
    Map<String, dynamic> map, {
    List<String> genres = const [],
    DateTime? lastReadDate,
    int? lastChapterRead,
    ReadingStatus? status,
    bool? isFavorited,
    double? rating,
  }) {
    return MangaModel(
      id: map['MangaID'] ?? '',
      authorId: map['AuthorID'],
      title: map['Title'] ?? '',
      synopsis: map['Synopsis'],
      userId: map['UserID'],
      rating:
          rating ??
          (map['Rating'] != null ? (map['Rating'] as num).toDouble() : 0),
      startPublicationDate:
          map['StartPublicationDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['StartPublicationDate'])
              : DateTime.now(),
      nextPublicationDate:
          map['NextPublicationDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['NextPublicationDate'])
              : null,
      totalChaptersAmount: map['Chapters'] ?? 0,
      coverUrl: map['CoverImage'],
      genres: genres,
      status:
          status ??
          (map.containsKey('ReadingStatus')
              ? ReadingStatusExtension.fromValue(map['ReadingStatus'] as int)
              : ReadingStatus.toRead),
      isFavorited: isFavorited ?? (map['IsFavorited'] == 1),
      lastChapterRead: lastChapterRead ?? 0,
      lastReadDate: lastReadDate,
    );
  }
}

class LastReadChapter {
  final int chapterNumber;
  final int lastReadDate;

  LastReadChapter({required this.chapterNumber, required this.lastReadDate});
}
