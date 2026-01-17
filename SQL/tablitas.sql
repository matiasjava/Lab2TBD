-- ================================================================================================
-- 1. LIMPIEZA INICIAL (DROPS)
-- ================================================================================================
DROP TRIGGER IF EXISTS trigger_refresh_view_reseñas ON reseñas;
DROP TRIGGER IF EXISTS trigger_refresh_view_fotos ON fotografias;
DROP TRIGGER IF EXISTS trigger_refresh_view_listas ON listas_personalizadas;
DROP FUNCTION IF EXISTS refrescar_resumen_contribuciones;
DROP MATERIALIZED VIEW IF EXISTS resumen_contribuciones_usuario CASCADE;

DROP TABLE IF EXISTS rutas_sugeridas CASCADE;
DROP TABLE IF EXISTS lista_sitios CASCADE;
DROP TABLE IF EXISTS listas_personalizadas CASCADE;
DROP TABLE IF EXISTS fotografias CASCADE;
DROP TABLE IF EXISTS reseñas CASCADE;
DROP TABLE IF EXISTS seguidores CASCADE;
DROP TABLE IF EXISTS sitios_turisticos CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;

-- Habilitar extensión PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;

-- ================================================================================================
-- 2. CREACIÓN DE TABLAS
-- ================================================================================================

CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    contrasena_hash VARCHAR(255) NOT NULL,
    biografia TEXT,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS seguidores (
    id SERIAL PRIMARY KEY,
    id_seguidor INT NOT NULL,
    id_seguido INT NOT NULL,
    fecha_inicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_seguidor) REFERENCES usuarios(id) ON DELETE CASCADE,
    FOREIGN KEY (id_seguido) REFERENCES usuarios(id) ON DELETE CASCADE,
    CHECK (id_seguidor != id_seguido),
    UNIQUE (id_seguidor, id_seguido)
);

CREATE TABLE sitios_turisticos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    descripcion TEXT,
    tipo VARCHAR(50),
    ubicacion GEOGRAPHY(POINT, 4326),
    calificacion_promedio DECIMAL(3, 2) DEFAULT 0.0,
    total_reseñas INT DEFAULT 0
);

CREATE TABLE reseñas (
    id SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL,
    id_sitio INT NOT NULL,
    contenido TEXT,
    calificacion INT NOT NULL CHECK (calificacion >= 1 AND calificacion <= 5),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id) ON DELETE SET NULL,
    FOREIGN KEY (id_sitio) REFERENCES sitios_turisticos(id) ON DELETE CASCADE
);

CREATE TABLE fotografias (
    id SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL,
    id_sitio INT NOT NULL,
    url VARCHAR(512) NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id) ON DELETE SET NULL,
    FOREIGN KEY (id_sitio) REFERENCES sitios_turisticos(id) ON DELETE CASCADE
);

CREATE TABLE listas_personalizadas (
    id SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id) ON DELETE CASCADE
);

CREATE TABLE lista_sitios (
    id_lista INT NOT NULL,
    id_sitio INT NOT NULL,
    FOREIGN KEY (id_lista) REFERENCES listas_personalizadas(id) ON DELETE CASCADE,
    FOREIGN KEY (id_sitio) REFERENCES sitios_turisticos(id) ON DELETE CASCADE,
    PRIMARY KEY (id_lista, id_sitio)
);

CREATE TABLE rutas_sugeridas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    descripcion TEXT,
    id_usuario INT NOT NULL,
    camino GEOMETRY(LINESTRING, 4326), -- Columna espacial para la línea de ruta
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- ================================================================================================
-- 3. TRIGGER: CALIFICACIÓN PROMEDIO (Requisito #6)
-- ================================================================================================

CREATE OR REPLACE FUNCTION actualizar_calificacion_promedio()
RETURNS TRIGGER AS $$
DECLARE
    sitio_id INT;
BEGIN
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        sitio_id := NEW.id_sitio;
    ELSEIF (TG_OP = 'DELETE') THEN
        sitio_id := OLD.id_sitio;
    END IF;

    UPDATE sitios_turisticos
    SET 
        calificacion_promedio = (SELECT COALESCE(AVG(calificacion), 0.0) FROM reseñas WHERE id_sitio = sitio_id),
        total_reseñas = (SELECT COUNT(*) FROM reseñas WHERE id_sitio = sitio_id)
    WHERE id = sitio_id;

    RETURN NULL; 
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_actualizar_calificacion
AFTER INSERT OR UPDATE OR DELETE ON reseñas
FOR EACH ROW
EXECUTE FUNCTION actualizar_calificacion_promedio();

-- ================================================================================================
-- 4. VISTA MATERIALIZADA (Requisito #9)
-- ================================================================================================

CREATE MATERIALIZED VIEW resumen_contribuciones_usuario AS
SELECT 
    u.id AS id_usuario,
    u.nombre,
    (SELECT COUNT(*) FROM reseñas r WHERE r.id_usuario = u.id) AS total_reseñas,
    (SELECT COUNT(*) FROM fotografias f WHERE f.id_usuario = u.id) AS total_fotos,
    (SELECT COUNT(*) FROM listas_personalizadas l WHERE l.id_usuario = u.id) AS total_listas
FROM 
    usuarios u
WITH DATA;

-- ÍNDICE OBLIGATORIO para refresco concurrente
CREATE UNIQUE INDEX idx_resumen_contribuciones_usuario_id
ON resumen_contribuciones_usuario(id_usuario);

-- ================================================================================================
-- 5. LÓGICA DE AUTO-REFRESCO (TRIGGERS PARA LA VISTA)
-- ================================================================================================

-- Función de refresco
CREATE OR REPLACE FUNCTION refrescar_resumen_contribuciones()
RETURNS TRIGGER AS $$
BEGIN
    -- Refresca la vista sin bloquear lecturas
    REFRESH MATERIALIZED VIEW CONCURRENTLY resumen_contribuciones_usuario;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger 1: Cuando cambian las reseñas
CREATE TRIGGER trigger_refresh_view_reseñas
AFTER INSERT OR UPDATE OR DELETE ON reseñas
FOR EACH STATEMENT  -- Ejecutar una vez por transacción (Eficiencia)
EXECUTE FUNCTION refrescar_resumen_contribuciones();

-- Trigger 2: Cuando cambian las fotos
CREATE TRIGGER trigger_refresh_view_fotos
AFTER INSERT OR UPDATE OR DELETE ON fotografias
FOR EACH STATEMENT
EXECUTE FUNCTION refrescar_resumen_contribuciones();

-- Trigger 3: Cuando cambian las listas
CREATE TRIGGER trigger_refresh_view_listas
AFTER INSERT OR UPDATE OR DELETE ON listas_personalizadas
FOR EACH STATEMENT
EXECUTE FUNCTION refrescar_resumen_contribuciones();

-- ================================================================================================
-- 6. ÍNDICES Y FUNCIONES ADICIONALES
-- ================================================================================================

CREATE INDEX idx_seguidores_seguidor ON seguidores(id_seguidor);
CREATE INDEX idx_seguidores_seguido ON seguidores(id_seguido);
CREATE INDEX idx_reseñas_id_sitio ON reseñas(id_sitio);
CREATE INDEX idx_reseñas_id_usuario ON reseñas(id_usuario);
CREATE INDEX idx_fotografias_id_sitio ON fotografias(id_sitio);
CREATE INDEX idx_fotografias_id_usuario ON fotografias(id_usuario);
CREATE INDEX idx_sitios_tipo ON sitios_turisticos(tipo);
CREATE INDEX idx_sitios_coordenadas ON sitios_turisticos USING GIST (coordenadas);
CREATE INDEX idx_rutas_camino ON rutas_sugeridas USING GIST (camino);

-- -----------------------------------------------------
-- Fin del Script de Índices
-- -----------------------------------------------------

-- =============================================
-- Requisito: Procedimiento Almacenado
-- Encapsula la lógica de "búsqueda de sitios cercanos".
-- =============================================

-- Función de Búsqueda Geoespacial
CREATE OR REPLACE FUNCTION buscar_sitios_cercanos(
    user_long DOUBLE PRECISION,
    user_lat DOUBLE PRECISION,
    radio_metros INT
)
RETURNS SETOF sitios_turisticos AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM sitios_turisticos
    WHERE ST_DWithin(
            coordenadas,
            ST_MakePoint(user_long, user_lat)::geography,
            radio_metros
        );
END;
$$ LANGUAGE plpgsql;