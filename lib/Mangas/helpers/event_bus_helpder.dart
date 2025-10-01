import 'dart:async';

class EventBus {
  EventBus._internal();

  static final EventBus _instance = EventBus._internal();

  factory EventBus() => _instance;

  final StreamController<String> _controller = StreamController<String>.broadcast();

  Stream<String> get stream => _controller.stream;

  void fire(String event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}
