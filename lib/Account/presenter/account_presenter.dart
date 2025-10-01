import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:yomuyomu/Account/contracts/account_contract.dart';
import 'package:yomuyomu/Account/model/account_model.dart';
import 'package:yomuyomu/DataBase/database_helper.dart';
import 'package:yomuyomu/Mangas/enums/reading_status.dart';
import 'package:yomuyomu/Mangas/models/usernote_model.dart';
import 'package:yomuyomu/Settings/global_settings.dart';

class AccountPresenter implements AccountPresenterContract {
  final AccountViewContract _view;
  final DatabaseHelper _db = DatabaseHelper();
  StreamSubscription<User?>? _authSubscription;

  AccountPresenter(this._view) {
    _getUserAccountWithNotesAndCovers();
  }

  void initSessionListener() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) async {
      await loadUserData();
    });
  }

  @override
  Future<void> loadUserData() async {
    try {
      _view.showLoading();

      await _getUserAccountWithNotesAndCovers();
    } catch (e) {
      _view.showError('Error cargando datos del usuario: $e');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> _getUserAccountWithNotesAndCovers() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    Map<String, dynamic>? userMap;
    String email = 'local@local.a';
    String username = 'local';

    if (firebaseUser != null &&
        firebaseUser.email != null &&
        _isValidEmail(firebaseUser.email!)) {
      email = firebaseUser.email!;
      username = firebaseUser.displayName ?? 'local';

      userMap = await _db.getUserByEmail(email);

      if (userMap == null) {
        await saveUserToDatabase(username, email);
        userMap = await _db.getUserByEmail(email);
      }
    }

    userMap ??= {
      'UserID': userId,
      'Username': username,
      'Email': email,
      'Icon': 'default_user_pfp.png',
      'CreationDate': DateTime.now().millisecondsSinceEpoch,
    };

    _view.updateAccount(await _buildAccountModel(userMap));
  }

  Future<AccountModel> _buildAccountModel(Map<String, dynamic> userMap) async {
    final List<UserNote> notes = await _db.getUserNotes(userId);
    final List<String> favoritedCovers = await _db.getFavoriteMangaCovers(
      userId,
    );
    final int finishedCount =
        notes
            .where((note) => note.readingStatus == ReadingStatus.completed)
            .length;

    return AccountModel.fromMap(
      userMap,
      favoriteMangaCovers: favoritedCovers,
      finishedMangasCount: finishedCount,
    );
  }

  @override
  Future<void> saveUserToDatabase(String username, String email) async {
    final user = AccountModel(
      userID: userId,
      username: username,
      email: email,
      icon: 'default_user_pfp.png',
      creationDate: DateTime.now(),
    );

    await _db.insertUser(user.toMap());
  }

  @override
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    

    _view.updateAccount(null);
    _view.showError("Sesión cerrada.");
  }

  bool _isValidEmail(String email) {
    const invalidDomains = ['local.a'];
    final regex = RegExp(r'^[\w\.-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
    final domain = email.split('@').last;
    return regex.hasMatch(email) && !invalidDomains.contains(domain);
  }

  void dispose() {
    _authSubscription?.cancel();
  }
}
