package com.tbd.lab2tbd.Controllers;

import com.tbd.lab2tbd.Dto.*;
import com.tbd.lab2tbd.Services.EstadisticasService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Controller para exponer las consultas SQL del enunciado como endpoints REST.
 * Cada endpoint corresponde a una consulta específica del laboratorio.
 */
@RestController
@RequestMapping("/estadisticas")
@RequiredArgsConstructor
public class EstadisticasController {

    private final EstadisticasService service;

    /**
     * Consulta #1: Procedimiento que reciba las coordenadas del usuario y devuelva los sitios
     *              turísticos en un radio de 5km ordenados por distancia (ST_Distance)
     */
    @GetMapping("/cercanos")
    public ResponseEntity<List<SitioCercanoResponse>> getSitiosCercanos(
            @RequestParam Double longitud,
            @RequestParam Double latitud) {
        List<SitioCercanoResponse> respuesta = service.obtenerSitiosCercanos(longitud, latitud);

        return ResponseEntity.ok(respuesta);
    }

    /**
     * Consulta #2: Análisis de proximidad (Restaurantes cerca de Teatros).
     */
    @GetMapping("/proximidad")
    public ResponseEntity<List<ProximidadSitiosResponse>> obtenerAnalisisProximidad() {
        return ResponseEntity.ok(service.obtenerAnalisisProximidad());
    }




    // ------------------ CONSULTAS LAB 1 --------------------------------------


    /**
     * GET /api/estadisticas/por-tipo
     * Consulta #1: Calificación promedio y conteo de reseñas por tipo de sitio.
     */
    @GetMapping("/por-tipo")
    public ResponseEntity<List<EstadisticasPorTipoResponse>> obtenerEstadisticasPorTipo() {
        return ResponseEntity.ok(service.obtenerEstadisticasPorTipo());
    }

    /**
     * GET /api/estadisticas/top-resenadores
     * Consulta #2: Top 5 reseñadores más activos (últimos 6 meses).
     */
    @GetMapping("/top-reseñadores")
    public ResponseEntity<List<TopResenadorResponse>> obtenerTopResenadores() {
        return ResponseEntity.ok(service.obtenerTopResenadores());
    }

    /**
     * GET /api/estadisticas/valoraciones-inusuales
     * Consulta #4: Sitios con valoraciones inusuales (>4.5 con <10 reseñas).
     */
    @GetMapping("/valoraciones-inusuales")
    public ResponseEntity<List<SitioValoracionInusualResponse>> obtenerSitiosValoracionInusual() {
        return ResponseEntity.ok(service.obtenerSitiosValoracionInusual());
    }

    /**
     *
     * Consulta #5:  Análisis de Popularidad por Región
     */
    @GetMapping("/popularidad-region")
    public ResponseEntity<List<EstadisticasPorRegionResponse>> obtenerPopularidadPorRegion() {
        return ResponseEntity.ok(service.obtenerPopularidadPorRegion());
    }

    /**
     * GET /api/estadisticas/pocas-contribuciones
     * Consulta #7: Sitios con pocas contribuciones (sin actividad en 3 meses).
     */
    @GetMapping("/pocas-contribuciones")
    public ResponseEntity<List<SitioPocasContribucionesResponse>> obtenerSitiosPocasContribuciones() {
        return ResponseEntity.ok(service.obtenerSitiosPocasContribuciones());
    }

    /**
     * GET /api/estadisticas/reseñas-largas
     * Consulta #8: Top 3 reseñas más largas de usuarios con promedio >4.0.
     */
    @GetMapping("/reseñas-largas")
    public ResponseEntity<List<ResenaLargaResponse>> obtenerreseñasLargas() {
        return ResponseEntity.ok(service.obtenerreseñasLargas());
    }

    /**
     * GET /api/estadisticas/resumen-contribuciones
     * Consulta #9: Resumen de contribuciones por usuario (vista materializada).
     */
    @GetMapping("/resumen-contribuciones")
    public ResponseEntity<List<ResumenContribucionesResponse>> obtenerResumenContribuciones() {
        return ResponseEntity.ok(service.obtenerResumenContribuciones());
    }

}