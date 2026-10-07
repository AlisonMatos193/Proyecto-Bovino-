import 'helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';


import '../data/repository.dart';
import '../models/models.dart';

final _fecha = DateFormat('dd/MM/yyyy');
String _f(String? iso) => iso == null ? '—' : _fecha.format(DateTime.parse(iso));

class BovinoDetailPage extends StatefulWidget {
  final Bovino b;
  final bool editable; // true = animal de mi rancho (puede registrar eventos y publicar)
  const BovinoDetailPage({super.key, required this.b, required this.editable});
  @override
  State<BovinoDetailPage> createState() => _BovinoDetailPageState();
}

class _BovinoDetailPageState extends State<BovinoDetailPage> {
  late Future<List<EventoClinico>> _eventos;

  @override
  void initState() {
    super.initState();
    _eventos = Repo.instance.eventos(widget.b.numeroSiniiga);
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.b;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(b.titulo)),
      floatingActionButton: widget.editable
          ? FloatingActionButton.extended(
              onPressed: _nuevoEvento,
              icon: const Icon(Icons.event_note),
              label: const Text('Registrar evento'),
            )
          : null,
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
        BovinoFoto(path: b.fotoPath, size: double.infinity, height: 220),
        const SizedBox(height: 16),
        Text('SINIIGA ${b.numeroSiniiga}', style: t.titleMedium),
Text("Consultar precio", style: t.headlineSmall?.copyWith(color: Paleta.tierra, fontWeight: FontWeight.w800)),
        if (b.descripcion != null) ...[const SizedBox(height: 8), Text(b.descripcion!)],
        _seccion('Datos', [
          _fila('Raza', b.raza),
          _fila('Sexo', b.sexo == 'M' ? 'Macho' : 'Hembra'),
          _fila('Categoría', categorias[b.categoria] ?? b.categoria),
          _fila('Propósito', b.proposito ?? '—'),
          _fila('Peso', b.peso == null ? '—' : '${b.peso!.toStringAsFixed(0)} kg'),
          _fila('Nacimiento', _f(b.fechaNacimiento)),
        ]),
        _seccion('Genealogía', [
          _fila('Padre', '${b.nombrePadre ?? 'Sin registro'}${b.siniigaPadre != null ? '  (${b.siniigaPadre})' : ''}'),
          _fila('Madre', '${b.nombreMadre ?? 'Sin registro'}${b.siniigaMadre != null ? '  (${b.siniigaMadre})' : ''}'),
          _fila('Pureza', b.pureza == null ? '—' : '${b.pureza}%'),
        ]),
        _seccion('Propietario', [
          _fila('Ganadero', b.ganadero ?? '—'),
          _fila('Rancho', b.rancho ?? '—'),
          _fila('Teléfono', b.telefono ?? '—'),
        ]),
        if (!widget.editable && b.telefono != null && b.telefono!.isNotEmpty)
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: b.telefono!));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teléfono copiado')));
              }
            },
            icon: const Icon(Icons.phone),
            label: const Text('Copiar teléfono del rancho'),
          ),
        if (widget.editable)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              onPressed: _publicar,
              icon: const Icon(Icons.sell_outlined),
              label: const Text('Publicar en la vitrina'),
            ),
          ),
        _seccion('Historial clínico e IATF', [
          FutureBuilder<List<EventoClinico>>(
            future: _eventos,
            builder: (_, snap) {
              final l = snap.data ?? [];
              if (snap.connectionState != ConnectionState.done) return const LinearProgressIndicator();
              if (l.isEmpty) return const Text('Sin eventos registrados.');
              return Column(children: [
                for (final e in l)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${e.tipo} · ${_f(e.fecha)}'),
                    subtitle: Text([
                      if (e.protocoloHormonal != null) 'Protocolo: ${e.protocoloHormonal}',
                      if (e.notas != null) e.notas!,
                      if (e.fechaProxima != null) 'Próxima: ${_f(e.fechaProxima)}',
                    ].join('\n')),
                  ),
              ]);
            },
          ),
        ]),
      ]),
    );
  }

  Widget _seccion(String titulo, List<Widget> hijos) => Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: Paleta.pasto)),
          const Divider(),
          ...hijos,
        ]),
      );

  Widget _fila(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 110, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(v)),
        ]),
      );

  Future<void> _nuevoEvento() async {
    final guardado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EventoSheet(numero: widget.b.numeroSiniiga),
    );
    if (guardado == true) setState(() => _eventos = Repo.instance.eventos(widget.b.numeroSiniiga));
  }

  Future<void> _publicar() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PublicarSheet(numero: widget.b.numeroSiniiga),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Publicado en la vitrina')));
    }
  }
}

EdgeInsets _sheetPadding(BuildContext c) =>
    EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(c).viewInsets.bottom);

class _EventoSheet extends StatefulWidget {
  final String numero;
  const _EventoSheet({required this.numero});
  @override
  State<_EventoSheet> createState() => _EventoSheetState();
}

class _EventoSheetState extends State<_EventoSheet> {
  String _tipo = tiposEvento.first;
  DateTime _fecha = DateTime.now();
  DateTime? _proxima;
  final _protocolo = TextEditingController();
  final _notas = TextEditingController();

  Future<DateTime?> _elegir(DateTime inicial) => showDatePicker(
        context: context,
        initialDate: inicial,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: _sheetPadding(context),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Nuevo evento', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _tipo,
            decoration: const InputDecoration(labelText: 'Tipo de evento'),
            items: [for (final e in tiposEvento) DropdownMenuItem(value: e, child: Text(e))],
            onChanged: (v) => setState(() => _tipo = v!),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              final d = await _elegir(_fecha);
              if (d != null) setState(() => _fecha = d);
            },
            child: Text('Fecha: ${_fecha.day}/${_fecha.month}/${_fecha.year}'),
          ),
          const SizedBox(height: 12),
          if (_tipo == 'IATF') ...[
            TextField(controller: _protocolo, decoration: const InputDecoration(labelText: 'Protocolo hormonal')),
            const SizedBox(height: 12),
          ],
          TextField(controller: _notas, decoration: const InputDecoration(labelText: 'Notas'), maxLines: 2),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              final d = await _elegir(_proxima ?? _fecha.add(const Duration(days: 30)));
              if (d != null) setState(() => _proxima = d);
            },
            child: Text(_proxima == null ? 'Programar próxima fecha (opcional)' : 'Próxima: ${_proxima!.day}/${_proxima!.month}/${_proxima!.year}'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              await Repo.instance.agregarEvento(EventoClinico(
                id: newId(),
                numeroSiniiga: widget.numero,
                fecha: _fecha.toIso8601String(),
                tipo: _tipo,
                protocoloHormonal: _protocolo.text.trim().isEmpty ? null : _protocolo.text.trim(),
                notas: _notas.text.trim().isEmpty ? null : _notas.text.trim(),
                fechaProxima: _proxima?.toIso8601String(),
              ));
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Guardar evento'),
          ),
        ]),
      );
}

class _PublicarSheet extends StatefulWidget {
  final String numero;
  const _PublicarSheet({required this.numero});
  @override
  State<_PublicarSheet> createState() => _PublicarSheetState();
}

class _PublicarSheetState extends State<_PublicarSheet> {
  String _tipo = 'animal';
  final _min = TextEditingController();
  final _max = TextEditingController();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: _sheetPadding(context),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Publicar en la vitrina', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _tipo,
            decoration: const InputDecoration(labelText: 'Qué vendes'),
            items: [for (final e in tiposVenta.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: (v) => setState(() => _tipo = v!),
          ),
          const SizedBox(height: 12),
          TextField(controller: _min, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio mínimo (MXN)')),
          const SizedBox(height: 12),
          TextField(controller: _max, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio máximo (opcional)')),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final min = double.tryParse(_min.text.trim());
              final max = double.tryParse(_max.text.trim());
              if (min == null || (max != null && max < min)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Revisa los precios: el máximo no puede ser menor que el mínimo.')),
                );
                return;
              }
              await Repo.instance.publicar(numeroSiniiga: widget.numero, tipoVenta: _tipo, precioMin: min, precioMax: max);
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Publicar'),
          ),
        ]),
      );
}
