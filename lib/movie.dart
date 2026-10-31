/// One row of the movies table.
class Movie {
  /// Auto-increment primary key. It is null until the row is saved,
  /// because the database is the one that hands out the number.
  final int? id;
  final String title;

  /// A whole number from 1 to 10.
  final int rating;

  const Movie({this.id, required this.title, required this.rating});

  /// Movie -> Map, the shape sqflite wants when it writes a row.
  /// When id is null, SQLite picks the next id by itself (AUTOINCREMENT).
  Map<String, Object?> toMap() => {'id': id, 'title': title, 'rating': rating};

  /// Map -> Movie, used when rows are read back from the table.
  factory Movie.fromMap(Map<String, Object?> m) => Movie(
        id: m['id'] as int,
        title: m['title'] as String,
        rating: m['rating'] as int,
      );
}