import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yomuyomu/DataBase/database_helper.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> insertUserPogressToFirestore(
    Map<String, dynamic> userPogress,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('Usuario no autenticado');
      return;
    }

    final String userId = user.uid;
    final String panelId = userPogress['PanelID'];
    final String userPogressId = "$userId-$panelId";
    await _firestore
        .collection('Users')
        .doc(userId)
        .collection('UserProgress')
        .doc(userPogressId)
        .set(userPogress, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> getAllUserProgressFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('Usuario no autenticado');
      return [];
    }

    final String userId = user.uid;

    try {
      final querySnapshot =
          await _firestore
              .collection('Users')
              .doc(userId)
              .collection('UserProgress')
              .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error al obtener todos los progresos: $e');
      return [];
    }
  }

  Future<void> syncUserProgressWithFirestore() async {
    final db = DatabaseHelper.instance;
    final user = _auth.currentUser;

    if (user == null) {
      print('Usuario no autenticado');
      return;
    }

    final userId = user.uid;

    final remoteProgressList = await getAllUserProgressFromFirestore();
    final localProgressList = await db.getAllLocalUserProgress();
    final localPanelIds = await db.getAllLocalPanelIDs();

    final Map<String, Map<String, dynamic>> localMap = {
      for (var p in localProgressList)
        if (p['PanelID'] != null) p['PanelID']: p,
    };

    final Map<String, Map<String, dynamic>> remoteMap = {
      for (var p in remoteProgressList)
        if (p['PanelID'] != null) p['PanelID']: p,
    };

    final Set<String> allPanelIDs = {...localMap.keys, ...remoteMap.keys};

    for (final panelId in allPanelIDs) {
      final local = localMap[panelId];
      final remote = remoteMap[panelId];

      if (!localPanelIds.contains(panelId)) {
        print('⚠️ PanelID $panelId no existe localmente. Ignorado.');
        continue;
      }

      final int localDate = local?['LastReadDate'] ?? 0;
      final int remoteDate = remote?['LastReadDate'] ?? 0;

      if (local != null && (remote == null || localDate > remoteDate)) {
        await insertUserPogressToFirestore(local);
        print('📤 Subido a Firestore desde local: $panelId');
      } else if (remote != null && (local == null || remoteDate > localDate)) {
        final enrichedRemote = {...remote, 'UserID': userId};
        await db.insertUserProgress(enrichedRemote);
        print('📥 Insertado en local desde Firestore: $panelId');
      } else {
        print('🔁 Sin cambios para $panelId');
      }
    }

    print('✅ Sincronización de UserProgress completada.');
  }

  Future<void> insertUserNotesToFirestore(
    Map<String, dynamic> userNotes,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('Usuario no autenticado');
      return;
    }

    final String userId = user.uid;
    final String mangaId = userNotes['MangaID'];
    await _firestore
        .collection('Users')
        .doc(userId)
        .collection('UserNotes')
        .doc(mangaId)
        .set(userNotes, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> getAllUserNotesFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('Usuario no autenticado');
      return [];
    }

    final String userId = user.uid;

    try {
      final snapshot =
          await _firestore
              .collection('Users')
              .doc(userId)
              .collection('UserNotes')
              .get();

      return snapshot.docs
          .map((doc) => {'MangaID': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('Error al obtener las notas del usuario: $e');
      return [];
    }
  }

  Future<void> syncUserNotesWithFirestore() async {
    final db = DatabaseHelper.instance;
    final user = _auth.currentUser;
    if (user == null) {
      print('Usuario no autenticado');
      return;
    }

    final remoteProgressList = await getAllUserNotesFromFirestore();
    final localProgressList = await db.getAllLocalUserNotes();
    final localMangaIds = await db.getAllLocalMangaIDs();

    final Map<String, Map<String, dynamic>> localMap = {
      for (var p in localProgressList)
        if (p['MangaID'] != null) p['MangaID']: p,
    };

    final Map<String, Map<String, dynamic>> remoteMap = {
      for (var p in remoteProgressList)
        if (p['MangaID'] != null) p['MangaID']: p,
    };

    final Set<String> allMangaIDs = {...localMap.keys, ...remoteMap.keys};

    for (final mangaId in allMangaIDs) {
      final local = localMap[mangaId];
      final remote = remoteMap[mangaId];

      if (local == null && remote != null) {
        if (!localMangaIds.contains(mangaId)) {
          print('⚠️ Manga $mangaId no existe localmente. Ignorado.');
          continue;
        }
        await db.insertOrUpdateUserNoteMap(remote);
        print('Insertado desde Firestore a local: $mangaId');
      } else if (remote == null && local != null) {
        await insertUserNotesToFirestore(local);
        print('Insertado desde local a Firestore: $mangaId');
      } else if (local != null && remote != null) {
        final int localDate = local['LastEdited'] ?? 0;
        final int remoteDate = remote['LastEdited'] ?? 0;

        if (localDate > remoteDate) {
          await insertUserNotesToFirestore(local);
          print('Actualizado Firestore desde local: $mangaId');
        } else if (remoteDate > localDate) {
          await db.insertOrUpdateUserNoteMap(remote);
          print('Actualizado local desde Firestore: $mangaId');
        } else {
          print('Sin cambios para $mangaId');
        }
      }
    }

    print('✅ Sincronización de UserNotes completada.');
  }

  Future<void> updateMangaStatusInFirestore({
    required String mangaId,
    required int readingStatus,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('Usuario no autenticado');
      return;
    }
    final userId = user.uid;
    final int now = DateTime.now().millisecondsSinceEpoch;

    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('UserNotes')
          .doc(mangaId)
          .set({
            'ReadingStatus': readingStatus,
            'LastEdited': now,
          }, SetOptions(merge: true));

      print('✅ ReadingStatus actualizado en Firestore para $mangaId');
    } catch (e) {
      print('❌ Error al actualizar ReadingStatus en Firestore: $e');
    }
  }
}
