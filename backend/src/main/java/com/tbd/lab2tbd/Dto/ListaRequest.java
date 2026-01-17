package com.tbd.lab2tbd.Dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

// DTO para crear o actualizar una lista
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ListaRequest {
    private String nombre;
}