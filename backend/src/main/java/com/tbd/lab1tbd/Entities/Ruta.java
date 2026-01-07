package com.tbd.lab1tbd.Entities;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.Date;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Ruta {
    private Long id;
    private String nombre;
    private String descripcion;
    private Long idUsuario;
    private String nombreUsuario;
    
    // GeoJSON crudo que nos entrega PostGIS
    private String geoJson; 
    
    // Longitud calculada por PostGIS
    private Double longitudKm;
    
    private Date fechaCreacion;
}