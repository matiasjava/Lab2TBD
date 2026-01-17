package com.tbd.lab2tbd.Dto;

import com.tbd.lab2tbd.Entities.SitioTuristico;
import lombok.Data;

@Data
public class SitioCercanoResponse {
    private SitioTuristico sitio;
    private Double distanciaEnMetros;
}
