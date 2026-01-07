package com.tbd.lab1tbd.Repositories;

import com.tbd.lab1tbd.Entities.Ruta;
import com.tbd.lab1tbd.Dto.RutaRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

@Repository
@RequiredArgsConstructor
public class RutaRepository {

    private final NamedParameterJdbcTemplate jdbc;

    // Mapper para convertir la respuesta SQL a objeto Java
    private static final RowMapper<Ruta> MAPPER = new RowMapper<>() {
        @Override
        public Ruta mapRow(ResultSet rs, int rowNum) throws SQLException {
            return new Ruta(
                rs.getLong("id"),
                rs.getString("nombre"),
                rs.getString("descripcion"),
                rs.getLong("id_usuario"),
                rs.getString("nombre_usuario"),
                rs.getString("geojson"), // PostGIS nos da el JSON listo
                rs.getDouble("kilometros"),
                rs.getTimestamp("fecha_creacion")
            );
        }
    };

    public List<Ruta> findAll() {
        // Obtenemos la geometría como GeoJSON y calculamos la longitud en KM
        String sql = """
            SELECT r.id, r.nombre, r.descripcion, r.id_usuario, u.nombre as nombre_usuario, r.fecha_creacion,
                   ST_AsGeoJSON(r.camino) as geojson,
                   (ST_Length(r.camino::geography) / 1000) as kilometros
            FROM rutas_sugeridas r
            JOIN usuarios u ON r.id_usuario = u.id
            ORDER BY r.fecha_creacion DESC
        """;
        return jdbc.query(sql, MAPPER);
    }

    public Long create(RutaRequest ruta) {
        // Convertir la lista de coordenadas [[lat, lon]] a WKT LINESTRING(lon lat, lon lat)
        // OJO: PostGIS usa (Longitud Latitud), pero Leaflet manda [Latitud, Longitud]
        StringBuilder wkt = new StringBuilder("LINESTRING(");
        for (int i = 0; i < ruta.getCoordenadas().size(); i++) {
            List<Double> punto = ruta.getCoordenadas().get(i);
            Double lat = punto.get(0);
            Double lon = punto.get(1);
            wkt.append(lon).append(" ").append(lat); // Espacio entre lon y lat
            if (i < ruta.getCoordenadas().size() - 1) {
                wkt.append(","); // Coma entre puntos
            }
        }
        wkt.append(")");

        String sql = """
            INSERT INTO rutas_sugeridas (nombre, descripcion, id_usuario, camino)
            VALUES (:nombre, :descripcion, :idUsuario, ST_GeomFromText(:wkt, 4326))
            RETURNING id
        """;

        MapSqlParameterSource params = new MapSqlParameterSource()
                .addValue("nombre", ruta.getNombre())
                .addValue("descripcion", ruta.getDescripcion())
                .addValue("idUsuario", ruta.getIdUsuario())
                .addValue("wkt", wkt.toString());

        return jdbc.queryForObject(sql, params, Long.class);
    }
}