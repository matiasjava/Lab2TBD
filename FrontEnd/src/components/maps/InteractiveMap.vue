<template>
  <div class="interactive-map-container">
    <div class="map-filters">
      <div class="filters-header">
        <h3>Filtros</h3>
        <button @click="resetFilters" class="btn-reset">Limpiar</button>
      </div>

      <div class="filter-group">
        <label>Tipo de Lugar</label>
        <select v-model="filters.tipo" @change="applyFilters" class="filter-select">
          <option value="">Todos los tipos</option>
          <option value="Museo">Museo</option>
          <option value="Parque">Parque</option>
          <option value="Monumento">Monumento</option>
          <option value="Plaza">Plaza</option>
          <option value="Mirador">Mirador</option>
          <option value="Iglesia">Iglesia</option>
          <option value="Mercado">Mercado</option>
          <option value="Centro Cultural">Centro Cultural</option>
          <option value="Restaurante">Restaurante</option>
          <option value="Bar">Bar</option>
          <option value="Teatro">Teatro</option>
          <option value="Cafe">Cafe</option>
          <option value="Otro">Otro</option>
        </select>
      </div>

      <div class="filter-group">
        <label>Calificación Mínima</label>
        <select v-model="filters.calificacionMin" @change="applyFilters" class="filter-select">
          <option value="0">Todas las calificaciones</option>
          <option value="1">1+</option>
          <option value="2">2+</option>
          <option value="3">3+</option>
          <option value="4">4+</option>
          <option value="4.5">4.5+</option>
        </select>
      </div>

      <div class="filter-group">
        <label>Radio de Distancia</label>
        <select v-model="filters.distanciaMax" @change="applyFilters" class="filter-select">
          <option value="">Sin límite de distancia</option>
          <option value="1000">1 km</option>
          <option value="2000">2 km</option>
          <option value="5000">5 km</option>
          <option value="10000">10 km</option>
          <option value="20000">20 km</option>
        </select>
      </div>

      <button 
        @click="centerOnUser" 
        :disabled="!userLocation || gettingLocation"
        class="btn-location"
      >
        <span v-if="!gettingLocation">Mi Ubicación</span>
        <span v-else>Ubicando...</span>
      </button>

      <div class="filter-stats">
        <span class="stats-count">
          Mostrando <strong>{{ filteredSites.length }}</strong> de <strong>{{ allSites.length }}</strong> sitios
        </span>
      </div>
    </div>

    <div class="map-wrapper">
      <div v-if="loading" class="map-loading">
        <div class="spinner"></div>
        <p>Cargando sitios turísticos...</p>
      </div>

      <div v-else-if="error" class="map-error">
        <p>{{ error }}</p>
        <button @click="loadSites" class="btn-retry">Reintentar</button>
      </div>

      <l-map
        v-else-if="isReady"
        ref="mapRef"
        :zoom="zoom"
        :center="center"
        :options="mapOptions"
        class="leaflet-map"
        @ready="onMapReady"
      >
        <l-tile-layer
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        />

        <l-marker
          v-if="userLocation"
          :lat-lng="[userLocation.lat, userLocation.lng]"
          :icon="userIcon"
        >
          <l-popup>
            <div class="popup-content">
              <h4>Tu ubicación</h4>
              <p>Estás aquí</p>
            </div>
          </l-popup>
        </l-marker>

        <l-circle
          v-if="userLocation && filters.distanciaMax"
          :lat-lng="[userLocation.lat, userLocation.lng]"
          :radius="parseInt(filters.distanciaMax)"
          :options="circleOptions"
        />

        <l-marker
          v-for="site in filteredSites"
          :key="site.id"
          :lat-lng="[site.latitud, site.longitud]"
          :icon="getMarkerIcon(site.tipo)"
          @click="selectSite(site)"
        >
          <l-popup :options="{ maxWidth: 300 }">
            <div class="site-popup">
              <h4>{{ site.nombre }}</h4>
              <span class="popup-type">{{ site.tipo }}</span>
              <p class="popup-description">{{ truncateText(site.descripcion, 100) }}</p>
              
              <div class="popup-stats">
                <span class="popup-rating">
                  {{ site.calificacionPromedio ? site.calificacionPromedio.toFixed(1) : 'N/A' }} ★
                </span>
                <span class="popup-reviews">
                  {{ site.totalResenas || 0 }} reseñas
                </span>
              </div>

              <div class="popup-coords">
                {{ site.latitud.toFixed(4) }}, {{ site.longitud.toFixed(4) }}
              </div>

              <button @click="goToSiteDetail(site.id)" class="btn-view-site">
                Ver Detalles
              </button>
            </div>
          </l-popup>
        </l-marker>
      </l-map>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { LMap, LTileLayer, LMarker, LPopup, LCircle } from '@vue-leaflet/vue-leaflet'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import { sitesService } from '@/services/sitesService'

const router = useRouter()

const allSites = ref([])
const loading = ref(false)
const error = ref(null)
const mapRef = ref(null)
const zoom = ref(13)
const center = ref([-33.4489, -70.6693])
const userLocation = ref(null)
const gettingLocation = ref(false)
const isReady = ref(false)

const filters = ref({
  tipo: '',
  calificacionMin: 0,
  distanciaMax: ''
})

const mapOptions = {
  zoomControl: true,
  attributionControl: true,
  scrollWheelZoom: true
}

const circleOptions = {
  color: '#3498db',
  fillColor: '#3498db',
  fillOpacity: 0.1,
  weight: 2
}

const createCustomIcon = (color, symbol) => {
  return L.divIcon({
    html: `<div style="
      background-color: ${color};
      width: 32px;
      height: 32px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 16px;
      font-weight: bold;
      color: white;
      border: 3px solid white;
      box-shadow: 0 2px 8px rgba(0,0,0,0.3);
    ">${symbol}</div>`,
    className: 'custom-marker',
    iconSize: [32, 32],
    iconAnchor: [16, 16],
    popupAnchor: [0, -16]
  })
}

const userIcon = L.divIcon({
  html: `<div style="
    background-color: #e74c3c;
    width: 20px;
    height: 20px;
    border-radius: 50%;
    border: 4px solid white;
    box-shadow: 0 2px 8px rgba(0,0,0,0.4);
  "></div>`,
  className: 'user-marker',
  iconSize: [20, 20],
  iconAnchor: [10, 10]
})

const getMarkerIcon = (tipo) => {
  const iconMap = {
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

  const config = iconMap[tipo] || iconMap['Otro']
  return createCustomIcon(config.color, config.symbol)
}

const filteredSites = computed(() => {
  let sites = [...allSites.value]

  if (filters.value.tipo) {
    sites = sites.filter(s => s.tipo === filters.value.tipo)
  }

  if (filters.value.calificacionMin > 0) {
    sites = sites.filter(s => 
      s.calificacionPromedio >= filters.value.calificacionMin
    )
  }

  if (filters.value.distanciaMax && userLocation.value) {
    sites = sites.filter(s => {
      const distance = calculateDistance(
        userLocation.value.lat,
        userLocation.value.lng,
        s.latitud,
        s.longitud
      )
      return distance <= parseInt(filters.value.distanciaMax)
    })
  }

  return sites
})

const loadSites = async () => {
  loading.value = true
  error.value = null
  try {
    allSites.value = await sitesService.getAll()
  } catch (err) {
    error.value = 'Error al cargar sitios turísticos'
    console.error('Error cargando sitios:', err)
  } finally {
    loading.value = false
  }
}

const getUserLocation = () => {
  if (!navigator.geolocation) {
    console.warn('Geolocalización no disponible')
    return
  }

  gettingLocation.value = true

  navigator.geolocation.getCurrentPosition(
    (position) => {
      userLocation.value = {
        lat: position.coords.latitude,
        lng: position.coords.longitude
      }
      center.value = [userLocation.value.lat, userLocation.value.lng]
      zoom.value = 14
      gettingLocation.value = false
    },
    (err) => {
      console.warn('No se pudo obtener ubicación:', err)
      gettingLocation.value = false
    }
  )
}

const centerOnUser = () => {
  if (userLocation.value && mapRef.value?.leafletObject) {
    mapRef.value.leafletObject.setView(
      [userLocation.value.lat, userLocation.value.lng],
      14
    )
  }
}

const applyFilters = () => {
}

const resetFilters = () => {
  filters.value = {
    tipo: '',
    calificacionMin: 0,
    distanciaMax: ''
  }
}

const selectSite = (site) => {
  console.log('Sitio seleccionado:', site)
}

const goToSiteDetail = (siteId) => {
  router.push(`/sitios/${siteId}`)
}

const truncateText = (text, maxLength) => {
  if (!text) return 'Sin descripción'
  if (text.length <= maxLength) return text
  return text.substring(0, maxLength) + '...'
}

const calculateDistance = (lat1, lon1, lat2, lon2) => {
  const R = 6371e3
  const φ1 = lat1 * Math.PI / 180
  const φ2 = lat2 * Math.PI / 180
  const Δφ = (lat2 - lat1) * Math.PI / 180
  const Δλ = (lon2 - lon1) * Math.PI / 180

  const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
            Math.cos(φ1) * Math.cos(φ2) *
            Math.sin(Δλ / 2) * Math.sin(Δλ / 2)
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

  return R * c
}

const onMapReady = () => {
  console.log('Mapa listo')
}

onMounted(async () => {
  loadSites()
  getUserLocation()
  await nextTick()
  setTimeout(() => {
    isReady.value = true
  }, 100)
})
</script>

<style scoped>
.interactive-map-container {
  display: grid;
  grid-template-columns: 300px 1fr;
  gap: 1rem;
  height: 600px;
  background: white;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.map-filters {
  padding: 1.5rem;
  background: #f8f9fa;
  overflow-y: auto;
  border-right: 1px solid #e0e0e0;
}

.filters-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

.filters-header h3 {
  margin: 0;
  color: #2c3e50;
  font-size: 1.25rem;
}

.btn-reset {
  background: transparent;
  border: 1px solid #e74c3c;
  color: #e74c3c;
  padding: 0.4rem 0.8rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.875rem;
  transition: all 0.3s;
}

.btn-reset:hover {
  background: #e74c3c;
  color: white;
}

.filter-group {
  margin-bottom: 1.25rem;
}

.filter-group label {
  display: block;
  font-weight: 600;
  color: #34495e;
  margin-bottom: 0.5rem;
  font-size: 0.9rem;
}

.filter-select {
  width: 100%;
  padding: 0.6rem;
  border: 2px solid #e0e0e0;
  border-radius: 6px;
  font-size: 0.9rem;
  background: white;
  cursor: pointer;
  transition: border-color 0.3s;
}

.filter-select:focus {
  outline: none;
  border-color: #3498db;
}

.btn-location {
  width: 100%;
  padding: 0.75rem;
  background: #3498db;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 600;
  transition: background 0.3s;
  margin-bottom: 1rem;
}

.btn-location:hover:not(:disabled) {
  background: #2980b9;
}

.btn-location:disabled {
  background: #bdc3c7;
  cursor: not-allowed;
}

.filter-stats {
  padding: 1rem;
  background: white;
  border-radius: 6px;
  text-align: center;
}

.stats-count {
  font-size: 0.9rem;
  color: #7f8c8d;
}

.stats-count strong {
  color: #2c3e50;
  font-weight: 700;
}

.map-wrapper {
  position: relative;
  height: 100%;
}

.leaflet-map {
  height: 100%;
  width: 100%;
  z-index: 1;
}

.map-loading,
.map-error {
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

.map-loading p {
  color: #7f8c8d;
  font-size: 1rem;
}

.map-error p {
  color: #e74c3c;
  margin-bottom: 1rem;
  font-size: 1.1rem;
}

.btn-retry {
  padding: 0.6rem 1.2rem;
  background: #3498db;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 600;
  transition: background 0.3s;
}

.btn-retry:hover {
  background: #2980b9;
}

.site-popup {
  min-width: 200px;
}

.site-popup h4 {
  margin: 0 0 0.5rem 0;
  color: #2c3e50;
  font-size: 1.1rem;
}

.popup-type {
  display: inline-block;
  background: #3498db;
  color: white;
  padding: 0.2rem 0.6rem;
  border-radius: 4px;
  font-size: 0.75rem;
  font-weight: 600;
  margin-bottom: 0.5rem;
}

.popup-description {
  color: #7f8c8d;
  font-size: 0.85rem;
  margin: 0.5rem 0;
  line-height: 1.4;
}

.popup-stats {
  display: flex;
  gap: 1rem;
  margin: 0.75rem 0;
  font-size: 0.85rem;
}

.popup-rating,
.popup-reviews {
  color: #34495e;
}

.popup-coords {
  font-size: 0.75rem;
  color: #95a5a6;
  margin: 0.5rem 0;
}

.btn-view-site {
  width: 100%;
  padding: 0.6rem;
  background: #3498db;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 600;
  margin-top: 0.75rem;
  transition: background 0.3s;
}

.btn-view-site:hover {
  background: #2980b9;
}

@media (max-width: 768px) {
  .interactive-map-container {
    grid-template-columns: 1fr;
    height: auto;
  }

  .map-filters {
    border-right: none;
    border-bottom: 1px solid #e0e0e0;
    max-height: 400px;
  }

  .map-wrapper {
    height: 500px;
  }
}
</style>
