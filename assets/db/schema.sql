-- Catálogo Digital Bovino · Tizimín · esquema SQLite (offline-first)
-- Fechas en formato ISO-8601 (texto). Los ids distintos a bovinos son texto generado en la app.

CREATE TABLE ganaderos (
  id_ganadero TEXT PRIMARY KEY,
  nombre      TEXT NOT NULL,
  rancho      TEXT NOT NULL,
  telefono    TEXT,
  municipio   TEXT NOT NULL DEFAULT 'Tizimín',
  updated_at  TEXT NOT NULL
);

CREATE TABLE bovinos (
  numero_siniiga   TEXT PRIMARY KEY,
  nombre           TEXT,
  raza             TEXT NOT NULL,
  sexo             TEXT NOT NULL CHECK (sexo IN ('M','H')),
  categoria        TEXT NOT NULL,
  proposito        TEXT,
  peso             REAL CHECK (peso IS NULL OR peso > 0),
  fecha_nacimiento TEXT,
  foto_path        TEXT,
  descripcion      TEXT,
  id_ganadero      TEXT NOT NULL REFERENCES ganaderos(id_ganadero),
  created_at       TEXT NOT NULL,
  updated_at       TEXT NOT NULL
);

-- Un registro de genealogía por animal. Padre y madre pueden ser animales externos (no están en bovinos).
CREATE TABLE linajes_genealogia (
  id_linaje         TEXT PRIMARY KEY,
  numero_siniiga    TEXT NOT NULL UNIQUE REFERENCES bovinos(numero_siniiga) ON DELETE CASCADE,
  siniiga_padre     TEXT,
  nombre_padre      TEXT,
  siniiga_madre     TEXT,
  nombre_madre      TEXT,
  porcentaje_pureza REAL CHECK (porcentaje_pureza IS NULL OR (porcentaje_pureza >= 0 AND porcentaje_pureza <= 100)),
  updated_at        TEXT NOT NULL
);

CREATE TABLE historial_clinico (
  id_evento          TEXT PRIMARY KEY,
  numero_siniiga     TEXT NOT NULL REFERENCES bovinos(numero_siniiga) ON DELETE CASCADE,
  fecha              TEXT NOT NULL,
  tipo_evento        TEXT NOT NULL,
  protocolo_hormonal TEXT,
  notas              TEXT,
  fecha_proxima      TEXT,
  updated_at         TEXT NOT NULL
);

CREATE TABLE productos_marketplace (
  id_producto    TEXT PRIMARY KEY,
  numero_siniiga TEXT NOT NULL REFERENCES bovinos(numero_siniiga) ON DELETE CASCADE,
  tipo_venta     TEXT NOT NULL CHECK (tipo_venta IN ('animal','semen_sexado_macho','semen_sexado_hembra','semen_convencional','embrion')),
  precio_min     REAL NOT NULL CHECK (precio_min >= 0),
  precio_max     REAL CHECK (precio_max IS NULL OR precio_max >= precio_min),
  activo         INTEGER NOT NULL DEFAULT 1,
  updated_at     TEXT NOT NULL
);

-- Bandeja de salida: cada alta o cambio hecho sin internet se encola aquí y se envía al detectar red.
CREATE TABLE sync_queue (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  tabla       TEXT NOT NULL,
  registro_id TEXT NOT NULL,
  operacion   TEXT NOT NULL CHECK (operacion IN ('insert','update','delete')),
  payload     TEXT NOT NULL,
  created_at  TEXT NOT NULL,
  intentos    INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_bovinos_ganadero ON bovinos(id_ganadero);
CREATE INDEX idx_bovinos_raza_sexo ON bovinos(raza, sexo);
CREATE INDEX idx_linajes_padre ON linajes_genealogia(siniiga_padre);
CREATE INDEX idx_linajes_madre ON linajes_genealogia(siniiga_madre);
CREATE INDEX idx_historial_bovino ON historial_clinico(numero_siniiga, fecha);
CREATE INDEX idx_marketplace_bovino ON productos_marketplace(numero_siniiga, activo);
