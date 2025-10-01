import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yomuyomu/Settings/presenters/settings_presenter.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});
  
  @override
  Widget build(BuildContext context) {
    final presenter = context.watch<SettingsPresenter>();
    final settings = presenter.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  _buildThemeSection(context, presenter),
                  const SizedBox(height: 20),
                  _buildLanguageSection(context, presenter),
                  const SizedBox(height: 20),
                  _buildOrientationSection(context, presenter),
                ],
              ),
            ),
    );
  }

  Widget _buildThemeSection(BuildContext context, SettingsPresenter presenter) {
    final currentTheme = _mapThemeFromInt(presenter.settings!.theme);
    return _buildSection(
      title: 'Theme',
      child: Wrap(
        spacing: 8,
        children: [
          _buildThemeButton(presenter, ThemeMode.system, 'System', currentTheme),
          _buildThemeButton(presenter, ThemeMode.light, 'Light', currentTheme),
          _buildThemeButton(presenter, ThemeMode.dark, 'Dark', currentTheme),
        ],
      ),
    );
  }

  Widget _buildLanguageSection(BuildContext context, SettingsPresenter presenter) {
    const availableLanguages = ['English', 'Español', '日本語'];
    final currentLang = availableLanguages[presenter.settings!.language];

    return _buildSection(
      title: 'Language',
      child: DropdownButton<String>(
        value: currentLang,
        onChanged: (value) {
          if (value != null) {
            final index = availableLanguages.indexOf(value);
            if (index != -1) {
              presenter.changeLanguage(index);
            }
          }
        },
        items: availableLanguages
            .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
            .toList(),
      ),
    );
  }

  Widget _buildOrientationSection(BuildContext context, SettingsPresenter presenter) {
    final current = _mapOrientationFromInt(presenter.settings!.orientation);

    return _buildSection(
      title: 'Reader Orientation',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildOrientationButton(presenter, Axis.vertical, Icons.swap_vert, 'Vertical', current),
          _buildOrientationButton(presenter, Axis.horizontal, Icons.swap_horiz, 'Horizontal', current),
        ],
      ),
    );
  }

  Widget _buildThemeButton(SettingsPresenter presenter, ThemeMode mode, String label, ThemeMode current) {
    final isSelected = current == mode;

    return ElevatedButton(
      onPressed: () {
        presenter.changeTheme(_mapThemeToInt(mode));
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }

  Widget _buildOrientationButton(SettingsPresenter presenter, Axis axis, IconData icon, String label, Axis current) {
    final isSelected = current == axis;

    return GestureDetector(
      onTap: () {
        presenter.changeOrientation(_mapOrientationToInt(axis));
      },
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: isSelected ? Colors.blue : Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            width: 80,
            height: 120,
            child: Icon(icon, size: 50),
          ),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  ThemeMode _mapThemeFromInt(int value) {
    switch (value) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  int _mapThemeToInt(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 1;
      case ThemeMode.dark:
        return 2;
      default:
        return 0;
    }
  }

  Axis _mapOrientationFromInt(int value) {
    return value == 1 ? Axis.horizontal : Axis.vertical;
  }

  int _mapOrientationToInt(Axis axis) {
    return axis == Axis.horizontal ? 1 : 0;
  }
}
