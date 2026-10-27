import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart';

/// Null when SQLite works, otherwise the error. Since sqlite3 3.x the SQLite
/// library is added to the app by a build hook at build time (downloaded from
/// the package's GitHub release). If that step didn't run, every database call
/// fails; checking once at startup turns endless loading into a clear message.
String? sqliteProblem() {
  try {
    // Any call needs the native library; reading the version is the cheapest.
    sqlite3.version;
    return null;
  } on Object catch (e) {
    return '$e';
  }
}

/// Shown instead of the app when SQLite is missing from the build.
class SqliteMissingApp extends StatelessWidget {
  const SqliteMissingApp({super.key, required this.problem});

  final String problem;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Harga Toko',
    home: Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text(
              'Database di HP tidak bisa dibuka',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Aplikasi ini terpasang tanpa mesin database (SQLite), jadi '
              'tidak ada data yang bisa dibaca atau disimpan. Data lama di HP '
              'tidak hilang.\n\n'
              'Untuk pengembang: bangun ulang aplikasinya dengan '
              '"flutter clean", lalu "flutter run", di komputer yang bisa '
              'mengakses github.com.',
            ),
            const SizedBox(height: 16),
            SelectableText(
              problem,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}
