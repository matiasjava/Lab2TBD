package com.tbd.lab2tbd.Dto;

public class EstadisticasPorRegionResponse {
    private String region;
    private Long totalResenas;

    public EstadisticasPorRegionResponse(String region, Long totalResenas) {
        this.region = region;
        this.totalResenas = totalResenas;
    }

    // Getters y Setters
    public String getRegion() { return region; }
    public void setRegion(String region) { this.region = region; }
    public Long getTotalResenas() { return totalResenas; }
    public void setTotalResenas(Long totalResenas) { this.totalResenas = totalResenas; }
}