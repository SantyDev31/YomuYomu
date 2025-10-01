enum ReadingStatus {
  toRead,
  reading,
  paused,
  completed,
  dropped,
  rereading,
}

extension ReadingStatusExtension on ReadingStatus {
  String get name {
    switch (this) {
      case ReadingStatus.toRead:
        return 'To Read';
      case ReadingStatus.reading:
        return 'Reading';
      case ReadingStatus.paused:
        return 'Pause';
      case ReadingStatus.completed:
        return 'Completed';
      case ReadingStatus.dropped:
        return 'Dropped';
      case ReadingStatus.rereading:
        return 'ReReading';
    }
  }

  int get value => index;

  static ReadingStatus fromValue(int value) {
    if (value < 0 || value >= ReadingStatus.values.length) {
      throw ArgumentError('Invalid ReadingStatus value: $value');
    }
    return ReadingStatus.values[value];
  }
}
