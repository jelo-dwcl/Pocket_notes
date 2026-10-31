import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'home_screen.dart';

class PocketNotesApp extends StatefulWidget {
  final bool initialDark;
  const PocketNotesApp({super.key, required this.initialDark});

  @override
  State<PocketNotesApp> createState() => _PocketNotesAppState();
}

class _PocketNotesAppState extends State<PocketNotesApp> {
  final _prefs = SharedPreferencesAsync();

  // Starts with the value that main() already read from disk.
  late bool _isDark = widget.initialDark;

  @override
  void initState() {
    super.initState();
    if (kExperimentFlash) _loadThemeLate();
  }

  /// Only used in Experiment 1: reads the theme AFTER the first frame.
  Future<void> _loadThemeLate() async {
    await Future.delayed(const Duration(seconds: 2));
    final saved = await _prefs.getBool('isDark') ?? false;
    if (!mounted) return;
    setState(() => _isDark = saved);
  }

  /// Called by the switch: update the screen now, then save the choice.
  Future<void> _setDark(bool value) async {
    setState(() => _isDark = value);
    await _prefs.setBool('isDark', value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Notes: Movies',
      debugShowCheckedModeBanner: false,
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      home: HomeScreen(isDark: _isDark, onThemeChanged: _setDark),
    );
  }
}