<template>
  <div class="zone-search-container">
    <div class="page-header">
      <h1>Buscar en Zona Personalizada</h1>
      <p class="subtitle">Dibuja un polígono en el mapa para encontrar sitios turísticos dentro del área</p>
    </div>

    <div class="map-section">
      <div class="controls-panel">
        <div class="instructions">
          <h3>Instrucciones</h3>
          <ol>
            <li>Haz clic en el mapa para agregar puntos del polígono</li>
            <li>Necesitas al menos 3 puntos para formar un área</li>
            <li>Presiona "Buscar en Zona" cuando termines</li>
          </ol>
        </div>

        <div class="polygon-info">
          <span class="point-count">
            Puntos: <strong>{{ polygonPoints.length }}</strong>
          </span>
          <span v-if="polygonPoints.length >= 3" class="ready-badge">
            Listo para buscar
          </span>
        </div>

        <div class="control-buttons">
          <button
            @click="searchInZone"
            :disabled="polygonPoints.length < 3 || loading"
            class="btn btn-primary"
          >
            <span v-if="loading">Buscando...</span>
            <span v-else>Buscar en Zona</span>
          </button>

          <button
            @click="clearPolygon"
            :disabled="polygonPoints.length === 0"
            class="btn btn-secondary"
          >
            Limpiar Polígono
          </button>

          <button
            @click="undoLastPoint"
            :disabled="polygonPoints.length === 0"
            class="btn btn-outline"
          >
            Deshacer Último Punto
          </button>
        </div>

        <div v-if="searchResults.length > 0" class="results-summary">
          <h4>Resultados</h4>
          <p>Se encontraron <strong>{{ searchResults.length }}</strong> sitios en la zona</p>
        </div>
      </div>

      <div class="map-wrapper">
        <div v-if="!isMapReady" class="map-loading">
          <div class="spinner"></div>
          <p>Cargando mapa...</p>
        </div>

        <l-map
          v-if="isMapReady"
          ref="mapRef"
          :zoom="zoom"
          :center="center"
          :options="mapOptions"
          class="leaflet-map"
          @click="onMapClick"
        >
          <l-tile-layer
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          />

          <!-- Marcadores de los puntos del polígono -->
          <l-marker
            v-for="(point, index) in polygonPoints"
            :key="'point-' + index"
            :lat-lng="point"
            :icon="getPointIcon(index)"
          >
            <l-popup>
              <div class="point-popup">
                <strong>Punto {{ index + 1 }}</strong>
                <p>{{ point[0].toFixed(4) }}, {{ point[1].toFixed(4) }}</p>
                <button @click="removePoint(index)" class="btn-remove-point">
                  Eliminar punto
                </button>
              </div>
            </l-popup>
          </l-marker>

          <!-- Polígono dibujado -->
          <l-polygon
            v-if="polygonPoints.length >= 3"
            :lat-lngs="polygonPoints"
            :options="polygonOptions"
          />

          <!-- Líneas conectando los puntos mientras se dibuja -->
          <l-polyline
            v-if="polygonPoints.length >= 2 && polygonPoints.length < 3"
            :lat-lngs="polygonPoints"
            :options="lineOptions"
          />

          <!-- Marcadores de sitios encontrados -->
          <l-marker
            v-for="site in searchResults"
            :key="'site-' + site.id"
            :lat-lng="[site.latitud, site.longitud]"
            :icon="getSiteIcon(site.tipo)"
          >
            <l-popup :options="{ maxWidth: 300 }">
              <div class="site-popup">
                <h4>{{ site.nombre }}</h4>
                <span class="site-type">{{ site.tipo }}</span>
                <p class="site-description">{{ truncateText(site.descripcion, 100) }}</p>
                <div class="site-stats">
                  <span class="rating">{{ site.calificacionPromedio?.toFixed(1) || 'N/A' }} ★</span>
                  <span class="reviews">{{ site.totalreseñas || 0 }} reseñas</span>
                </div>
                <router-link :to="`/sitios/${site.id}`" class="btn-view-detail">
                  Ver Detalles
                </router-link>
              </div>
            </l-popup>
          </l-marker>
        </l-map>
      </div>
    </div>

    <!-- Lista de resultados -->
    <div v-if="searchResults.length > 0" class="results-section">
      <h2>Sitios Encontrados en la Zona</h2>
      <div class="results-grid">
        <div
          v-for="site in searchResults"
          :key="site.id"
          class="site-card"
          @click="goToSite(site.id)"
        >
          <div class="site-card-header">
            <h3>{{ site.nombre }}</h3>
            <span class="type-badge">{{ site.tipo }}</span>
          </div>
          <p class="site-card-description">{{ truncateText(site.descripcion, 150) }}</p>
          <div class="site-card-footer">
            <span class="rating">{{ site.calificacionPromedio?.toFixed(1) || 'N/A' }} ★</span>
            <span class="reviews">{{ site.totalreseñas || 0 }} reseñas</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Mensaje cuando no hay resultados -->
    <div v-if="hasSearched && searchResults.length === 0" class="no-results">
      <p>No se encontraron sitios turísticos en la zona seleccionada.</p>
      <p>Intenta dibujar un área más grande o en otra ubicación.</p>
    </div>

    <!-- Mensaje de error -->
    <div v-if="error" class="error-message">
      <p>{{ error }}</p>
      <button @click="error = null" class="btn btn-secondary">Cerrar</button>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { LMap, LTileLayer, LMarker, LPopup, LPolygon, LPolyline } from '@vue-leaflet/vue-leaflet'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import { sitesService } from '@/services/sitesService'

const router = useRouter()

const mapRef = ref(null)
const zoom = ref(13)
const center = ref([-33.4489, -70.6693])
const isMapReady = ref(false)

const polygonPoints = ref([])
const searchResults = ref([])
const loading = ref(false)
const error = ref(null)
const hasSearched = ref(false)

const mapOptions = {
  zoomControl: true,
  attributionControl: true,
  scrollWheelZoom: true
}

const polygonOptions = {
  color: '#3498db',
  fillColor: '#3498db',
  fillOpacity: 0.2,
  weight: 3
}

const lineOptions = {
  color: '#3498db',
  weight: 2,
  dashArray: '5, 10'
}

const getPointIcon = (index) => {
  const isFirst = index === 0
  const color = isFirst ? '#27ae60' : '#3498db'
  const label = index + 1

  return L.divIcon({
    html: `<div style="
      background-color: ${color};
      width: 28px;
      height: 28px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 12px;
      font-weight: bold;
      color: white;
      border: 3px solid white;
      box-shadow: 0 2px 8px rgba(0,0,0,0.3);
    ">${label}</div>`,
    className: 'polygon-point-marker',
    iconSize: [28, 28],
    iconAnchor: [14, 14]
  })
}

const getSiteIcon = (tipo) => {
  const iconConfig = {
    'Museo': { color: '#9b59b6', symbol: 'M' },
    'Parque': { color: '#27ae60', symbol: 'P' },
    'Monumento': { color: '#e67e22', symbol: 'M' },
    'Plaza': { color: '#f39c12', symbol: 'P' },
    'Mirador': { color: '#16a085', symbol: 'V' },
    'Iglesia': { color: '#8e44ad', symbol: 'I' },
    'Mercado': { color: '#d35400', symbol: 'M' },
    'Centro Cultural': { color: '#c0392b', symbol: 'C' },
    'Restaurante': { color: '#e74c3c', symbol: 'R' },
    'Bar': { color: '#2c3e50', symbol: 'B' },
    'Teatro': { color: '#3498db', symbol: 'T' },
    'Cafe': { color: '#d68910', symbol: 'C' },
    'Otro': { color: '#7f8c8d', symbol: '•' }
  }

  const config = iconConfig[tipo] || iconConfig['Otro']

  return L.divIcon({
    html: `<div style="
      background-color: ${config.color};
      width: 32px;
      height: 32px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 14px;
      font-weight: bold;
      color: white;
      border: 3px solid white;
      box-shadow: 0 2px 8px rgba(0,0,0,0.3);
    ">${config.symbol}</div>`,
    className: 'site-marker',
    iconSize: [32, 32],
    iconAnchor: [16, 16],
    popupAnchor: [0, -16]
  })
}

const onMapClick = (e) => {
  const { lat, lng } = e.latlng
  polygonPoints.value.push([lat, lng])
}

const removePoint = (index) => {
  polygonPoints.value.splice(index, 1)
}

const undoLastPoint = () => {
  if (polygonPoints.value.length > 0) {
    polygonPoints.value.pop()
  }
}

const clearPolygon = () => {
  polygonPoints.value = []
  searchResults.value = []
  hasSearched.value = false
  error.value = null
}

const searchInZone = async () => {
  if (polygonPoints.value.length < 3) {
    error.value = 'Necesitas al menos 3 puntos para definir una zona'
    return
  }

  loading.value = true
  error.value = null
  hasSearched.value = true

  try {
    const puntos = polygonPoints.value.map(p => [p[0], p[1]])
    searchResults.value = await sitesService.searchInZone(puntos)

    if (searchResults.value.length > 0 && mapRef.value?.leafletObject) {
      const bounds = L.latLngBounds(polygonPoints.value)
      mapRef.value.leafletObject.fitBounds(bounds, { padding: [50, 50] })
    }
  } catch (err) {
    console.error('Error buscando en zona:', err)
    error.value = 'Error al buscar sitios en la zona. Intenta nuevamente.'
  } finally {
    loading.value = false
  }
}

const goToSite = (id) => {
  router.push(`/sitios/${id}`)
}

const truncateText = (text, maxLength) => {
  if (!text) return 'Sin descripción'
  if (text.length <= maxLength) return text
  return text.substring(0, maxLength) + '...'
}

onMounted(async () => {
  await nextTick()
  setTimeout(() => {
    isMapReady.value = true
  }, 100)
})
</script>

<style scoped>
.zone-search-container {
  max-width: 1400px;
  margin: 0 auto;
  padding: 2rem;
}

.page-header {
  margin-bottom: 2rem;
}

.page-header h1 {
  color: #2c3e50;
  margin-bottom: 0.5rem;
}

.subtitle {
  color: #7f8c8d;
  font-size: 1.1rem;
}

.map-section {
  display: grid;
  grid-template-columns: 300px 1fr;
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.controls-panel {
  background: #f8f9fa;
  border-radius: 12px;
  padding: 1.5rem;
  height: fit-content;
}

.instructions {
  margin-bottom: 1.5rem;
}

.instructions h3 {
  color: #2c3e50;
  margin-bottom: 0.75rem;
  font-size: 1rem;
}

.instructions ol {
  padding-left: 1.25rem;
  color: #5a6c7d;
  font-size: 0.9rem;
  line-height: 1.6;
}

.polygon-info {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 1.5rem;
  padding: 0.75rem;
  background: white;
  border-radius: 8px;
}

.point-count {
  color: #5a6c7d;
  font-size: 0.95rem;
}

.ready-badge {
  background: #27ae60;
  color: white;
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  font-size: 0.8rem;
  font-weight: 600;
}

.control-buttons {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.btn {
  padding: 0.75rem 1rem;
  border: none;
  border-radius: 8px;
  font-size: 0.95rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-primary {
  background: #3498db;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #2980b9;
}

.btn-secondary {
  background: #e74c3c;
  color: white;
}

.btn-secondary:hover:not(:disabled) {
  background: #c0392b;
}

.btn-outline {
  background: white;
  color: #5a6c7d;
  border: 2px solid #e0e0e0;
}

.btn-outline:hover:not(:disabled) {
  border-color: #3498db;
  color: #3498db;
}

.results-summary {
  margin-top: 1.5rem;
  padding: 1rem;
  background: #d5f4e6;
  border-radius: 8px;
}

.results-summary h4 {
  color: #27ae60;
  margin-bottom: 0.25rem;
}

.results-summary p {
  color: #2d6a4f;
  margin: 0;
}

.map-wrapper {
  height: 600px;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  position: relative;
}

.leaflet-map {
  height: 100%;
  width: 100%;
  cursor: crosshair;
}

.map-loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  background: #f8f9fa;
}

.spinner {
  border: 4px solid #f3f3f3;
  border-top: 4px solid #3498db;
  border-radius: 50%;
  width: 50px;
  height: 50px;
  animation: spin 1s linear infinite;
  margin-bottom: 1rem;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.point-popup {
  text-align: center;
}

.point-popup p {
  color: #7f8c8d;
  font-size: 0.85rem;
  margin: 0.5rem 0;
}

.btn-remove-point {
  background: #e74c3c;
  color: white;
  border: none;
  padding: 0.4rem 0.8rem;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.8rem;
}

.site-popup {
  min-width: 200px;
}

.site-popup h4 {
  margin: 0 0 0.5rem;
  color: #2c3e50;
}

.site-type {
  display: inline-block;
  background: #3498db;
  color: white;
  padding: 0.2rem 0.6rem;
  border-radius: 4px;
  font-size: 0.75rem;
  font-weight: 600;
}

.site-description {
  color: #7f8c8d;
  font-size: 0.85rem;
  margin: 0.5rem 0;
}

.site-stats {
  display: flex;
  gap: 1rem;
  margin: 0.5rem 0;
  font-size: 0.85rem;
  color: #5a6c7d;
}

.btn-view-detail {
  display: block;
  width: 100%;
  padding: 0.5rem;
  background: #3498db;
  color: white;
  text-align: center;
  text-decoration: none;
  border-radius: 6px;
  margin-top: 0.75rem;
  font-weight: 600;
  font-size: 0.9rem;
}

.results-section {
  margin-top: 2rem;
}

.results-section h2 {
  color: #2c3e50;
  margin-bottom: 1.5rem;
}

.results-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1.5rem;
}

.site-card {
  background: white;
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  cursor: pointer;
  transition: transform 0.3s, box-shadow 0.3s;
}

.site-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
}

.site-card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 0.75rem;
}

.site-card-header h3 {
  margin: 0;
  color: #2c3e50;
  font-size: 1.1rem;
}

.type-badge {
  background: #e8f4fc;
  color: #3498db;
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  font-size: 0.8rem;
  font-weight: 600;
}

.site-card-description {
  color: #7f8c8d;
  font-size: 0.9rem;
  line-height: 1.5;
  margin-bottom: 1rem;
}

.site-card-footer {
  display: flex;
  gap: 1rem;
  color: #5a6c7d;
  font-size: 0.9rem;
}

.no-results {
  text-align: center;
  padding: 3rem;
  background: #f8f9fa;
  border-radius: 12px;
  color: #7f8c8d;
}

.error-message {
  position: fixed;
  bottom: 2rem;
  right: 2rem;
  background: #e74c3c;
  color: white;
  padding: 1rem 1.5rem;
  border-radius: 8px;
  display: flex;
  align-items: center;
  gap: 1rem;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
}

.error-message p {
  margin: 0;
}

.error-message .btn-secondary {
  padding: 0.4rem 0.8rem;
  font-size: 0.85rem;
}

@media (max-width: 900px) {
  .map-section {
    grid-template-columns: 1fr;
  }

  .controls-panel {
    order: 2;
  }

  .map-wrapper {
    order: 1;
    height: 450px;
  }
}

@media (max-width: 600px) {
  .zone-search-container {
    padding: 1rem;
  }

  .results-grid {
    grid-template-columns: 1fr;
  }
}
</style>
