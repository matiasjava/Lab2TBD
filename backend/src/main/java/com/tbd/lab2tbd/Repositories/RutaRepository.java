package com.tbd.lab2tbd.Repositories;

import com.tbd.lab2tbd.Entities.Ruta;
import com.tbd.lab2tbd.Dto.RutaRequest;
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

    private static final RowMapper<Ruta> MAPPER = (rs, rowNum) -> new Ruta(
            rs.getLong("id"),
            rs.getString("nombre"),
            rs.getString("descripcion"),
            rs.getLong("id_usuario"),
            rs.getString("nombre_usuario"),
            rs.getString("geojson"),
            rs.getDouble("longitud_km"),
            rs.getTimestamp("fecha_creacion")
    );

    public List<Ruta> findAll() {
        String sql = """
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
            ORDER BY r.fecha_creacion DESC
        """;

        try {
            List<Ruta> rutas = jdbc.query(sql, MAPPER);
            System.out.println("RutaRepository.findAll() - Rutas encontradas: " + rutas.size());
            return rutas;
        } catch (Exception e) {
            System.err.println("Error en RutaRepository.findAll(): " + e.getMessage());
            e.printStackTrace();
            return List.of();
        }
    }

    public Long create(RutaRequest ruta) {
        StringBuilder wkt = new StringBuilder("LINESTRING(");
        for (int i = 0; i < ruta.getCoordenadas().size(); i++) {
            List<Double> punto = ruta.getCoordenadas().get(i);
            Double lat = punto.get(0);
            Double lon = punto.get(1);
            wkt.append(lon).append(" ").append(lat);
            if (i < ruta.getCoordenadas().size() - 1) {
                wkt.append(", ");
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

        try {
            Long id = jdbc.queryForObject(sql, params, Long.class);
            System.out.println("Ruta creada con ID: " + id);
            return id;
        } catch (Exception e) {
            System.err.println("Error al crear ruta: " + e.getMessage());
            e.printStackTrace();
            throw e;
        }
    }
}