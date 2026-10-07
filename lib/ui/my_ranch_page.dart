import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../models/models.dart';
import 'bovino_detail_page.dart';
import 'bovino_form_page.dart';
import 'catalog_page.dart';

/// Módulo 2: Administración e IATF (registro del hato, todo offline).
class MyRanchPage extends StatefulWidget {
  const MyRanchPage({super.key});
  @override
  State<MyRanchPage> createState() => _MyRanchPageState();
}

class _MyRanchPageState extends State<MyRanchPage> {
  late Future<List<Bovino>> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _futuro = () async {
      final id = await Repo.instance.miGanaderoId();
      return Repo.instance.catalogo(idGanadero: id);
    }();
  }

  Future<void> _nuevo() async {
    final id = await Repo.instance.miGanaderoId();
    if (!mounted) return;
    final creado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => BovinoFormPage(idGanadero: id)),
    );
    if (creado == true) setState(_cargar);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mi rancho'), actions: const [SyncBadge()]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _nuevo,
          icon: const Icon(Icons.add),
          label: const Text('Registrar bovino'),
        ),
        body: FutureBuilder<List<Bovino>>(
          future: _futuro,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final lista = snap.data ?? [];
            if (lista.isEmpty) {
              return const Center(child: Text('Aún no tienes animales. Toca "Registrar bovino".'));
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              itemCount: lista.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => BovinoCard(
                b: lista[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BovinoDetailPage(b: lista[i], editable: true)),
                ).then((_) => setState(_cargar)),
              ),
            );
          },
        ),
      );
}
