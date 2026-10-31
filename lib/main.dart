// Pocket Notes: Movies
//
// Setup:  flutter pub add shared_preferences sqflite path
//
// Where each piece of data lives
//   theme            -> SharedPreferences (one small true/false setting, on disk)
//   movies           -> sqflite database file pocket_notes.db (rows, on disk)
//   "8+ only" chip   -> a plain variable inside a State object (RAM only)
//

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'config.dart';

Future<void> main() async {
  // Needed because we use plugins (shared_preferences, sqflite) before runApp().
  WidgetsFlutterBinding.ensureInitialized();

  // Read the saved theme FIRST, then draw the app, so the first frame already
  // has the right theme. "?? false" = light theme on the first launch.
  final isDark = kExperimentFlash
      ? false
      : (await SharedPreferencesAsync().getBool('isDark') ?? false);

  runApp(PocketNotesApp(initialDark: isDark));
}