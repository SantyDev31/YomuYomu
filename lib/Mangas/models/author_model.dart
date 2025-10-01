class Author {
  final String authorId;
  final String name;
  final String? biography;
  final String? icon;
  final DateTime birthDate; 

  Author({
    required this.authorId,
    required this.name,
    this.biography,
    this.icon,
    required this.birthDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'AuthorID': authorId,
      'Name': name,
      'Biography': biography,
      'Icon': icon,
      'BirthDate': birthDate,
    };
  }

  factory Author.fromMap(Map<String, dynamic> map) {
    return Author(
      authorId: map['AuthorID'],
      name: map['Name'],
      biography: map['Biography'],
      icon: map['Icon'],
      birthDate:
          map['BirthDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['BirthDate'])
              : DateTime.now(),
    );
  }
  
}
