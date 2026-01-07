package com.tbd.lab1tbd.Dto;

import lombok.Data;
import java.util.List;

@Data
public class RutaRequest {
    private String nombre;
    private String descripcion;
    private Long idUsuario;
    
    // Recibiremos una lista de puntos: [[lat1, lon1], [lat2, lon2], ...]
    private List<List<Double>> coordenadas; 
}