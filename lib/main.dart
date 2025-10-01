import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:yomuyomu/DataBase/firebase_helper.dart';

import 'package:yomuyomu/Settings/global_settings.dart';
import 'package:yomuyomu/firebase_options.dart';
import 'package:yomuyomu/DataBase/database_helper.dart';
import 'package:yomuyomu/DataBase/insert_base_data.dart';
import 'package:yomuyomu/Account/views/account_view.dart';
import 'package:yomuyomu/Mangas/views/library_view.dart';
import 'package:yomuyomu/Settings/views/settings_view.dart';
import 'package:yomuyomu/Settings/presenters/settings_presenter.dart';

import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    try {
      print('🖥️ Inicializando sqflite_common_ffi para escritorio...');
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      print('✅ sqflite_common_ffi inicializado.');
    } catch (e, st) {
      print('❌ Error al inicializar sqflite_common_ffi: $e');
      print(st);
    }
  }

  try {
    // print('Borrando base de datos (si existe)');
    // await DatabaseHelper.instance.deleteDatabaseFile();
    // print('Base de datos borrada');

    print('📝 Insertando datos de muestra...');
    await insertBaseData();
    print('✅ Datos de muestra insertados.');

    print('📂 Abriendo base de datos...');
    await DatabaseHelper.instance.database;
    print('✅ Base de datos abierta.');
  } catch (e, st) {
    print('❌ Error durante la inicialización de base de datos: $e');
    print(st);
  }

  try {
    print('🔄 Inicializando Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      await FirebaseAuth.instance
          .authStateChanges()
          .firstWhere((user) => user != null)
          .timeout(const Duration(milliseconds: 500));
      print('✅ Firebase inicializado correctamente.');
      FirebaseService().syncUserProgressWithFirestore();
      FirebaseService().syncUserNotesWithFirestore();
    } catch (_) {
      print('❌ Firebase timeouteado.');
    }
  } catch (e, st) {
    print('❌ Error al inicializar Firebase: $e');
    print(st);
    return;
  }

  print('🚀 Ejecutando la aplicación...');
  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsPresenter(),
      child: const AppRoot(),
    ),
  );
}

Future<void> updateThemePreference(ThemeMode mode) async {
  final preferences = await SharedPreferences.getInstance();
  await preferences.setString('theme_mode', _getThemePreferenceString(mode));
  appThemeMode.value = mode;
}

String _getThemePreferenceString(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    default:
      return 'system';
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsPresenter>(
      builder: (context, presenter, _) {
        final settings = presenter.settings;
        final error = presenter.error;

        if (error != null) {
          print('❌ Error cargando ajustes: $error');
        }

        if (settings == null) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        final themeMode = _mapThemeFromInt(settings.theme);

        return MaterialApp(
          title: 'Manga Reader',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeMode,
          home: const MainNavigationScreen(),
        );
      },
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
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int currentIndex = 0;

  final List<String> screenTitles = const [
    "Library",
    "History",
    "Favorite",
    "Account",
    "Settings",
  ];

  void onNavItemSelected(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  Widget _getCurrentScreenView() {
    switch (currentIndex) {
      case 0:
        return LibraryView(key: const ValueKey("library_0"), viewMode: 0);
      case 1:
        return LibraryView(key: const ValueKey("library_1"), viewMode: 1);
      case 2:
        return LibraryView(key: const ValueKey("library_2"), viewMode: 2);
      case 3:
        return const AccountView();
      case 4:
        return const SettingsView();
      default:
        return const SizedBox();
    }
  }

  Widget _buildNavigationDrawer(BuildContext context, bool isWideScreen) {
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onNavItemSelected,
      labelType: NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.library_books),
          label: Text('Library'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.history),
          label: Text('History'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.star),
          label: Text('Favorite'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.account_circle),
          label: Text('Account'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
    );
  }

  Icon _getIconForScreen(int index) {
    switch (index) {
      case 0:
        return const Icon(Icons.library_books);
      case 1:
        return const Icon(Icons.history);
      case 2:
        return const Icon(Icons.star);
      case 3:
        return const Icon(Icons.account_circle);
      case 4:
      default:
        return const Icon(Icons.settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWideScreen = constraints.maxWidth >= 600;

        return Scaffold(
          appBar: AppBar(
            title: Text(screenTitles[currentIndex]),
            leading:
                isWideScreen
                    ? null
                    : Builder(
                      builder:
                          (context) => IconButton(
                            icon: const Icon(Icons.menu),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                    ),
          ),
          drawer:
              isWideScreen
                  ? null
                  : Drawer(
                    child: ListView(
                      children: [
                        for (int i = 0; i < screenTitles.length; i++)
                          ListTile(
                            title: Text(screenTitles[i]),
                            leading: _getIconForScreen(i),
                            selected: currentIndex == i,
                            onTap: () {
                              onNavItemSelected(i);
                              Navigator.pop(context);
                            },
                          ),
                      ],
                    ),
                  ),
          body: Row(
            children: [
              if (isWideScreen) _buildNavigationDrawer(context, true),
              Expanded(child: _getCurrentScreenView()),
            ],
          ),
        );
      },
    );
  }
}
