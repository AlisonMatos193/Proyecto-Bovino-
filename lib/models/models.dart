/// Catálogos usados por los formularios.
const categorias = <String, String>{
  'ternero_destete': 'Ternero (destete)',
  'ternera_destete': 'Ternera (destete)',
  'novillo': 'Novillo',
  'novilla': 'Novilla',
  'vaca_gestante': 'Vaca gestante',
  'vaca_pegada': 'Vaca pegada',
  'toro_semental': 'Toro semental',
  'toro_terminado': 'Toro terminado',
};

const tiposVenta = <String, String>{
  'animal': 'Animal en pie',
  'semen_sexado_macho': 'Semen sexado (macho)',
  'semen_sexado_hembra': 'Semen sexado (hembra)',
  'semen_convencional': 'Semen convencional',
  'embrion': 'Embrión',
};

const tiposEvento = ['IATF', 'Palpación', 'Parto', 'Vacunación', 'Desparasitación', 'Tratamiento'];

class Bovino {
  final String numeroSiniiga;
  final String? nombre;
  final String raza;
  final String sexo; // 'M' | 'H'
  final String categoria;
  final String? proposito;
  final double? peso;
  final String? fechaNacimiento;
  final String? fotoPath;
  final String? descripcion;
  final String idGanadero;

  // Datos que vienen de JOINs (solo lectura)
  final String? ganadero, rancho, telefono;
  final String? siniigaPadre, nombrePadre, siniigaMadre, nombreMadre;
  final double? pureza, precioMin, precioMax;

  const Bovino({
    required this.numeroSiniiga,
    this.nombre,
    required this.raza,
    required this.sexo,
    required this.categoria,
    this.proposito,
    this.peso,
    this.fechaNacimiento,
    this.fotoPath,
    this.descripcion,
    required this.idGanadero,
    this.ganadero,
    this.rancho,
    this.telefono,
    this.siniigaPadre,
    this.nombrePadre,
    this.siniigaMadre,
    this.nombreMadre,
    this.pureza,
    this.precioMin,
    this.precioMax,
  });

  String get titulo => (nombre != null && nombre!.trim().isNotEmpty) ? nombre! : numeroSiniiga;
  bool get enVenta => precioMin != null;

  factory Bovino.fromMap(Map<String, Object?> m) => Bovino(
        numeroSiniiga: m['numero_siniiga'] as String,
        nombre: m['nombre'] as String?,
        raza: m['raza'] as String,
        sexo: m['sexo'] as String,
        categoria: m['categoria'] as String,
        proposito: m['proposito'] as String?,
        peso: (m['peso'] as num?)?.toDouble(),
        fechaNacimiento: m['fecha_nacimiento'] as String?,
        fotoPath: m['foto_path'] as String?,
        descripcion: m['descripcion'] as String?,
        idGanadero: m['id_ganadero'] as String,
        ganadero: m['ganadero'] as String?,
        rancho: m['rancho'] as String?,
        telefono: m['telefono'] as String?,
        siniigaPadre: m['siniiga_padre'] as String?,
        nombrePadre: m['nombre_padre'] as String?,
        siniigaMadre: m['siniiga_madre'] as String?,
        nombreMadre: m['nombre_madre'] as String?,
        pureza: (m['pureza'] as num?)?.toDouble(),
        precioMin: (m['precio_min'] as num?)?.toDouble(),
        precioMax: (m['precio_max'] as num?)?.toDouble(),
      );

  /// Solo columnas de la tabla `bovinos`.
  Map<String, Object?> toMap() => {
        'numero_siniiga': numeroSiniiga,
        'nombre': nombre,
        'raza': raza,
        'sexo': sexo,
        'categoria': categoria,
        'proposito': proposito,
        'peso': peso,
        'fecha_nacimiento': fechaNacimiento,
        'foto_path': fotoPath,
        'descripcion': descripcion,
        'id_ganadero': idGanadero,
      };
}

class EventoClinico {
  final String id;
  final String numeroSiniiga;
  final String fecha;
  final String tipo;
  final String? protocoloHormonal;
  final String? notas;
  final String? fechaProxima;

  const EventoClinico({
    required this.id,
    required this.numeroSiniiga,
    required this.fecha,
    required this.tipo,
    this.protocoloHormonal,
    this.notas,
    this.fechaProxima,
  });

  factory EventoClinico.fromMap(Map<String, Object?> m) => EventoClinico(
        id: m['id_evento'] as String,
        numeroSiniiga: m['numero_siniiga'] as String,
        fecha: m['fecha'] as String,
        tipo: m['tipo_evento'] as String,
        protocoloHormonal: m['protocolo_hormonal'] as String?,
        notas: m['notas'] as String?,
        fechaProxima: m['fecha_proxima'] as String?,
      );

  Map<String, Object?> toMap() => {
        'id_evento': id,
        'numero_siniiga': numeroSiniiga,
        'fecha': fecha,
        'tipo_evento': tipo,
        'protocolo_hormonal': protocoloHormonal,
        'notas': notas,
        'fecha_proxima': fechaProxima,
      };
}
