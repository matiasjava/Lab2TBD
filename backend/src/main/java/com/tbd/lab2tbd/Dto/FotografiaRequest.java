package com.tbd.lab2tbd.Dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO para la petición de subir una nueva fotografía.
 * Solo contiene la URL.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class FotografiaRequest {
    private String url;
}
