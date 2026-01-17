package com.tbd.lab2tbd.Dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO para Consulta #3: Proximidad entre sitios
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProximidadSitiosResponse {
    private String nombreTeatro;
    private String nombreRestaurante;
    private Double distanciaEnMetros;
}
