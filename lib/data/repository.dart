import 'dart:convert';
import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/models.dart';
import '../services/sync_service.dart';

String _now() => DateTime.now().toIso8601String();
String newId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${Random().nextInt(1 << 31).toRadixString(36)}';

/// Todas las lecturas/escrituras pasan por aquí. Cada escritura también encola el cambio para la nube.
class Repo {
  Repo._();
  static final instance = Repo._();

  Future<Database> get _db => AppDatabase.instance.database;

  static const _select = '''
SELECT b.*, g.nombre AS ganadero, g.rancho AS rancho, g.telefono AS telefono,
       l.siniiga_padre, l.nombre_padre, l.siniiga_madre, l.nombre_madre,
       l.porcentaje_pureza AS pureza,
       (SELECT MIN(pm.precio_min) FROM productos_marketplace pm
         WHERE pm.numero_siniiga = b.numero_siniiga AND pm.activo = 1) AS precio_min,
       (SELECT MAX(COALESCE(pm.precio_max, pm.precio_min)) FROM productos_marketplace pm
         WHERE pm.numero_siniiga = b.numero_siniiga AND pm.activo = 1) AS precio_max
FROM bovinos b
JOIN ganaderos g ON g.id_ganadero = b.id_ganadero
LEFT JOIN linajes_genealogia l ON l.numero_siniiga = b.numero_siniiga
''';

  // ---------- Ganadero de este teléfono ----------
  Future<String> miGanaderoId() async {
    final db = await _db;
    final r = await db.query('ganaderos', columns: ['id_ganadero'], orderBy: 'updated_at ASC', limit: 1);
    if (r.isNotEmpty) return r.first['id_ganadero'] as String;
    final id = newId();
    final row = {
      'id_ganadero': id,
      'nombre': 'Mi perfil',
      'rancho': 'Mi rancho',
      'municipio': 'Tizimín',
      'updated_at': _now(),
    };
    await db.transaction((tx) async {
      await tx.insert('ganaderos', row);
      await _enqueue(tx, 'ganaderos', id, 'insert', row);
    });
    return id;
  }

  // ---------- Catálogo ----------
  Future<List<Bovino>> catalogo({
    String? q,
    String? sexo,
    String? raza,
    bool soloVenta = false,
    String? idGanadero,
  }) async {
    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];
    if (q != null && q.trim().isNotEmpty) {
      where.add('(b.nombre LIKE ? OR b.numero_siniiga LIKE ? OR b.raza LIKE ?)');
      final like = '%${q.trim()}%';
      args.addAll([like, like, like]);
    }
    if (sexo != null) {
      where.add('b.sexo = ?');
      args.add(sexo);
    }
    if (raza != null) {
      where.add('b.raza = ?');
      args.add(raza);
    }
    if (idGanadero != null) {
      where.add('b.id_ganadero = ?');
      args.add(idGanadero);
    }
    if (soloVenta) {
      where.add('EXISTS (SELECT 1 FROM productos_marketplace pm '
          'WHERE pm.numero_siniiga = b.numero_siniiga AND pm.activo = 1)');
    }
    final sql = '$_select ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'} ORDER BY b.nombre COLLATE NOCASE';
    final rows = await db.rawQuery(sql, args);
    return rows.map(Bovino.fromMap).toList();
  }

  // ---------- Registro de bovinos ----------
  /// Lanza [DatabaseException] si el número SINIIGA ya existe.
  Future<void> guardarBovino(
    Bovino b, {
    String? siniigaPadre,
    String? nombrePadre,
    String? siniigaMadre,
    String? nombreMadre,
    double? pureza,
  }) async {
    final db = await _db;
    final ahora = _now();
    final base = {...b.toMap(), 'created_at': ahora, 'updated_at': ahora};
    final linaje = {
      'id_linaje': newId(),
      'numero_siniiga': b.numeroSiniiga,
      'siniiga_padre': _vacioANull(siniigaPadre),
      'nombre_padre': _vacioANull(nombrePadre),
      'siniiga_madre': _vacioANull(siniigaMadre),
      'nombre_madre': _vacioANull(nombreMadre),
      'porcentaje_pureza': pureza,
      'updated_at': ahora,
    };
    await db.transaction((tx) async {
      await tx.insert('bovinos', base);
      await tx.insert('linajes_genealogia', linaje);
      await _enqueue(tx, 'bovinos', b.numeroSiniiga, 'insert', base);
      await _enqueue(tx, 'linajes_genealogia', linaje['id_linaje'] as String, 'insert', linaje);
    });
    await SyncService.instance.refresh();
  }

  // ---------- Historial clínico / IATF ----------
  Future<List<EventoClinico>> eventos(String numeroSiniiga) async {
    final db = await _db;
    final r = await db.query('historial_clinico',
        where: 'numero_siniiga = ?', whereArgs: [numeroSiniiga], orderBy: 'fecha DESC');
    return r.map(EventoClinico.fromMap).toList();
  }

  Future<void> agregarEvento(EventoClinico e) async {
    final db = await _db;
    final row = {...e.toMap(), 'updated_at': _now()};
    await db.transaction((tx) async {
      await tx.insert('historial_clinico', row);
      await _enqueue(tx, 'historial_clinico', e.id, 'insert', row);
    });
    await SyncService.instance.refresh();
  }

  // ---------- Marketplace ----------
  Future<void> publicar({
    required String numeroSiniiga,
    required String tipoVenta,
    required double precioMin,
    double? precioMax,
  }) async {
    final db = await _db;
    final id = newId();
    final row = {
      'id_producto': id,
      'numero_siniiga': numeroSiniiga,
      'tipo_venta': tipoVenta,
      'precio_min': precioMin,
      'precio_max': precioMax,
      'activo': 1,
      'updated_at': _now(),
    };
    await db.transaction((tx) async {
      await tx.insert('productos_marketplace', row);
      await _enqueue(tx, 'productos_marketplace', id, 'insert', row);
    });
    await SyncService.instance.refresh();
  }

  // ---------- Genealogía completa para el asesor genético ----------
  Future<Map<String, List<String?>>> pedigree() async {
    final db = await _db;
    final r = await db.query('linajes_genealogia',
        columns: ['numero_siniiga', 'siniiga_padre', 'siniiga_madre']);
    return {
      for (final f in r)
        f['numero_siniiga'] as String: [f['siniiga_padre'] as String?, f['siniiga_madre'] as String?],
    };
  }

  // ---------- Utilidades ----------
  Future<void> _enqueue(DatabaseExecutor tx, String tabla, String id, String op, Map<String, Object?> payload) =>
      tx.insert('sync_queue', {
        'tabla': tabla,
        'registro_id': id,
        'operacion': op,
        'payload': jsonEncode(payload),
        'created_at': _now(),
      });

  String? _vacioANull(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
}
