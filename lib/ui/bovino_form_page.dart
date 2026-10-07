import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../data/repository.dart';
import '../models/models.dart';


class BovinoFormPage extends StatefulWidget {
  final String idGanadero;
  const BovinoFormPage({super.key, required this.idGanadero});
  @override
  State<BovinoFormPage> createState() => _BovinoFormPageState();
}

class _BovinoFormPageState extends State<BovinoFormPage> {
  final _form = GlobalKey<FormState>();
  final _siniiga = TextEditingController();
  final _nombre = TextEditingController();
  final _raza = TextEditingController();
  final _proposito = TextEditingController(text: 'Carne');
  final _peso = TextEditingController();
  final _descripcion = TextEditingController();
  final _padreId = TextEditingController();
  final _padreNombre = TextEditingController();
  final _madreId = TextEditingController();
  final _madreNombre = TextEditingController();
  final _pureza = TextEditingController();
  String _sexo = 'H';
  String _categoria = 'novilla';
  DateTime? _nacimiento;
  String? _fotoPath;
  bool _guardando = false;

  Future<void> _elegirFoto() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1280, imageQuality: 80);
    if (x == null) return;
    final dir = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'fotos'));
    await dir.create(recursive: true);
    final nombre = '${DateTime.now().millisecondsSinceEpoch}${p.extension(x.path)}';
    final destino = p.join(dir.path, nombre);
    await File(x.path).copy(destino);
    setState(() => _fotoPath = destino);
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await Repo.instance.guardarBovino(
        Bovino(
          numeroSiniiga: _siniiga.text.trim(),
          nombre: _nombre.text.trim().isEmpty ? null : _nombre.text.trim(),
          raza: _raza.text.trim(),
          sexo: _sexo,
          categoria: _categoria,
          proposito: _proposito.text.trim().isEmpty ? null : _proposito.text.trim(),
          peso: double.tryParse(_peso.text.trim()),
          fechaNacimiento: _nacimiento?.toIso8601String(),
          fotoPath: _fotoPath,
          descripcion: _descripcion.text.trim().isEmpty ? null : _descripcion.text.trim(),
          idGanadero: widget.idGanadero,
        ),
        siniigaPadre: _padreId.text,
        nombrePadre: _padreNombre.text,
        siniigaMadre: _madreId.text,
        nombreMadre: _madreNombre.text,
        pureza: double.tryParse(_pureza.text.trim()),
      );
      if (mounted) Navigator.pop(context, true);
    } on DatabaseException catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      final duplicado = e.isUniqueConstraintError();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(duplicado ? 'Ese número SINIIGA ya está registrado.' : 'No se pudo guardar. Intenta de nuevo.'),
      ));
    }
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;

  Widget _sep() => const SizedBox(height: 12);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Registrar bovino')),
        body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(16), children: [
         GestureDetector(
              onTap: _elegirFoto,
              child: Stack(alignment: Alignment.bottomRight, children: [
                // Nuevo contenedor inteligente de fotos locales
                Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8CDB4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _fotoPath != null && _fotoPath!.isNotEmpty
                      ? Image.file(
                          File(_fotoPath!),
                          fit: BoxFit.cover,
                        )
                      : const Center(child: Icon(Icons.pets, size: 60, color: Colors.white)),
                ),
                // Botón de la camarita
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: Color(0xFF1F3A2E), 
                    child: Icon(Icons.photo_camera_outlined, color: Colors.white)
                  ),
                ),
              ]),
            ),
            _sep(),
            TextFormField(
              controller: _siniiga,
              decoration: const InputDecoration(labelText: 'Número SINIIGA (arete)'),
              keyboardType: TextInputType.number,
              validator: _req,
            ),
            _sep(),
            TextFormField(controller: _nombre, decoration: const InputDecoration(labelText: 'Nombre (opcional)')),
            _sep(),
            TextFormField(controller: _raza, decoration: const InputDecoration(labelText: 'Raza'), validator: _req),
            _sep(),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'H', label: Text('Hembra')),
                ButtonSegment(value: 'M', label: Text('Macho')),
              ],
              selected: {_sexo},
              onSelectionChanged: (s) => setState(() => _sexo = s.first),
            ),
            _sep(),
            DropdownButtonFormField<String>(
              value: _categoria,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: [for (final e in categorias.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
              onChanged: (v) => setState(() => _categoria = v!),
            ),
            _sep(),
            TextFormField(controller: _proposito, decoration: const InputDecoration(labelText: 'Propósito')),
            _sep(),
            TextFormField(
              controller: _peso,
              decoration: const InputDecoration(labelText: 'Peso (kg)'),
              keyboardType: TextInputType.number,
              validator: (v) => (v != null && v.trim().isNotEmpty && double.tryParse(v.trim()) == null) ? 'Escribe un número' : null,
            ),
            _sep(),
            OutlinedButton(
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _nacimiento ?? DateTime.now(),
                  firstDate: DateTime(1990),
                  lastDate: DateTime.now(),
                );
                if (d != null) setState(() => _nacimiento = d);
              },
              child: Text(_nacimiento == null ? 'Fecha de nacimiento' : 'Nació: ${_nacimiento!.day}/${_nacimiento!.month}/${_nacimiento!.year}'),
            ),
            const SizedBox(height: 20),
            Text('Genealogía', style: Theme.of(context).textTheme.titleMedium),
            _sep(),
            TextFormField(controller: _padreId, decoration: const InputDecoration(labelText: 'SINIIGA del padre')),
            _sep(),
            TextFormField(controller: _padreNombre, decoration: const InputDecoration(labelText: 'Nombre del padre')),
            _sep(),
            TextFormField(controller: _madreId, decoration: const InputDecoration(labelText: 'SINIIGA de la madre')),
            _sep(),
            TextFormField(controller: _madreNombre, decoration: const InputDecoration(labelText: 'Nombre de la madre')),
            _sep(),
            TextFormField(
              controller: _pureza,
              decoration: const InputDecoration(labelText: 'Porcentaje de pureza (0 a 100)'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = double.tryParse(v.trim());
                return (n == null || n < 0 || n > 100) ? 'Escribe un valor entre 0 y 100' : null;
              },
            ),
            _sep(),
            TextFormField(controller: _descripcion, decoration: const InputDecoration(labelText: 'Descripción'), maxLines: 3),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: Text(_guardando ? 'Guardando…' : 'Guardar bovino'),
            ),
          ]),
        ),
      );
}
