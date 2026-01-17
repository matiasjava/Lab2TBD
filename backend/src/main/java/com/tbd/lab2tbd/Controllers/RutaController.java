package com.tbd.lab2tbd.Controllers;

import com.tbd.lab2tbd.Dto.RutaRequest;
import com.tbd.lab2tbd.Entities.Ruta;
import com.tbd.lab2tbd.Services.RutaService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/rutas")
@RequiredArgsConstructor
public class RutaController {
    
    private final RutaService service;

    @GetMapping
    public List<Ruta> getAll() {
        return service.getAll();
    }

    @PostMapping
    public ResponseEntity<Long> create(@RequestBody RutaRequest ruta) {
        return ResponseEntity.ok(service.create(ruta));
    }
}