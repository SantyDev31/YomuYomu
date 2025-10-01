class Panel {
  final String id;
  final String chapterId;
  final int index;
  final String filePath;

  Panel({
    required this.id,
    required this.chapterId,
    required this.index,
    required this.filePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'PanelID': id,
      'ChapterID': chapterId,
      'ImagePath': filePath,
      'PageNumber': index,
    };
  }

  factory Panel.fromMap(Map<String, dynamic> map) {
    return Panel(
      id: map['PanelID'] as String,
      chapterId: map['ChapterID'] as String,
      index: map['PageNumber'] as int,
      filePath: map['ImagePath'] as String,
    );
  }
}
