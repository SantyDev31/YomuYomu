import 'package:flutter/material.dart';

abstract class SettingsViewContract {
  void showLoading();
  void hideLoading();
  void showError(String message);
  void updateTheme(ThemeMode mode);
  void updateLanguage(String language);
  void updateReaderOrientation(Axis orientation);
}

