import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:yomuyomu/DataBase/database_helper.dart';
import 'package:yomuyomu/DataBase/firebase_helper.dart';
import 'package:yomuyomu/Mangas/models/manga_model.dart';
import 'package:yomuyomu/Mangas/models/usernote_model.dart';
import 'package:yomuyomu/Settings/global_settings.dart';

class NotesTab extends StatefulWidget {
  final MangaModel manga;

  const NotesTab({super.key, required this.manga});

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  final _db = DatabaseHelper.instance;
  late final TextEditingController _notesController;
  double _rating = 0;
  UserNote? _userNote;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final note = await _db.getUserNote(userId, widget.manga.id);

      if (mounted) {
        setState(() {
          _userNote =
              note ??
              UserNote(
                userId: userId,
                mangaId: widget.manga.id,
                personalComment: '',
                personalRating: 0,
                isFavorited: false,
                lastEdited: DateTime.now(),
              );
          _notesController.text = _userNote?.personalComment ?? "";
          _rating = _userNote?.personalRating ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading user note: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveNotes() async {
    if (_userNote == null) return;

    final db = DatabaseHelper.instance;

    _userNote = UserNote(
      userId: userId,
      mangaId: _userNote!.mangaId,
      personalComment: _notesController.text,
      personalRating: _rating,
      isFavorited: _userNote!.isFavorited,
      lastEdited: DateTime.now(),
    );

    await db.insertOrUpdateUserNote(_userNote!);
    FirebaseService().insertUserNotesToFirestore(_userNote!.toMap());
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Rating:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          RatingBar.builder(
            initialRating: _rating,
            minRating: 0,
            allowHalfRating: true,
            itemCount: 5,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder:
                (context, _) => const Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: (rating) {
              setState(() {
                _rating = rating;
              });
            },
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton.icon(
              onPressed: _saveNotes,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
