import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Base de datos local (SQLite). Es la fuente de verdad: la app SIEMPRE lee y escribe aquí,
/// haya o no internet. La nube solo recibe copias mediante la cola de sincronización.
class AppDatabase {
  AppDatabase._();
  static final instance = AppDatabase._();

  Database? _db;
  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'catalogo_bovino.db');
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await _runScript(db, 'assets/db/schema.sql');
        if (kDebugMode) await _runScript(db, 'assets/db/seed.sql');
      },
      // Para cambios futuros del esquema: sube `version` y agrega migraciones aquí.
      onUpgrade: (db, oldVersion, newVersion) async {},
    );
  }

  Future<void> _runScript(Database db, String asset) async {
    final raw = await rootBundle.loadString(asset);
    final sinComentarios =
        raw.split('\n').where((l) => !l.trimLeft().startsWith('--')).join('\n');
    for (final stmt in sinComentarios.split(';')) {
      final s = stmt.trim();
      if (s.isNotEmpty) await db.execute(s);
    }
  }
}
