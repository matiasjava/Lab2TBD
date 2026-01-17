package com.tbd.lab2tbd.Dto;

import lombok.Data;
import java.util.List;

@Data
public class ZonaBusquedaRequest {
    // Lista de puntos que forman el polígono: [[lat, lon], ...]
    private List<List<Double>> puntos;
}