<template>
  <div class="routes-container">
    <div class="header-row">
      <h2 class="title">Rutas Turísticas</h2>
      <button @click="$router.push('/rutas/crear')" class="btn-add">
        + Agregar Nueva Ruta
      </button>
    </div>

    <div v-if="loading" class="loading">
      <div class="spinner"></div>
      <p>Cargando</p>
    </div>

    <div v-else-if="error" class="error-message">
      <p>{{ error }}</p>
      <button @click="fetchRutas" class="retry-btn">Reintentar</button>
    </div>

    <div v-else-if="rutas.length === 0" class="empty">
      <div class="empty-icon">📍</div>
      <p>No hay rutas disponibles.</p>
      <button @click="fetchRutas" class="retry-btn">Actualizar</button>
    </div>

    <div v-else class="content-wrapper">
      <div class="map-section">
        <div class="map-container">
          <l-map
            ref="mapRef"
            :zoom="zoom"
            :center="center"
            :options="mapOptions"
            class="leaflet-map"
          >
            <l-tile-layer
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
            />

            <l-polyline
              v-for="ruta in rutas"
              :key="'route-' + ruta.id"
              :lat-lngs="getRouteCoordinates(ruta)"
              :options="ruta.id === selectedRuta?.id ? selectedRouteStyle : defaultRouteStyle"
              @click="selectRuta(ruta)"
            />

            <template v-if="selectedRuta && selectedRouteCoords.length > 0">
              <l-marker :lat-lng="selectedRouteCoords[0]" :icon="startIcon">
                <l-popup>
                  <strong>Inicio</strong><br>{{ selectedRuta.nombre }}
                </l-popup>
              </l-marker>
              <l-marker :lat-lng="selectedRouteCoords[selectedRouteCoords.length - 1]" :icon="endIcon">
                <l-popup>
                  <strong>Fin</strong><br>{{ selectedRuta.nombre }}
                </l-popup>
              </l-marker>
            </template>
          </l-map>
        </div>

        <div v-if="selectedRuta" class="selected-route-info">
          <button class="close-btn" @click="selectedRuta = null">&times;</button>
          <h3>{{ selectedRuta.nombre }}</h3>
          <p class="selected-description">{{ selectedRuta.descripcion }}</p>
          <div class="selected-stats">
            <div class="stat">
              <span class="stat-value">{{ formatDistance(selectedRuta.longitudKm) }}</span>
              <span class="stat-label">Distancia</span>
            </div>
            <div class="stat">
              <span class="stat-value">{{ selectedRouteCoords.length }}</span>
              <span class="stat-label">Puntos</span>
            </div>
          </div>
          <div class="selected-meta">
            <span>Por {{ selectedRuta.nombreUsuario || 'Usuario' }}</span>
            <span>{{ formatDate(selectedRuta.fechaCreacion) }}</span>
          </div>
        </div>
      </div>

      <div class="routes-grid">
        <div
          v-for="ruta in rutas"
          :key="ruta.id"
          class="route-card"
          :class="{ 'selected': selectedRuta?.id === ruta.id }"
          @click="selectRuta(ruta)"
        >
          <div class="card-header">
            <h3>{{ ruta.nombre }}</h3>
            <span class="route-id">#{{ ruta.id }}</span>
          </div>

          <p class="description">{{ ruta.descripcion }}</p>

          <div class="distance-section">
            <div class="distance-badge">
              {{ formatDistance(ruta.longitudKm) }}
            </div>
            <div class="distance-detail">
              Calculado con ST_Length de PostGIS
            </div>
          </div>

          <div class="card-footer">
            <span class="author">{{ ruta.nombreUsuario || 'Usuario' }}</span>
            <span class="date">{{ formatDate(ruta.fechaCreacion) }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import { LMap, LTileLayer, LPolyline, LMarker, LPopup } from '@vue-leaflet/vue-leaflet'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import axios from 'axios'

const mapRef = ref(null)
const zoom = ref(13)
const center = ref([-33.4489, -70.6693])
const rutas = ref([])
const selectedRuta = ref(null)
const loading = ref(true)
const error = ref(null)

const API_URL = 'http://localhost:8090/api/rutas'

const mapOptions = {
  zoomControl: true,
  scrollWheelZoom: true
}

const defaultRouteStyle = {
  color: '#95a5a6',
  weight: 4,
  opacity: 0.7
}

const selectedRouteStyle = {
  color: '#e74c3c',
  weight: 6,
  opacity: 1
}

const startIcon = L.divIcon({
  html: '<div style="background:#27ae60;width:28px;height:28px;border-radius:50%;display:flex;align-items:center;justify-content:center;color:white;font-weight:bold;border:3px solid white;box-shadow:0 2px 6px rgba(0,0,0,0.3);">A</div>',
  className: 'route-marker',
  iconSize: [28, 28],
  iconAnchor: [14, 14]
})

const endIcon = L.divIcon({
  html: '<div style="background:#e74c3c;width:28px;height:28px;border-radius:50%;display:flex;align-items:center;justify-content:center;color:white;font-weight:bold;border:3px solid white;box-shadow:0 2px 6px rgba(0,0,0,0.3);">B</div>',
  className: 'route-marker',
  iconSize: [28, 28],
  iconAnchor: [14, 14]
})

const selectedRouteCoords = computed(() => {
  if (!selectedRuta.value) return []
  return getRouteCoordinates(selectedRuta.value)
})

const getRouteCoordinates = (ruta) => {
  if (!ruta.geoJson) return []
  try {
    const geo = JSON.parse(ruta.geoJson)
    if (geo.type === 'LineString' && geo.coordinates) {
      return geo.coordinates.map(coord => [coord[1], coord[0]])
    }
  } catch (e) {
    console.error('Error parsing geoJson:', e)
  }
  return []
}

const selectRuta = (ruta) => {
  selectedRuta.value = ruta
  const coords = getRouteCoordinates(ruta)
  if (coords.length > 0 && mapRef.value?.leafletObject) {
    const bounds = L.latLngBounds(coords)
    mapRef.value.leafletObject.fitBounds(bounds, { padding: [50, 50] })
  }
}

const formatDistance = (dist) => {
  if (!dist || dist === 0) return '0 km'
  return `${parseFloat(dist).toFixed(2)} km`
}

const formatDate = (fecha) => {
  if (!fecha) return ''
  const date = new Date(fecha)
  return date.toLocaleDateString('es-CL', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
}

const fetchRutas = async () => {
  loading.value = true
  error.value = null

  try {
    const response = await axios.get(API_URL)
    rutas.value = response.data

    await nextTick()
    if (rutas.value.length > 0) {
      selectRuta(rutas.value[0])
    }
  } catch (err) {
    if (err.response) {
      error.value = `Error del servidor: ${err.response.status}`
    } else if (err.request) {
      error.value = 'No se pudo conectar con el servidor'
    } else {
      error.value = `Error: ${err.message}`
    }
  } finally {
    loading.value = false
  }
}

onMounted(fetchRutas)
</script>

<style scoped>
.routes-container {
  padding: 20px;
  max-width: 1400px;
  margin: 0 auto;
}

.header-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.title {
  margin: 0;
  color: #2c3e50;
  font-size: 2rem;
  font-weight: 600;
}

.btn-add {
  background-color: #27ae60;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 6px;
  font-weight: 600;
  font-size: 1rem;
  cursor: pointer;
  transition: background-color 0.2s;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}

.btn-add:hover {
  background-color: #219150;
}

.content-wrapper {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.map-section {
  position: relative;
}

.map-container {
  height: 450px;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}

.leaflet-map {
  height: 100%;
  width: 100%;
}

.selected-route-info {
  position: absolute;
  bottom: 16px;
  left: 16px;
  background: white;
  border-radius: 10px;
  padding: 16px;
  max-width: 320px;
  box-shadow: 0 4px 16px rgba(0,0,0,0.15);
  z-index: 1000;
}

.selected-route-info h3 {
  margin: 0 0 8px;
  color: #2c3e50;
  padding-right: 24px;
}

.close-btn {
  position: absolute;
  top: 8px;
  right: 12px;
  background: none;
  border: none;
  font-size: 1.4rem;
  color: #95a5a6;
  cursor: pointer;
}

.close-btn:hover {
  color: #e74c3c;
}

.selected-description {
  color: #7f8c8d;
  font-size: 0.9rem;
  margin: 0 0 12px;
  line-height: 1.4;
}

.selected-stats {
  display: flex;
  gap: 24px;
  margin-bottom: 12px;
}

.stat {
  display: flex;
  flex-direction: column;
}

.stat-value {
  font-size: 1.3rem;
  font-weight: 700;
  color: #e74c3c;
}

.stat-label {
  font-size: 0.75rem;
  color: #95a5a6;
  text-transform: uppercase;
}

.selected-meta {
  display: flex;
  justify-content: space-between;
  font-size: 0.85rem;
  color: #7f8c8d;
  padding-top: 10px;
  border-top: 1px solid #eee;
}

.routes-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 20px;
}

.route-card {
  background: white;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  border-left: 4px solid #95a5a6;
  transition: all 0.2s;
  cursor: pointer;
}

.route-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(0,0,0,0.15);
}

.route-card.selected {
  border-left-color: #e74c3c;
  background: #fef5f5;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 10px;
}

.card-header h3 {
  margin: 0;
  color: #2c3e50;
  font-size: 1.1rem;
  flex: 1;
}

.route-id {
  background: #ecf0f1;
  padding: 3px 8px;
  border-radius: 10px;
  font-size: 0.8rem;
  color: #7f8c8d;
  font-weight: 600;
}

.description {
  color: #555;
  line-height: 1.5;
  margin: 10px 0;
  font-size: 0.9rem;
}

.distance-section {
  margin: 12px 0;
  padding: 10px;
  background: #f8f9fa;
  border-radius: 8px;
}

.distance-badge {
  font-weight: bold;
  font-size: 1.1rem;
  color: #27ae60;
  margin-bottom: 2px;
}

.distance-detail {
  font-size: 0.7rem;
  color: #7f8c8d;
  font-style: italic;
}

.card-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid #ecf0f1;
  font-size: 0.85rem;
}

.author {
  color: #34495e;
  font-weight: 500;
}

.date {
  color: #95a5a6;
}

.loading {
  text-align: center;
  margin-top: 80px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 20px;
}

.spinner {
  border: 4px solid #f3f3f3;
  border-top: 4px solid #3498db;
  border-radius: 50%;
  width: 50px;
  height: 50px;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.loading p {
  font-size: 1.1rem;
  color: #7f8c8d;
}

.error-message {
  text-align: center;
  margin-top: 60px;
  padding: 30px;
  background: #fee;
  border-radius: 12px;
  border: 2px solid #e74c3c;
}

.error-message p {
  color: #c0392b;
  font-size: 1.1rem;
  margin-bottom: 20px;
}

.retry-btn {
  background: #3498db;
  color: white;
  border: none;
  padding: 12px 24px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 1rem;
  font-weight: 600;
  transition: background 0.3s;
}

.retry-btn:hover {
  background: #2980b9;
}

.empty {
  text-align: center;
  margin-top: 80px;
  color: #7f8c8d;
}

.empty-icon {
  font-size: 4rem;
  margin-bottom: 20px;
}

.empty p {
  font-size: 1.2rem;
  margin: 10px 0;
}

@media (max-width: 768px) {
  .header-row {
    flex-direction: column;
    gap: 15px;
    text-align: center;
  }
  
  .map-container {
    height: 350px;
  }

  .selected-route-info {
    left: 8px;
    right: 8px;
    bottom: 8px;
    max-width: none;
  }

  .routes-grid {
    grid-template-columns: 1fr;
  }
}
</style>