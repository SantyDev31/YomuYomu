import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yomuyomu/Settings/global_settings.dart';
import 'package:yomuyomu/Mangas/contracts/manga_viewer_contract.dart';
import 'package:yomuyomu/Mangas/helpers/manga_navigation_helper.dart';
import 'package:yomuyomu/Mangas/models/chapter_model.dart';
import 'package:yomuyomu/Mangas/presenters/manga_viewer_presenter.dart';

class MangaViewer extends StatefulWidget {
  final List<Chapter> chapters;
  final Chapter initialChapter;

  const MangaViewer({
    super.key,
    required this.chapters,
    required this.initialChapter,
  });

  @override
  State<MangaViewer> createState() => _MangaViewerState();
}

class _MangaViewerState extends State<MangaViewer>
    implements MangaViewerViewContract {
  late Chapter _currentChapter;
  List<Uint8List> _currentImages = [];
  bool _isLoading = true;

  late MangaViewerPresenter _presenter;

  final ScrollController _scrollController = ScrollController();
  late Size _screenSize;

  @override
  void initState() {
    super.initState();
    _presenter = MangaViewerPresenter(this);
    _currentChapter = widget.initialChapter;
    _presenter.loadChapterImages(_currentChapter);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.of(context).size;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void showLoading() {
    setState(() {
      _isLoading = true;
    });
  }

  @override
  void hideLoading() {
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void updateChapter(Chapter chapter, List<Uint8List> images) {
    setState(() {
      _currentChapter = chapter;
      _currentImages = images;
    });
  }

  @override
  void saveProgress(String panelId) {
    _presenter.saveProgress(panelId);
  }


  void _goToNextChapter() {
    final index = widget.chapters.indexOf(_currentChapter);
    if (index < widget.chapters.length - 1) {
      _presenter.loadChapterImages(widget.chapters[index + 1]);
      _scrollController.jumpTo(0);
    }
  }

  void _goToPreviousChapter() {
    final index = widget.chapters.indexOf(_currentChapter);
    if (index > 0) {
      _presenter.loadChapterImages(widget.chapters[index - 1]);
      _scrollController.jumpTo(0);
    }
  }

  void _saveVisiblePanelProgress() {
    final axis = userDirectionPreference.value;
    final itemSize =
        axis == Axis.vertical
            ? _screenSize.height + 10
            : _screenSize.width + 10;

    final index = (_scrollController.offset / itemSize).round();
    if (index >= 0 && index < _currentChapter.panels.length) {
      final panelId = _currentChapter.panels[index].id;
      saveProgress(panelId);
    }
  }

  void _handleArrowNavigation(LogicalKeyboardKey key, Axis axis) {
    final isHorizontal = axis == Axis.horizontal;
    final scrollAmount = 300.0;

    double newOffset = _scrollController.offset;

    if (isHorizontal) {
      if (key == LogicalKeyboardKey.arrowLeft) {
        newOffset -= scrollAmount;
      } else if (key == LogicalKeyboardKey.arrowRight) {
        newOffset += scrollAmount;
      }
    } else {
      if (key == LogicalKeyboardKey.arrowUp) {
        newOffset -= scrollAmount;
      } else if (key == LogicalKeyboardKey.arrowDown) {
        newOffset += scrollAmount;
      }
    }

    _scrollController.animateTo(
      newOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _saveVisiblePanelProgress();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentChapter.title ?? 'Chapter'),
          backgroundColor: Colors.black,
          titleTextStyle: const TextStyle(color: Colors.cyanAccent),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.navigate_before),
              onPressed: _isLoading ? null : _goToPreviousChapter,
            ),
            IconButton(
              icon: const Icon(Icons.navigate_next),
              onPressed: _isLoading ? null : _goToNextChapter,
            ),
          ],
        ),
        backgroundColor: Colors.black,
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ValueListenableBuilder<Axis>(
                  valueListenable: userDirectionPreference,
                  builder: (context, axis, _) {
                    final isVertical = axis == Axis.vertical;

                    return FocusableActionDetector(
                      autofocus: true,
                      shortcuts: {
                        LogicalKeySet(
                          LogicalKeyboardKey.arrowLeft,
                        ): const DirectionalIntent('right'),
                        LogicalKeySet(
                          LogicalKeyboardKey.arrowRight,
                        ): const DirectionalIntent('left'),
                        LogicalKeySet(
                          LogicalKeyboardKey.arrowUp,
                        ): const DirectionalIntent('up'),
                        LogicalKeySet(
                          LogicalKeyboardKey.arrowDown,
                        ): const DirectionalIntent('down'),
                      },
                      actions: {
                        DirectionalIntent: CallbackAction<DirectionalIntent>(
                          onInvoke:
                              (intent) => _handleArrowNavigation(
                                keyFromDirection(intent.direction),
                                axis,
                              ),
                        ),
                      },

                      child: ScrollConfiguration(
                        behavior: const ScrollBehavior().copyWith(
                          overscroll: false,
                        ),
                        child:
                            isVertical
                                ? ListView.separated(
                                  key: const PageStorageKey(
                                    'manga_scroll_vertical',
                                  ),
                                  controller: _scrollController,
                                  scrollDirection: Axis.vertical,
                                  padding: EdgeInsets.zero,
                                  itemCount: _currentImages.length,
                                  itemBuilder:
                                      (context, index) => SizedBox(
                                        width: _screenSize.width,
                                        height: _screenSize.height,
                                        child: InteractiveViewer(
                                          panEnabled: true,
                                          minScale: 1.0,
                                          maxScale: 4.0,
                                          child: Image.memory(
                                            _currentImages[index],
                                            fit: BoxFit.contain,
                                            gaplessPlayback: true,
                                          ),
                                        ),
                                      ),
                                  separatorBuilder:
                                      (_, __) => const SizedBox(height: 5),
                                )
                                : ListView.separated(
                                  key: const PageStorageKey(
                                    'manga_scroll_horizontal',
                                  ),
                                  controller: _scrollController,
                                  scrollDirection: Axis.horizontal,
                                  reverse: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: _currentImages.length,
                                  itemBuilder:
                                      (context, index) => InteractiveViewer(
                                        panEnabled: true,
                                        minScale: 1.0,
                                        maxScale: 4.0,
                                        child: Image.memory(
                                          _currentImages[index],
                                          fit: BoxFit.contain,
                                          gaplessPlayback: true,
                                        ),
                                      ),
                                  separatorBuilder:
                                      (_, __) => const SizedBox(width: 10),
                                ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
