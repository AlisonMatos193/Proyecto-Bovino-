import 'package:flutter/material.dart';

import 'helpers.dart';
import '../data/repository.dart';
import '../models/models.dart';
import '../services/consanguinidad.dart';
import 'catalog_page.dart';



class _Opcion {
  final Bovino toro;
  final ResultadoCruza r;
  _Opcion(this.toro, this.r);
}

/// Módulo 3: Asesor genético. Se calcula en el teléfono con la genealogía local, sin internet.
class AdvisorPage extends StatefulWidget {
  const AdvisorPage({super.key});
  @override
  State<AdvisorPage> createState() => _AdvisorPageState();
}

class _AdvisorPageState extends State<AdvisorPage> {
  List<Bovino> _machos = [];
  List<Bovino> _hembras = [];
  Map<String, List<String?>> _ped = {};
  Bovino? _vaca;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final mio = await Repo.instance.miGanaderoId();
    final r = await Future.wait([
      Repo.instance.catalogo(sexo: 'M'),
      Repo.instance.catalogo(sexo: 'H', idGanadero: mio),
      Repo.instance.pedigree(),
    ]);
    if (!mounted) return;
    setState(() {
      _machos = r[0] as List<Bovino>;
      _hembras = r[1] as List<Bovino>;
      _ped = r[2] as Map<String, List<String?>>;
      _cargando = false;
    });
  }

  List<_Opcion> get _ranking {
    final v = _vaca;
    if (v == null) return [];
    final l = [
      for (final m in _machos) _Opcion(m, Consanguinidad.calcular(m.numeroSiniiga, v.numeroSiniiga, _ped)),
    ]..sort((a, b) => a.r.f.compareTo(b.r.f));
    return l;
  }

  Color _color(String riesgo) => switch (riesgo) {
        'Bajo' => Paleta.pasto,
        'Moderado' => Paleta.sol,
        _ => Paleta.alerta,
      };

  String _nombre(String id) {
    for (final b in [..._machos, ..._hembras]) {
      if (b.numeroSiniiga == id) return b.titulo;
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Asesor genético'), actions: const [SyncBadge()]),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              Text('Elige una hembra de tu rancho y verás qué sementales evitan la consanguinidad.', style: t.bodyMedium),
              const SizedBox(height: 12),
              DropdownButtonFormField<Bovino>(
                value: _vaca,
                decoration: const InputDecoration(labelText: 'Hembra a inseminar', filled: true, fillColor: Colors.white),
                items: [for (final h in _hembras) DropdownMenuItem(value: h, child: Text('${h.titulo} (${h.numeroSiniiga})'))],
                onChanged: (v) => setState(() => _vaca = v),
              ),
              const SizedBox(height: 16),
              if (_vaca == null && _hembras.isEmpty)
                const Text('Registra hembras en "Mi rancho" para usar el asesor.'),
              for (final o in _ranking)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      title: Text(o.toro.titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        '${o.toro.raza} · ${o.toro.rancho ?? ''}'
                        '${o.r.ancestrosComunes.isEmpty ? '\nSin ancestros en común' : '\nAncestros en común: ${o.r.ancestrosComunes.map(_nombre).join(', ')}'}',
                      ),
                      isThreeLine: true,
                      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('${o.r.porcentaje.toStringAsFixed(1)}%', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: _color(o.r.riesgo))),
                        Text(o.r.riesgo, style: t.labelSmall?.copyWith(color: _color(o.r.riesgo))),
                      ]),
                    ),
                  ),
                ),
              if (_vaca != null)
                Text(
                  'El porcentaje es la consanguinidad estimada de la cría (hasta 6 generaciones). '
                  'Es una guía simplificada: no sustituye la opinión de un zootecnista.',
                  style: t.bodySmall,
                ),
            ]),
    );
  }
}
