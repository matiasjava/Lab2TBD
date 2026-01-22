
-- Consultas del Enunciado Laboratorio 1

-- Consulta #1: Procedimiento que reciba las coordenadas del usuario y devuelva los sitios turísticos en un radio de 5km ordenados por distancia (ST_Distance)
SELECT
    s.id,
    s.nombre,
    s.descripcion,
    s.tipo,
    s.calificacion_promedio,
    s.total_reseñas,
    ST_Y(s.ubicacion::geometry) AS latitud,
    ST_X(s.ubicacion::geometry) AS longitud,
    ST_Distance(
        s.ubicacion, 
        ST_MakePoint(-70.6506, -33.4372)::geography 
    ) AS distancia
FROM buscar_sitios_cercanos(-70.6506, -33.4372, 5000) s 
ORDER BY distancia ASC;

-- Consulta 2: Análisis de Proximidad (Restaurantes a < 100m de un Teatro).
SELECT 
    t.nombre AS nombre_teatro,
    r.nombre AS nombre_restaurante,
    ST_Distance(t.ubicacion, r.ubicacion) AS distancia_en_metros
FROM 
    sitios_turisticos t
JOIN 
    sitios_turisticos r ON ST_DWithin(t.ubicacion, r.ubicacion, 100) 
WHERE 
    t.tipo = 'Teatro' 
    AND r.tipo = 'Restaurante'
    AND t.id != r.id; 

-- Consulta 3:  Permitir que el usuario defina un polígono arbitrario (dibujado en el mapa) y encontrar todos los sitios contenidos en él usando ST_Contains o ST_Covers.
SELECT
    id, nombre, descripcion, tipo, calificacion_promedio, total_reseñas,
    ST_Y(ubicacion::geometry) AS latitud,
    ST_X(ubicacion::geometry) AS longitud
FROM sitios_turisticos
WHERE ST_Covers(
    ST_GeomFromText('POLYGON((-70.64 -33.44, -70.65 -33.43, -70.63 -33.43, -70.64 -33.44))', 4326),
    ubicacion::geometry
);


-- Consulta 4: Si existen rutas guardadas, calcular la longitud total del recorrido en kilómetros usando ST_Length.

SELECT 
    r.id, 
    r.nombre, 
    r.descripcion, 
    r.id_usuario, 
    u.nombre as nombre_usuario, 
    r.fecha_creacion,
    ST_AsGeoJSON(r.camino) as geojson,
    ROUND(CAST(ST_Length(r.camino::geography) / 1000 AS numeric), 2) as longitud_km
FROM rutas_sugeridas r
INNER JOIN usuarios u ON r.id_usuario = u.id
ORDER BY r.fecha_creacion DESC;

