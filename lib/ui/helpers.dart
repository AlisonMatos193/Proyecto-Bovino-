import 'package:flutter/material.dart';

// --- PIEZAS RECUPERADAS DEL DISEÑO ANTERIOR ---

class Paleta {
  static const Color pasto = Color(0xFF4CAF50);
  static const Color sol = Color(0xFFFFC107);
  static const Color alerta = Color(0xFFF44336);
  static const Color tierra = Color(0xFF795548);
}

String rangoPrecio(dynamic b) {
  if (b.precio != null) return '\$${b.precio}';
  if (b.precioMin != null && b.precioMax != null) {
    return '\$${b.precioMin} - \$${b.precioMax}';
  }
  return 'Precio no definido';
}

class BovinoFoto extends StatelessWidget {
  final String? path;
  final double size;
  final double height;
  const BovinoFoto({super.key, this.path, required this.size, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: height,
      color: Colors.grey[300],
      child: path != null
          ? Image.network(path!, fit: BoxFit.cover) // Asumiendo que es URL
          : const Icon(Icons.pets, size: 50, color: Colors.grey),
    );
  }
}