import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

class CBZHandler {
  final File cbzFile;
  late final String mangaTitle;

  CBZHandler(this.cbzFile);

  Future<Map<String, List<_InMemoryImage>>> extractChaptersInMemory() async {
    final inputStream = InputFileStream(cbzFile.path);
    final archive = ZipDecoder().decodeBuffer(inputStream);
    final Map<String, List<_InMemoryImage>> chapterMap = {};

    for (final file in archive.files) {
      if (file.isFile && _isImage(file.name)) {
        final data = file.content as List<int>;
        final filename = p.basenameWithoutExtension(file.name);

        final parsed = _parseFilename(filename);
        if (parsed == null) continue;

        final String chapterKey = parsed.chapter;

        chapterMap
            .putIfAbsent(chapterKey, () => [])
            .add(
              _InMemoryImage(
                filename: file.name,
                data: Uint8List.fromList(data),
                page: parsed.page,
              ),
            );
      }
    }

    for (final entry in chapterMap.entries) {
      entry.value.sort((a, b) => a.page.compareTo(b.page));
    }

    return chapterMap;
  }

  Future<List<Uint8List>> extractImagesByChapter(String chapterId) async {
    final chapters = await extractChaptersInMemory();

    if (!chapters.containsKey(chapterId)) {
      return [];
    }

    return chapters[chapterId]!.map((img) => img.data).toList();
  }

  bool _isImage(String filename) {
    final ext = p.extension(filename).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.webp'].contains(ext);
  }

  _ParsedFilename? _parseFilename(String filename) {
    final RegExp regex = RegExp(r'(.+?) - (\d+) \(.*?\) - (\d+)$');
    final match = regex.firstMatch(filename);
    if (match == null) return null;

    final chapter = match.group(2)!;
    final page = int.tryParse(match.group(3)!);
    if (page == null) return null;

    return _ParsedFilename(chapter: chapter, page: page);
  }
}

class _InMemoryImage {
  final String filename;
  final Uint8List data;
  final int page;

  _InMemoryImage({
    required this.filename,
    required this.data,
    required this.page,
  });
}

class _ParsedFilename {
  final String chapter;
  final int page;

  _ParsedFilename({required this.chapter, required this.page});
}
