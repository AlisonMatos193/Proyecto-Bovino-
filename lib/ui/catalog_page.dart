import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../data/repository.dart';
import '../models/models.dart';
import 'dart:io';
import 'bovino_detail_page.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    // Video de prueba temporal. Luego lo cambiaremos por el archivo .mp4 de JD Carnes/Tizimín
    _controller = VideoPlayerController.networkUrl(
        Uri.parse('https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'))
      ..initialize().then((_) {
        _controller.setVolume(0.0); // Completamente en silencio
        _controller.setLooping(true); // Repetir infinitamente
        _controller.play(); // Iniciar automáticamente
        setState(() {}); // Actualizar la pantalla cuando el video cargue
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. CAPA DE FONDO: EL VIDEO INMERSIVO
          SizedBox.expand(
            child: _controller.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  )
                :  Container(color: Color(0xFF1F3A2E)), // Fondo verde mientras carga
          ),

          // 2. CAPA OSCURA: PARA LEER BIEN EL TEXTO BLANCO
          Container(
            color: Colors.black.withOpacity(0.5),
          ),

          // 3. CAPA FRONTAL: TEXTOS, CATEGORÍAS Y TOP 10
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "El esfuerzo de cada rancho de Tizimín, en un solo lugar",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Bitter'),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Detrás de cada animal hay meses de manejo, cuidado y buena genética. Elige qué tipo de ganado buscas para empezar.",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 30),

                  // BOTONES DE CATEGORÍA
                  Row(
                    children: [
                      Expanded(
                        child: _CategoriaCard(
                            titulo: "Ganado comercial",
                            desc: "Animales de venta general. Precio en rango."),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CategoriaCard(
                            titulo: "Ganado de registro",
                            desc: "Animales con pedigrí. Precio único."),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // CARRUSEL TOP 10
                  const Text(
                    "Top 10 vacas destacadas",
                    style: TextStyle(
                        color: Color(0xFFC9A24B), // Acento dorado
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Bitter'),
                  ),
                  // CARRUSEL TOP 10 CONECTADO A SQLITE
const SizedBox(height: 10),
SizedBox(
  height: 220,
  child: FutureBuilder<List<Bovino>>(
    future: Repo.instance.miGanaderoId().then((id) => Repo.instance.catalogo(idGanadero: id)),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFFC9A24B))); 
      }
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Center(
          child: Text("No hay bovinos registrados aún.", style: TextStyle(color: Colors.white70)),
        );
      }

      final bovinos = snapshot.data!;
      // Solo tomamos los primeros 10 para cumplir con el "Top 10"
      final limite = bovinos.length > 10 ? 10 : bovinos.length;

      return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: limite,
        itemBuilder: (context, index) {
          return _Top10Card(index: index + 1, b: bovinos[index]);
        },
      );
    },
  ),
),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET PARA LAS TARJETAS DE CATEGORÍA ---
class _CategoriaCard extends StatelessWidget {
  final String titulo;
  final String desc;
  const _CategoriaCard({required this.titulo, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F1), // Fondo beige claro del HTML
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD8CDB4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F3A2E))),
          const SizedBox(height: 5),
          Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF5B5546))),
        ],
      ),
    );
  }
}

// --- WIDGET PARA LAS TARJETAS DEL TOP 10 (NÚMEROS GIGANTES) ---
class _Top10Card extends StatelessWidget {
  final int index;
  final dynamic b; // <-- Conector para los datos reales

  const _Top10Card({required this.index, required this.b});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // NÚMERO GIGANTE HUECO DE FONDO
        Positioned(
          left: 0,
          bottom: -20,
          child: Text(
            '$index',
            style: TextStyle(
              fontSize: 140,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = Colors.white.withOpacity(0.3),
            ),
          ),
        ),
        // TARJETA DEL BOVINO
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BovinoDetailPage(b: b, editable: true),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(left: 45, right: 15, top: 10, bottom: 10),
            width: 140,
            decoration: BoxDecoration(
              color: const Color(0xFFFBF8F1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD8CDB4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD8CDB4),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: b.fotoPath != null && b.fotoPath!.isNotEmpty
                      ? Image.file(
                          File(b.fotoPath!),
                          fit: BoxFit.cover,
                        )
                      : const Center(child: Icon(Icons.pets, color: Colors.white)),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.nombre ?? "Sin nombre", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F3A2E))),
                      Text(b.raza ?? "No especificada", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFF5B5546))),
                      const SizedBox(height: 5),
                      const Text("Consultar precio", style: TextStyle(color: Color(0xFF7A3B23), fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// --- PIEZAS RECUPERADAS PARA MANTENER TU REGISTRO INTACTO ---

class SyncBadge extends StatelessWidget {
  const SyncBadge({super.key});
  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.cloud_done, color: Color(0xFF1F3A2E), size: 18);
  }
}

class BovinoCard extends StatelessWidget {
  final dynamic b; // Ajustado a 'b' como lo pide my_ranch_page.dart
  final VoidCallback? onTap; // Agregada la acción onTap

  const BovinoCard({super.key, required this.b, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      color: const Color(0xFFFBF8F1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFD8CDB4)),
      ),
      child: InkWell( // InkWell permite que la tarjeta detecte el clic (onTap)
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFF1F3A2E),
            child: Icon(Icons.pets, color: Color.fromARGB(232, 255, 255, 255)),
          ),
          title: Text(
            b.nombre ?? 'Sin nombre', 
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F3A2E))
          ),
          subtitle: Text('Raza: ${b.raza ?? 'No especificada'}'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFC9A24B)),
        ),
      ),
    );
  }
}