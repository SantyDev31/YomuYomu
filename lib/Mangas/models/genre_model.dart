class GenreModel {
  final String genreId;
  final String description;

  GenreModel({required this.genreId, required this.description});

  Map<String, dynamic> toMap() {
    return {'GenreID': genreId, 'Description': description};
  }

  factory GenreModel.fromMap(Map<String, dynamic> map) {
    return GenreModel(genreId: map['GenreID'], description: map['Description']);
  }
}
