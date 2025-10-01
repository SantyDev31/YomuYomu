import 'package:yomuyomu/Mangas/enums/reading_status.dart';

class UserNote {
  final String userId;
  final String mangaId;
  String? personalComment;
  double? personalRating;
  bool isFavorited;
  ReadingStatus readingStatus;
  DateTime? lastEdited;

  UserNote({
    required this.userId,
    required this.mangaId,
    this.personalComment,
    this.personalRating,
    this.isFavorited = false,
    this.readingStatus = ReadingStatus.toRead,
    this.lastEdited,
  });

  Map<String, dynamic> toMap() {
    return {
      'UserID': userId,
      'MangaID': mangaId,
      'PersonalComment': personalComment,
      'PersonalRating': personalRating,
      'IsFavorited': isFavorited ? 1 : 0,
      'ReadingStatus': readingStatus.value, 
      'LastEdited': lastEdited?.millisecondsSinceEpoch,
    };
  }

  factory UserNote.fromMap(Map<String, dynamic> map) {
    return UserNote(
      userId: map['UserID'],
      mangaId: map['MangaID'],
      personalComment: map['PersonalComment'],
      personalRating:
          map['PersonalRating'] != null
              ? (map['PersonalRating'] as num).toDouble()
              : null,
      isFavorited: map['IsFavorited'] == 1,
      readingStatus: ReadingStatus.values.firstWhere(
        (e) => e.value == map['ReadingStatus'],
        orElse: () => ReadingStatus.toRead,
      ),
      lastEdited:
          map['LastEdited'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['LastEdited'])
              : null,
    );
  }
}
