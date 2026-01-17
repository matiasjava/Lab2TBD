package com.tbd.lab2tbd.Repositories;

import com.tbd.lab2tbd.Dto.*;
import com.tbd.lab2tbd.Entities.SitioTuristico;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Repository para ejecutar las consultas SQL del enunciado del lab 1 y 2.
 * Cada método corresponde a una consulta específica.
 */
@Repository
@RequiredArgsConstructor
public class EstadisticasRepository {

    private final NamedParameterJdbcTemplate jdbc;

    /**
     * Consulta #1: Procedimiento que reciba las coordenadas del usuario y devuelva los sitios
     *              turísticos en un radio de 5km ordenados por distancia (ST_Distance)
     */

    public List<SitioCercanoResponse> findCercanos(Double longitud, Double latitud, Integer radioMetros) {
        String sql = """
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
                ST_MakePoint(:longitud, :latitud)::geography
            ) AS distancia
        FROM buscar_sitios_cercanos(:longitud, :latitud, :radio) s
        ORDER BY distancia ASC
        """;

        MapSqlParameterSource params = new MapSqlParameterSource()
                .addValue("longitud", longitud)
                .addValue("latitud", latitud)
                .addValue("radio", radioMetros);

        return jdbc.query(sql, params, (rs, rowNum) -> {
            // 1. Mapeo del objeto interno
            SitioTuristico sitio = new SitioTuristico();
            sitio.setId(rs.getLong("id"));
            sitio.setNombre(rs.getString("nombre"));
            sitio.setDescripcion(rs.getString("descripcion"));
            sitio.setTipo(rs.getString("tipo"));
            sitio.setLatitud(rs.getDouble("latitud"));
            sitio.setLongitud(rs.getDouble("longitud"));
            sitio.setCalificacionPromedio(rs.getDouble("calificacion_promedio"));
            sitio.setTotalreseñas(rs.getInt("total_reseñas"));

            // 2. Mapeo del DTO respuesta
            SitioCercanoResponse response = new SitioCercanoResponse();
            response.setSitio(sitio);
            response.setDistanciaEnMetros(rs.getDouble("distancia"));

            return response;
        });
    }


    /**
     * Consulta #3: Análisis de Proximidad (Restaurantes a < 100m de un Teatro)
     */
    public List<ProximidadSitiosResponse> obtenerAnalisisProximidad() {
        String sql = """
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
                    AND t.id != r.id
                ORDER BY distancia_en_metros ASC
                """;

        return jdbc.query(sql, (rs, rowNum) -> new ProximidadSitiosResponse(
                rs.getString("nombre_teatro"),
                rs.getString("nombre_restaurante"),
                rs.getDouble("distancia_en_metros")
        ));
    }


    /**
     * Consulta #1: Cálculo de Calificación Promedio y Conteo de Reseñas por tipo
     */
    public List<EstadisticasPorTipoResponse> obtenerEstadisticasPorTipo() {
        String sql = """
                SELECT
                    tipo,
                    AVG(calificacion_promedio) AS calificacion_promedio_general,
                    SUM(total_reseñas) AS total_reseñas_general
                FROM
                    sitios_turisticos
                GROUP BY
                    tipo
                ORDER BY total_reseñas_general DESC
                """;

        return jdbc.query(sql, (rs, rowNum) -> new EstadisticasPorTipoResponse(
                rs.getString("tipo"),
                rs.getDouble("calificacion_promedio_general"),
                rs.getInt("total_reseñas_general")
        ));
    }

    /**
     * Consulta #2: Identificación de los 5 Reseñadores Más Activos (últimos 6 meses)
     */
    public List<TopResenadorResponse> obtenerTopResenadores() {
        String sql = """
                WITH reseñasRecientes AS (
                    SELECT
                        id_usuario,
                        COUNT(*) AS conteo_reseñas
                    FROM
                        reseñas
                    WHERE
                        fecha >= (CURRENT_TIMESTAMP - INTERVAL '6 months')
                    GROUP BY
                        id_usuario
                )
                SELECT
                    u.nombre AS nombre_usuario,
                    rr.conteo_reseñas
                FROM
                    reseñasRecientes rr
                JOIN
                    usuarios u ON rr.id_usuario = u.id
                ORDER BY
                    rr.conteo_reseñas DESC
                LIMIT 5
                """;

        return jdbc.query(sql, (rs, rowNum) -> new TopResenadorResponse(
                rs.getString("nombre_usuario"),
                rs.getInt("conteo_reseñas")
        ));
    }

    /**
     * Consulta #4: Detección de Sitios con Valoraciones Inusuales
     * (Promedio > 4.5, < 10 reseñas)
     */
    public List<SitioValoracionInusualResponse> obtenerSitiosValoracionInusual() {
        String sql = """
                SELECT
                    nombre,
                    calificacion_promedio,
                    total_reseñas
                FROM
                    sitios_turisticos
                WHERE
                    calificacion_promedio > 4.5
                    AND total_reseñas < 10
                    AND total_reseñas > 0
                ORDER BY calificacion_promedio DESC
                """;

        return jdbc.query(sql, (rs, rowNum) -> new SitioValoracionInusualResponse(
                rs.getString("nombre"),
                rs.getDouble("calificacion_promedio"),
                rs.getInt("total_reseñas")
        ));
    }

    /**
     * Consulta #7: Listado de Sitios con Pocas Contribuciones
     * (Sin reseñas o fotos en 3 meses)
     */
    public List<SitioPocasContribucionesResponse> obtenerSitiosPocasContribuciones() {
        String sql = """
                WITH UltimasContribuciones AS (
                    SELECT
                        id_sitio,
                        MAX(fecha) AS ultima_fecha
                    FROM (
                        SELECT id_sitio, fecha FROM reseñas
                        UNION ALL
                        SELECT id_sitio, fecha FROM fotografias
                    ) AS contribuciones
                    GROUP BY id_sitio
                )
                SELECT
                    s.nombre,
                    s.tipo,
                    uc.ultima_fecha AS fecha_ultima_contribucion
                FROM
                    sitios_turisticos s
                LEFT JOIN
                    UltimasContribuciones uc ON s.id = uc.id_sitio
                WHERE
                    uc.ultima_fecha IS NULL
                    OR uc.ultima_fecha < (CURRENT_TIMESTAMP - INTERVAL '3 months')
                ORDER BY uc.ultima_fecha ASC NULLS FIRST
                """;

        return jdbc.query(sql, (rs, rowNum) -> new SitioPocasContribucionesResponse(
                rs.getString("nombre"),
                rs.getString("tipo"),
                rs.getObject("fecha_ultima_contribucion", LocalDateTime.class)
        ));
    }

    /**
     * Consulta #8: Análisis de Contenido de Reseñas
     * (3 más largas de usuarios con promedio > 4.0)
     */
    public List<ResenaLargaResponse> obtenerreseñasLargas() {
        String sql = """
                WITH PromedioUsuario AS (
                    SELECT
                        id_usuario,
                        AVG(calificacion) AS promedio_calificacion
                    FROM
                        reseñas
                    GROUP BY
                        id_usuario
                    HAVING
                        AVG(calificacion) > 4.0
                )
                SELECT
                    u.nombre AS nombre_usuario,
                    s.nombre AS nombre_sitio,
                    r.contenido,
                    LENGTH(r.contenido) AS longitud_resena
                FROM
                    reseñas r
                JOIN
                    usuarios u ON r.id_usuario = u.id
                JOIN
                    sitios_turisticos s ON r.id_sitio = s.id
                JOIN
                    PromedioUsuario pu ON r.id_usuario = pu.id_usuario
                ORDER BY
                    longitud_resena DESC
                LIMIT 3
                """;

        return jdbc.query(sql, (rs, rowNum) -> new ResenaLargaResponse(
                rs.getString("nombre_usuario"),
                rs.getString("nombre_sitio"),
                rs.getString("contenido"),
                rs.getInt("longitud_resena")
        ));
    }

    /**
     * Consulta #9: Resumen de Contribuciones por Usuario
     * (Vista Materializada)
     */
    public List<ResumenContribucionesResponse> obtenerResumenContribuciones() {
        String sql = "SELECT * FROM resumen_contribuciones_usuario ORDER BY total_reseñas DESC";

        return jdbc.query(sql, (rs, rowNum) -> new ResumenContribucionesResponse(
                rs.getLong("id_usuario"),
                rs.getString("nombre"),
                rs.getInt("total_reseñas"),
                rs.getInt("total_fotos"),
                rs.getInt("total_listas")
        ));
    }


    //Consulta #5: Analisis de popularidad por region
    public List<EstadisticasPorRegionResponse> obtenerPopularidadPorRegion() {
        String sql = """
                SELECT 
                    ciudad AS region, 
                    SUM(total_reseñas) AS total_resenas_por_ciudad
                FROM 
                    sitios_turisticos
                WHERE 
                    ciudad IS NOT NULL
                GROUP BY 
                    ciudad
                ORDER BY 
                    total_resenas_por_ciudad DESC
                """;

        return jdbc.query(sql, (rs, rowNum) -> new EstadisticasPorRegionResponse(
                rs.getString("region"),
                rs.getLong("total_resenas_por_ciudad")
        ));
    }
}
