<template>
  <div class="mini-map-container">
    <l-map
      v-if="latitude && longitude"
      :zoom="zoom"
      :center="[latitude, longitude]"
      :options="mapOptions"
      class="mini-map"
    >
      <l-tile-layer
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
      />
      
      <l-marker
        :lat-lng="[latitude, longitude]"
        :icon="markerIcon"
      >
        <l-popup v-if="siteName">
          <div class="popup-mini">
            <strong>{{ siteName }}</strong>
            <p class="popup-coords">{{ latitude.toFixed(4) }}, {{ longitude.toFixed(4) }}</p>
          </div>
        </l-popup>
      </l-marker>
    </l-map>
    
    <div v-else class="mini-map-error">
      <p>Coordenadas no disponibles</p>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { LMap, LTileLayer, LMarker, LPopup } from '@vue-leaflet/vue-leaflet'
import L from 'leaflet'

const props = defineProps({
  latitude: {
    type: Number,
    required: false,
    default: null
  },
  longitude: {
    type: Number,
    required: false,
    default: null
  },
  siteName: {
    type: String,
    required: false,
    default: ''
  },
  zoom: {
    type: Number,
    default: 15
  }
})

const mapOptions = {
  zoomControl: true,
  attributionControl: true,
  scrollWheelZoom: false,
  dragging: true,
  doubleClickZoom: true
}

const markerIcon = L.divIcon({
  html: `<div style="
    background-color: #e74c3c;
    width: 30px;
    height: 30px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 14px;
    font-weight: bold;
    color: white;
    border: 3px solid white;
    box-shadow: 0 2px 8px rgba(0,0,0,0.3);
  ">•</div>`,
  className: 'mini-map-marker',
  iconSize: [30, 30],
  iconAnchor: [15, 15],
  popupAnchor: [0, -15]
})
</script>

<style scoped>
.mini-map-container {
  width: 100%;
  height: 300px;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.mini-map {
  width: 100%;
  height: 100%;
}

.mini-map-error {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #f8f9fa;
  color: #7f8c8d;
  font-size: 0.9rem;
}

.popup-mini {
  text-align: center;
}

.popup-mini strong {
  display: block;
  margin-bottom: 0.25rem;
  color: #2c3e50;
}

.popup-coords {
  margin: 0;
  font-size: 0.75rem;
  color: #7f8c8d;
}
</style>
