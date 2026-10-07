import 'package:flutter/material.dart';

ThemeData buildTheme() {
  return ThemeData(
    // Fondo beige principal de la app
    scaffoldBackgroundColor: const Color(0xFFEDE6D6), 
    
    // Color verde bosque principal
    primaryColor: const Color(0xFF1F3A2E), 
    
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: const Color(0xFF1F3A2E),
      secondary: const Color(0xFFC9A24B), // Dorado para botones y detalles
      surface: const Color(0xFFFBF8F1), // Fondo claro de las tarjetas de ganado
    ),
    
    // Diseño de la barra superior
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1F3A2E),
      foregroundColor: Color(0xFFF4EFE1), // Letras claras en la barra
      elevation: 0,
    ),
    
    // Estilo de los botones principales
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1F3A2E),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    ),
  );
}