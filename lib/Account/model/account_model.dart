class AccountModel {
  final String userID;
  final String email;
  final String username;
  final DateTime creationDate;
  final String? icon;

  final List<String> favoriteMangaCovers;
  final int finishedMangasCount;

  AccountModel({
    required this.userID,
    required this.email,
    required this.username,
    required this.creationDate,
    this.icon,
    this.favoriteMangaCovers = const [],
    this.finishedMangasCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'UserID': userID,
      'Email': email,
      'Username': username,
      'Icon': icon,
      'CreationDate': creationDate.millisecondsSinceEpoch,
    };
  }

  factory AccountModel.fromMap(
    Map<String, dynamic> map, {
    List<String> favoriteMangaCovers = const [],
    int finishedMangasCount = 0,
  }) {
    return AccountModel(
      userID: map['UserID'],
      email: map['Email'],
      username: map['Username'],
      icon: map['Icon'],
      creationDate: DateTime.fromMillisecondsSinceEpoch(map['CreationDate']),
      favoriteMangaCovers: favoriteMangaCovers,
      finishedMangasCount: finishedMangasCount,
    );
  }
}
