package com.tbd.lab2tbd.Services;

import com.tbd.lab2tbd.Dto.RutaRequest;
import com.tbd.lab2tbd.Entities.Ruta;
import com.tbd.lab2tbd.Repositories.RutaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
@RequiredArgsConstructor
public class RutaService {
    private final RutaRepository repository;

    public List<Ruta> getAll() {
        return repository.findAll();
    }

    public Long create(RutaRequest request) {
        if (request.getCoordenadas() == null || request.getCoordenadas().size() < 2) {
            throw new IllegalArgumentException("Una ruta necesita al menos 2 puntos");
        }
        return repository.create(request);
    }
}