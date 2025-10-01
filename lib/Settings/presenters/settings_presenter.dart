import 'package:flutter/material.dart';
import 'package:yomuyomu/Settings/global_settings.dart';
import 'package:yomuyomu/DataBase/database_helper.dart';
import 'package:yomuyomu/Settings/models/settings_model.dart';

class SettingsPresenter extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  SettingsPresenter() {
    loadSettings();
  }

  SettingsModel? _settings;
  SettingsModel? get settings => _settings;

  String? _error;
  String? get error => _error;

  Future<void> loadSettings() async {
    try {
      final settingsMap = await _dbHelper.getUserSettingsById(userId);

      if (settingsMap != null) {
        _settings = SettingsModel.fromMap(settingsMap);
      } else {
        _settings = SettingsModel(
          userID: userId, 
          language: 0,
          theme: 0,
          orientation: 0,
        );
        await _dbHelper.insertUserSettings(_settings!.toMap());
      }

      _syncOrientationWithNotifier();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateSettings(SettingsModel newSettings) async {
    if (_settings == null) return;

    try {
      await _dbHelper.updateUserSettings(
        newSettings.toMap(),
        newSettings.userID,
      );
      _settings = newSettings;
      _syncOrientationWithNotifier();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> changeTheme(int newTheme) async {
    await _updateField(theme: newTheme);
  }

  Future<void> changeLanguage(int newLanguage) async {
    await _updateField(language: newLanguage);
  }

  Future<void> changeOrientation(int newOrientation) async {
    await _updateField(orientation: newOrientation);
  }

  Future<void> _updateField({
    int? theme,
    int? language,
    int? orientation,
  }) async {
    if (_settings == null) await loadSettings();
    if (_settings == null) return;

    final updated = SettingsModel(
      userID: _settings!.userID, 
      theme: theme ?? _settings!.theme,
      language: language ?? _settings!.language,
      orientation: orientation ?? _settings!.orientation,
    );

    await updateSettings(updated);
  }

  void _syncOrientationWithNotifier() {
    if (_settings == null) return;

    final axis = _settings!.orientation == 0 ? Axis.vertical : Axis.horizontal;
    if (userDirectionPreference.value != axis) {
      userDirectionPreference.value = axis;
    }
  }
}
