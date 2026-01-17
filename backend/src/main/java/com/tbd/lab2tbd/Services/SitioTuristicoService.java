package com.tbd.lab2tbd.Services;

import com.tbd.lab2tbd.Entities.SitioTuristico;
import com.tbd.lab2tbd.Dto.SitioTuristicoRequest;
import com.tbd.lab2tbd.Repositories.SitioTuristicoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class SitioTuristicoService {

    private final SitioTuristicoRepository repository;

    public List<SitioTuristico> getAll() {
        return repository.findAll();
    }

    public SitioTuristico getById(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Sitio Turístico no encontrado"));
    }

    public Long create(SitioTuristicoRequest sitio) {
        return repository.create(sitio);
    }

    public void update(Long id, SitioTuristicoRequest sitio) {
        // Primero, verificamos que exista
        getById(id); 
        // Si no lanza excepción, actualizamos
        repository.update(id, sitio);
    }

    public void delete(Long id) {
        if (repository.delete(id) == 0) {
            throw new RuntimeException("Sitio Turístico no encontrado");
        }
    }

    public List<SitioTuristico> getPopulares() {
        return repository.findPopulares();
    }

    public List<SitioTuristico> getByTipo(String tipo) {
        return repository.findByTipo(tipo);
    }


    /**
     * Busca sitios turísticos cercanos a una ubicación.
     *
     * @param longitud Longitud de la ubicación
     * @param latitud Latitud de la ubicación
     * @param radioMetros Radio de búsqueda en metros (por defecto 1000m = 1km)
     * @return Lista de sitios turísticos cercanos
     */
    public List<SitioTuristico> getCercanos(Double longitud, Double latitud, Integer radioMetros) {
        // Validación de parámetros
        if (longitud == null || latitud == null) {
            throw new IllegalArgumentException("Longitud y latitud son requeridas");
        }

        // Si no se especifica radio, usar 1000 metros (1 km) por defecto
        if (radioMetros == null || radioMetros <= 0) {
            radioMetros = 1000;
        }

        // Limitar el radio máximo a 50 km para evitar consultas muy costosas
        if (radioMetros > 50000) {
            throw new IllegalArgumentException("El radio máximo permitido es 50000 metros (50 km)");
        }

        return repository.findCercanos(longitud, latitud, radioMetros);
    }

    /**
     * Busca sitios turísticos dentro de una zona definida por un polígono.
     *
     * @param puntos Lista de puntos [[lat, lon], [lat, lon], ...] que definen el polígono
     * @return Lista de sitios turísticos dentro del polígono
     */
    public List<SitioTuristico> getEnZona(List<List<Double>> puntos) {
        if (puntos == null || puntos.size() < 3) {
            throw new IllegalArgumentException("Se requieren al menos 3 puntos para un polígono");
        }
        return repository.findEnZona(puntos);
    }
}
