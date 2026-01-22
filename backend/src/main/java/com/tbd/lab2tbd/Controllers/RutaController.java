package com.tbd.lab2tbd.Controllers;

import com.tbd.lab2tbd.Dto.RutaRequest;
import com.tbd.lab2tbd.Entities.Ruta;
import com.tbd.lab2tbd.Services.RutaService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/rutas")
@RequiredArgsConstructor
public class RutaController {

    private final RutaService service;

    /**
     * Consulta #4: Si existen rutas guardadas, calcular la longitud total del recorrido en kilómetros usando ST_Length.
     */
    @GetMapping
    public ResponseEntity<List<Ruta>> getAll() {
        try {
            List<Ruta> rutas = service.getAll();
            System.out.println("Rutas encontradas: " + rutas.size());
            return ResponseEntity.ok(rutas);
        } catch (Exception e) {
            System.err.println("Error en getAll rutas: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(List.of());
        }
    }

    @PostMapping
    public ResponseEntity<?> create(@RequestBody RutaRequest ruta) {
        try {
            Long id = service.create(ruta);
            System.out.println("Ruta creada con ID: " + id);
            return ResponseEntity.ok(id);
        } catch (IllegalArgumentException e) {
            System.err.println("Error de validación: " + e.getMessage());
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            System.err.println("Error al crear ruta: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Error al crear la ruta");
        }
    }
}