import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DirectionalIntent extends Intent {
  final String direction;
  const DirectionalIntent(this.direction);
}

LogicalKeyboardKey keyFromDirection(String dir) {
  switch (dir) {
    case 'left': return LogicalKeyboardKey.arrowLeft;
    case 'right': return LogicalKeyboardKey.arrowRight;
    case 'up': return LogicalKeyboardKey.arrowUp;
    case 'down': return LogicalKeyboardKey.arrowDown;
    default: return LogicalKeyboardKey.space;
  }
}
