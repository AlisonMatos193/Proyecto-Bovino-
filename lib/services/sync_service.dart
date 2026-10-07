import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../db/app_database.dart';

/// Sincronización automática (patrón "outbox").
/// La app escribe en SQLite y encola el cambio en `sync_queue`. Al detectar red, se envía en orden.
class SyncService {
  SyncService._();
  static final instance = SyncService._();

  /// URL de tu API en la nube (PostgreSQL/MySQL detrás). Vacía = solo se acumula la cola.
  static const apiUrl = '';

  final pendientes = ValueNotifier<int>(0);
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _corriendo = false;

  void start() {
    _sub ??= Connectivity().onConnectivityChanged.listen((r) {
      if (!r.contains(ConnectivityResult.none)) sync();
    });
    refresh();
    sync();
  }

  Future<void> refresh() async {
    final db = await AppDatabase.instance.database;
    final r = await db.rawQuery('SELECT COUNT(*) AS n FROM sync_queue');
    pendientes.value = (r.first['n'] as int?) ?? 0;
  }

  Future<void> sync() async {
    if (_corriendo || apiUrl.isEmpty) return;
    _corriendo = true;
    try {
      final db = await AppDatabase.instance.database;
      final cola = await db.query('sync_queue', orderBy: 'id ASC', limit: 100);
      for (final fila in cola) {
        final ok = await _enviar(fila);
        if (!ok) {
          await db.rawUpdate('UPDATE sync_queue SET intentos = intentos + 1 WHERE id = ?', [fila['id']]);
          break; // sin conexión real: se reintenta luego, conservando el orden
        }
        await db.delete('sync_queue', where: 'id = ?', whereArgs: [fila['id']]);
      }
    } finally {
      _corriendo = false;
      await refresh();
    }
  }

  Future<bool> _enviar(Map<String, Object?> fila) async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      final req = await client.postUrl(Uri.parse('$apiUrl/sync'));
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        'tabla': fila['tabla'],
        'registro_id': fila['registro_id'],
        'operacion': fila['operacion'],
        'payload': jsonDecode(fila['payload'] as String),
        'created_at': fila['created_at'],
      }));
      final res = await req.close();
      client.close();
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
