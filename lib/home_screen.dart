import 'package:flutter/material.dart';

import 'database.dart';
import 'movie.dart';

class HomeScreen extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onThemeChanged;
  const HomeScreen({
    super.key,
    required this.isDark,
    required this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // The one shared database instance (see database.dart).
  final _db = AppDatabase.instance;

  List<Movie> _movies = [];
  bool _loading = true;

  // EXPERIMENT 2: this chip's value is a plain variable in this State object.
  // It lives only in RAM and is never saved, so a force-kill resets it to false.
  bool _topRatedOnly = false;

  @override
  void initState() {
    super.initState();
    _load(); // load the saved movies from the table when the app launches
  }

  Future<void> _load() async {
    final rows = await _db.getAll();
    if (!mounted) return;
    setState(() {
      _movies = rows;
      _loading = false;
    });
  }

  /// One dialog for both Add (existing == null) and Edit (existing != null).
  Future<void> _showForm({Movie? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final ratingCtrl =
        TextEditingController(text: existing?.rating.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add movie' : 'Edit movie'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: ratingCtrl,
                decoration: const InputDecoration(labelText: 'Rating (1 to 10)'),
                keyboardType: TextInputType.number,
                // The rating must be a whole number from 1 to 10.
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return (n == null || n < 1 || n > 10)
                      ? 'Enter a number from 1 to 10'
                      : null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // Only close the dialog with "true" when both fields are valid.
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true) return; // Cancel, or tapped outside the dialog

    final movie = Movie(
      id: existing?.id, // keeps the same id when editing; null when adding
      title: titleCtrl.text.trim(),
      rating: int.parse(ratingCtrl.text),
    );
    if (existing == null) {
      await _db.insert(movie);
    } else {
      await _db.update(movie);
    }
    await _load(); // re-read the table so the list matches the database
  }

  Future<void> _delete(Movie movie) async {
    await _db.delete(movie.id!);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // The chip only changes what is SHOWN. The table still holds every movie.
    final shown =
        _topRatedOnly ? _movies.where((m) => m.rating >= 8).toList() : _movies;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surfaceContainer,
        title: const Text(
          'MOVIES',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        actions: [
          // For screenshot 7: prints the table rows to the console.
          IconButton(
            tooltip: 'Print DB rows to console',
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: _db.printAll,
          ),
          const Icon(Icons.light_mode_outlined),
          Switch(value: widget.isDark, onChanged: widget.onThemeChanged),
          const Icon(Icons.dark_mode_outlined),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FilterChip(
                label: const Text('8+ rating only'),
                selected: _topRatedOnly,
                onSelected: (v) => setState(() => _topRatedOnly = v),
              ),
              Text('${shown.length} ${shown.length == 1 ? 'record' : 'records'}'),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (shown.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text('No records yet. Tap + to add.')),
            )
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (int i = 0; i < shown.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
                      title: Text(shown[i].title),
                      subtitle: Text('Rating: ${shown[i].rating}/10'),
                      onTap: () => _showForm(existing: shown[i]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(shown[i]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}