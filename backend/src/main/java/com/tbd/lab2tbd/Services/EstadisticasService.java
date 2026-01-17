package com.tbd.lab2tbd.Services;

import com.tbd.lab2tbd.Dto.*;
import com.tbd.lab2tbd.Repositories.EstadisticasRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Service para exponer las estadísticas del sistema.
 * Simplemente delega al repository.
 */
@Service
@RequiredArgsConstructor
public class EstadisticasService {

    private final EstadisticasRepository repository;

    public List<EstadisticasPorTipoResponse> obtenerEstadisticasPorTipo() {
        return repository.obtenerEstadisticasPorTipo();
    }

    public List<TopResenadorResponse> obtenerTopResenadores() {
        return repository.obtenerTopResenadores();
    }

    public List<ProximidadSitiosResponse> obtenerAnalisisProximidad() {
        return repository.obtenerAnalisisProximidad();
    }

    public List<SitioValoracionInusualResponse> obtenerSitiosValoracionInusual() {
        return repository.obtenerSitiosValoracionInusual();
    }

    public List<SitioPocasContribucionesResponse> obtenerSitiosPocasContribuciones() {
        return repository.obtenerSitiosPocasContribuciones();
    }

    public List<ResenaLargaResponse> obtenerreseñasLargas() {
        return repository.obtenerreseñasLargas();
    }

    public List<ResumenContribucionesResponse> obtenerResumenContribuciones() {
        return repository.obtenerResumenContribuciones();
    }

    public List<EstadisticasPorRegionResponse> obtenerPopularidadPorRegion() {
        return repository.obtenerPopularidadPorRegion();
    }

    public List<SitioCercanoResponse> obtenerSitiosCercanos(Double longitud, Double latitud) {
        Integer radio = 5000;
        return repository.findCercanos(longitud, latitud, radio);
    }
}
