-- ============================================================
--  GrowAI – Schema de Supabase
--  Ejecuta esto en Supabase → SQL Editor
-- ============================================================

-- ── Usuarios de la aplicación ────────────────────────────────
CREATE TABLE IF NOT EXISTS usuarios (
  id          UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  username    TEXT    UNIQUE NOT NULL,
  password_hash TEXT  NOT NULL,   -- En producción usa pgcrypto / bcrypt
  rol         TEXT    DEFAULT 'usuario',  -- 'admin' | 'usuario'
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Usuarios de prueba (contraseñas en texto plano para el TFG)
INSERT INTO usuarios (username, password_hash, rol) VALUES
  ('maria',      '123456',  'usuario'),
  ('DanielAdmin','123456',  'admin')
ON CONFLICT (username) DO NOTHING;

-- ── Sensores IoT ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sensores (
  id              TEXT    PRIMARY KEY,   -- ESP-01, ESP-08, etc.
  nombre          TEXT    NOT NULL,      -- Finca Martínez Ruiz
  sector          TEXT,                  -- Sector A-1
  cliente         TEXT,                  -- Martínez
  temperatura     DECIMAL(5,2),          -- 24.1 °C
  humedad         DECIMAL(5,2),          -- 68 %
  luminosidad     INTEGER,               -- 32000 lux
  co2             INTEGER,               -- 400 ppm
  estado          TEXT    DEFAULT 'online',  -- online | offline | warning
  ultima_lectura  TIMESTAMPTZ DEFAULT NOW()
);

-- Datos de ejemplo
INSERT INTO sensores (id, nombre, sector, cliente, temperatura, humedad, luminosidad, co2, estado) VALUES
  ('ESP-01', 'Finca Martínez Ruiz',   'Sector A-1',       'Martínez', 24.1, 68, 32000, 410, 'online'),
  ('ESP-08', 'García Flores S.L.',    'Sector B-3',       'García',   26.8, 34, 28000, 390, 'warning'),
  ('ESP-14', 'López & Sánchez',       'Zona Principal',   'López',    NULL, NULL, NULL, NULL, 'offline'),
  ('ESP-22', 'Ruiz Agro',             'Invernadero 2',    'Ruiz',     22.5, 72, 41000, 400, 'online'),
  ('ESP-31', 'Sánchez Horticultura',  'Sector C-2',       'Sánchez',  23.9, 65, 38000, 420, 'online'),
  ('ESP-44', 'Paco Agro CB',          'Sector D-1',       'Paco',     21.3, 74, 29000, 380, 'online')
ON CONFLICT (id) DO NOTHING;

-- ── Alertas del sistema ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS alertas (
  id          UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo        TEXT    NOT NULL,   -- critical | warning | info
  titulo      TEXT    NOT NULL,
  descripcion TEXT,
  nivel       TEXT,               -- Crítico | Aviso | IA Predictiva | Sistema
  resuelta    BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Alertas de ejemplo
INSERT INTO alertas (tipo, titulo, descripcion, nivel) VALUES
  ('critical', 'Sensor #ESP-14 offline',        'Parcela Martínez · Sin datos desde hace 2h 14min. Revisar dispositivo.', 'Crítico'),
  ('warning',  'Humedad baja detectada',         'Invernadero García · Humedad actual 34%, umbral mínimo 45%.', 'Aviso'),
  ('warning',  'Temperatura elevada',            'Parcela López · 38.2°C en sector B. Rango óptimo 18–28°C.', 'Aviso'),
  ('info',     'Predicción: estrés hídrico',     'IA detecta riesgo de estrés en Finca Ruiz en 36h. Probabilidad 91%.', 'IA Predictiva'),
  ('info',     'Modelo IA reentrenado',          'Precisión mejorada de 85.2% a 87.3%.', 'Sistema');

-- ── Clientes ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS clientes (
  id           UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre       TEXT    NOT NULL,
  ubicacion    TEXT,
  plan         TEXT    DEFAULT 'basico',       -- basico | profesional | premium
  num_zonas    INTEGER DEFAULT 1,
  num_sensores INTEGER DEFAULT 2,
  mrr          DECIMAL(8,2) DEFAULT 19,
  estado       TEXT    DEFAULT 'activo',       -- activo | inactivo | warning
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO clientes (nombre, ubicacion, plan, num_zonas, num_sensores, mrr, estado) VALUES
  ('Finca Martínez Ruiz',   'El Ejido, Almería',  'premium',      10, 10, 65,  'activo'),
  ('García Flores S.L.',    'Níjar, Almería',      'profesional',   3,  6, 39,  'activo'),
  ('López & Sánchez',       'Almería capital',     'profesional',   3,  5, 39,  'warning'),
  ('Paco Agro CB',          'Vícar, Almería',      'basico',        1,  2, 19,  'activo'),
  ('Ruiz Agro',             'Roquetas de Mar',     'premium',       8,  8, 65,  'activo'),
  ('Sánchez Horticultura',  'Berja, Almería',      'profesional',   3,  4, 39,  'inactivo')
ON CONFLICT DO NOTHING;

-- ── Políticas RLS (Row Level Security) ──────────────────────
-- Habilitar RLS en las tablas
ALTER TABLE usuarios  ENABLE ROW LEVEL SECURITY;
ALTER TABLE sensores  ENABLE ROW LEVEL SECURITY;
ALTER TABLE alertas   ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes  ENABLE ROW LEVEL SECURITY;

-- Permitir lectura pública de sensores y alertas (el servidor ya protege con sesión)
CREATE POLICY "Lectura pública sensores"  ON sensores FOR SELECT USING (true);
CREATE POLICY "Lectura pública alertas"   ON alertas  FOR SELECT USING (true);
CREATE POLICY "Lectura pública usuarios"  ON usuarios FOR SELECT USING (true);

-- Permitir actualización de sensores (para cuando los ESP32 envíen datos)
CREATE POLICY "Actualizar sensores"       ON sensores  FOR UPDATE USING (true);
CREATE POLICY "Insertar sensores"         ON sensores  FOR INSERT WITH CHECK (true);
CREATE POLICY "Lectura pública clientes"  ON clientes  FOR SELECT USING (true);
CREATE POLICY "Actualizar clientes"       ON clientes  FOR UPDATE USING (true);
CREATE POLICY "Insertar clientes"         ON clientes  FOR INSERT WITH CHECK (true);
