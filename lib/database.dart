import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'movie.dart';

/// The only class that talks to sqflite.
///
/// (Called AppDatabase because "Database" is already sqflite's own type.)
///
/// WHY THE DATABASE IS OPENED ONLY ONCE
///   Opening a database means finding the file, opening a connection to it and
///   checking that the table exists. That costs time, and every extra
///   connection to the same file is another handle that can get out of step
///   with the others (for example, two connections both trying to write, which
///   can give "database is locked" errors or reads that miss a fresh write).
///   One shared instance means one connection, one place to run onCreate, and
///   the same fast Database object for every insert, query, update and delete.
///
///   Two things make that happen here:
///     1. A private constructor plus one static instance, so nobody can create
///        a second AppDatabase.
///     2. We cache the Future (not the finished Database). If two parts of the
///        app ask for the database at the same moment, both get the SAME Future,
///        so _open() still runs only once.
class AppDatabase {
  AppDatabase._(); // private constructor: nobody else can make another one
  static final AppDatabase instance = AppDatabase._();

  static const String table = 'movies';

  // The cached Future. "??=" means: if it is still null, run _open() and store
  // the result; every later call just returns what was stored.
  static Future<Database>? _dbFuture;
  Future<Database> get database => _dbFuture ??= _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'pocket_notes.db');
    return openDatabase(
      path,
      version: 1,
      // Runs only the first time the file is created.
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE $table('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'title TEXT NOT NULL, '
          'rating INTEGER NOT NULL)',
        );
        // The first three records are samples.
        for (final m in const [
          Movie(title: 'Inception', rating: 9),
          Movie(title: 'Interstellar', rating: 8),
          Movie(title: 'The Room', rating: 3),
        ]) {
          await db.insert(table, m.toMap());
        }
      },
    );
  }

  /// Adds a movie. Returns the new row's id.
  Future<int> insert(Movie movie) async {
    final db = await database;
    return db.insert(table, movie.toMap());
  }

  /// Reads every movie, oldest first.
  Future<List<Movie>> getAll() async {
    final db = await database;
    final rows = await db.query(table, orderBy: 'id ASC');
    return rows.map(Movie.fromMap).toList();
  }

  /// Changes one movie. The "?" in where is filled from whereArgs, so the id is
  /// passed as a value and never glued into the SQL text.
  Future<int> update(Movie movie) async {
    final db = await database;
    return db.update(
      table,
      {'title': movie.title, 'rating': movie.rating},
      where: 'id = ?',
      whereArgs: [movie.id],
    );
  }

  /// Removes one movie, again with where + whereArgs.
  Future<int> delete(int id) async {
    final db = await database;
    return db.delete(
      table,
      where: 'id = ?', // <-- circle this for screenshot 8
      whereArgs: [id], // <-- and this
    );
  }

  /// For screenshot 7: prints the raw rows to the console.
  Future<void> printAll() async {
    final db = await database;
    debugPrint((await db.query(table)).toString());
  }
}