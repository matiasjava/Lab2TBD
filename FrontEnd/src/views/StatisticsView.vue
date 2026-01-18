<template>
  <div class="statistics-view">
    <Navbar />

    <div class="header">
      <h1>📊 Panel de Estadísticas</h1>
      <p class="subtitle">Consultas SQL del Enunciado del Laboratorio</p>
    </div>

    <div class="reload-section">
      <button @click="loadAllStatistics" :disabled="loading" class="btn-reload">
        <span v-if="!loading">🔄 Recargar Estadísticas Generales</span>
        <span v-else>⏳ Cargando...</span>
      </button>
    </div>

    <ErrorMessage v-if="error" :message="error" @close="error = null" />

    <div class="stats-grid">

      <div class="stat-card full-width">
        <h2>🗺️ Consulta #1: Sitios Cercanos</h2>
        <p class="description">
          Usa tu ubicación o haz clic en el mapa para buscar sitios en un radio de 5km.
        </p>

        <div class="map-wrapper mb-3">
           <l-map 
             v-if="mapReady"
             v-model:zoom="zoom" 
             :center="center" 
             :use-global-leaflet="false" 
             @click="onMapClick"
             class="map-container"
           >
             <l-tile-layer
               url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
               layer-type="base"
               name="OpenStreetMap"
             ></l-tile-layer>
             
             <l-marker 
               v-if="searchParams.latitud && searchParams.longitud" 
               :lat-lng="[searchParams.latitud, searchParams.longitud]"
             >
               <l-tooltip>Centro de Búsqueda</l-tooltip>
             </l-marker>
           </l-map>
           <div v-else class="loading-map">Cargando mapa...</div>
        </div>

        <div class="selected-coords mb-3" v-if="searchParams.latitud">
           <span>📍 Coordenadas: <strong>{{ searchParams.latitud.toFixed(4) }}, {{ searchParams.longitud.toFixed(4) }}</strong></span>
        </div>

        <div class="form-actions-inline">
          <button @click="searchNearbySites" :disabled="nearbyLoading || !isFormValid" class="btn-search">
            <span v-if="!nearbyLoading">🔍 Buscar en este punto</span>
            <span v-else>⏳ Buscando...</span>
          </button>
          
          <button @click="useCurrentLocation" :disabled="nearbyLoading || gettingLocation" class="btn-location">
            <span v-if="!gettingLocation">🎯 Mi Ubicación actual</span>
            <span v-else>📡 Obteniendo y buscando...</span>
          </button>
        </div>

        <div v-if="nearbySites.length > 0" class="data-table mt-4">
          <table>
            <thead>
              <tr>
                <th>Nombre</th>
                <th>Descripción</th>
                <th>Coordenadas</th>
                <th>Distancia</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in nearbySites" :key="item.sitio.id">
                <td class="name-cell">{{ item.sitio.nombre }}</td>
                <td class="desc-cell" :title="item.sitio.descripcion">
                  {{ item.sitio.descripcion || 'Sin descripción' }}
                </td>
                <td class="coords-cell">
                  {{ item.sitio.latitud?.toFixed(4) }}, {{ item.sitio.longitud?.toFixed(4) }}
                </td>
                <td class="distance-cell">
                  {{ formatDistance(item.distanciaEnMetros) }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        
        <p v-else-if="searched && nearbySites.length === 0" class="no-data">
          No se encontraron sitios turísticos a 5km de este punto.
        </p>
      </div>

      <div class="stat-card full-width">
        <h2>📍 Consulta #2: Análisis de Proximidad</h2>
        <div v-if="proximityAnalysis.length > 0" class="data-table">
          <table>
            <thead>
              <tr>
                <th>Teatro</th>
                <th>Restaurante</th>
                <th>Distancia</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(item, index) in proximityAnalysis" :key="index">
                <td>{{ item.nombreTeatro }}</td>
                <td>{{ item.nombreRestaurante }}</td>
                <td class="distance-cell">{{ item.distanciaEnMetros?.toFixed(1) }}m</td>
              </tr>
            </tbody>
          </table>
        </div>
        <p v-else class="no-data">No hay restaurantes cerca de teatros</p>
      </div>

      <div class="stat-card">
        <h2>👑 Consulta #3: Top Reseñadores</h2>
        <div v-if="topReviewers.length > 0" class="leaderboard">
          <div v-for="(reviewer, index) in topReviewers" :key="index" class="leaderboard-item">
            <span class="rank">{{ index + 1 }}°</span>
            <span class="name">{{ reviewer.nombreUsuario }}</span>
            <span class="count">{{ reviewer.conteoreseñas }} reseñas</span>
          </div>
        </div>
        <p v-else class="no-data">No hay reseñadores activos</p>
      </div>

      <div class="stat-card">
        <h2>⚠️ Consulta: Valoraciones Inusuales</h2>
        <div v-if="unusualRatings.length > 0" class="site-list">
          <div v-for="site in (showAllUnusual ? unusualRatings : unusualRatings.slice(0, 5))" :key="site.nombre" class="site-item">
            <div class="site-name">{{ site.nombre }}</div>
            <div class="site-stats">
              <span class="rating">⭐ {{ site.calificacionPromedio?.toFixed(1) }}</span>
              <span class="count">{{ site.totalreseñas }} reseñas</span>
            </div>
          </div>
          <div v-if="unusualRatings.length > 5" class="toggle-container">
            <button @click="showAllUnusual = !showAllUnusual" class="btn-toggle">
              {{ showAllUnusual ? '▲ Ver menos' : '▼ Ver todos (' + unusualRatings.length + ')' }}
            </button>
          </div>
        </div>
        <p v-else class="no-data">No hay sitios con estas características</p>
      </div>

    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { statisticsService } from '@/services/statisticsService'
import Navbar from '@/components/layout/Navbar.vue'
import ErrorMessage from '@/components/common/ErrorMessage.vue'

// Importaciones de Leaflet
import { LMap, LTileLayer, LMarker, LTooltip } from '@vue-leaflet/vue-leaflet'
import 'leaflet/dist/leaflet.css'

// --- ESTADO GLOBAL ---
const topReviewers = ref([])
const proximityAnalysis = ref([])
const unusualRatings = ref([])
const showAllUnusual = ref(false)
const loading = ref(false)
const error = ref(null)

// --- ESTADO CONSULTA 1 (MAPA + BÚSQUEDA) ---
const searchParams = ref({
  latitud: null,
  longitud: null,
  radio: 5000 // Fijo 5km
})
const nearbySites = ref([])
const nearbyLoading = ref(false)
const searched = ref(false)
const gettingLocation = ref(false)

// Configuración del Mapa
const zoom = ref(12)
const center = ref([-33.4489, -70.6693]) // Santiago Centro por defecto
const mapReady = ref(false)

// Validación
const isFormValid = computed(() => {
  return searchParams.value.latitud !== null && searchParams.value.longitud !== null
})

// --- MÉTODOS CONSULTA 1 ---

const formatDistance = (metros) => {
  if (!metros && metros !== 0) return '0m'
  if (metros < 1000) {
    return `${Number(metros).toFixed(0)}m`
  }
  return `${(Number(metros) / 1000).toFixed(2)}km`
}

// 1. EVENTO CLICK EN MAPA 
const onMapClick = (e) => {
  searchParams.value.latitud = e.latlng.lat
  searchParams.value.longitud = e.latlng.lng
  
}

// 2. FUNCIÓN DE BÚSQUEDA 
const searchNearbySites = async () => {
  if (!isFormValid.value) return
  
  nearbyLoading.value = true
  searched.value = true
  
  try {
    const data = await statisticsService.getNearbySites(
      searchParams.value.longitud,
      searchParams.value.latitud,
      searchParams.value.radio
    )
    nearbySites.value = data
  } catch (err) {
    error.value = "Error al buscar sitios cercanos"
    console.error(err)
  } finally {
    nearbyLoading.value = false
  }
}

// 3. USAR MI UBICACIÓN 
const useCurrentLocation = () => {
  if (!navigator.geolocation) {
    error.value = 'Navegador no soporta geolocalización'
    return
  }
  
  gettingLocation.value = true
  
  navigator.geolocation.getCurrentPosition(
    async (pos) => {
      // A. Actualizamos coordenadas
      searchParams.value.latitud = pos.coords.latitude
      searchParams.value.longitud = pos.coords.longitude
      gettingLocation.value = false
      await searchNearbySites()
    },
    (err) => {
      console.error(err)
      error.value = "No se pudo obtener la ubicación GPS"
      gettingLocation.value = false
    }
  )
}


// --- CARGA GENERAL DE ESTADÍSTICAS ---
const loadAllStatistics = async () => {
  loading.value = true
  try {
    const results = await Promise.allSettled([
      statisticsService.getTopReviewers(),
      statisticsService.getProximityAnalysis(),
      statisticsService.getUnusualRatings()
    ])
    
    if (results[0].status === 'fulfilled') topReviewers.value = results[0].value
    if (results[1].status === 'fulfilled') proximityAnalysis.value = results[1].value
    if (results[2].status === 'fulfilled') unusualRatings.value = results[2].value

  } catch (err) {
    error.value = 'Error al cargar estadísticas generales'
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadAllStatistics()
  setTimeout(() => { mapReady.value = true }, 200)
})
</script>

<style scoped>
/* --- ESTILOS MAPA --- */
.map-wrapper {
  height: 400px;
  width: 100%;
  border: 1px solid #bdc3c7;
  border-radius: 8px;
  overflow: hidden;
  position: relative;
  z-index: 1;
}

.map-container {
  height: 100%;
  width: 100%;
}

.loading-map {
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #ecf0f1;
  color: #7f8c8d;
}

.selected-coords {
  background: #e8f6f3;
  color: #16a085;
  padding: 0.5rem 1rem;
  border-radius: 6px;
  border: 1px solid #a3e4d7;
  display: inline-block;
  font-size: 0.9rem;
}

.mb-3 { margin-bottom: 1rem; }

/* --- ESTILOS BOTONES --- */
.form-actions-inline {
  display: flex;
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.btn-search {
  background: #3498db;
  color: white;
  flex: 2;
  padding: 0.8rem;
  border: none;
  border-radius: 6px;
  font-weight: bold;
  cursor: pointer;
  transition: background 0.2s;
  font-size: 1rem;
}
.btn-search:hover:not(:disabled) { background: #2980b9; }

.btn-location {
  background: #f1c40f; 
  color: #2c3e50;
  flex: 1;
  padding: 0.8rem;
  border: none;
  border-radius: 6px;
  font-weight: bold;
  cursor: pointer;
}
.btn-location:hover:not(:disabled) { background: #d4ac0d; }

button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* --- LAYOUT GENERAL --- */
.statistics-view { min-height: 100vh; background-color: #f8f9fa; padding-bottom: 3rem; }
.header, .reload-section, .stats-grid { max-width: 1200px; margin: 0 auto; padding: 0 2rem; }
.header { text-align: center; margin-bottom: 2rem; padding-top: 2rem; }
.stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(500px, 1fr)); gap: 1.5rem; }
.stat-card { background: white; border-radius: 12px; padding: 1.5rem; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
.stat-card.full-width { grid-column: 1 / -1; }

/* Tablas */
table { width: 100%; border-collapse: collapse; }
th, td { padding: 0.75rem; border-bottom: 1px solid #ecf0f1; text-align: left; }
th { background: #ecf0f1; font-weight: 600; color: #2c3e50; }
.distance-cell { text-align: right; color: #27ae60; font-weight: 600; }
.no-data { text-align: center; color: #bdc3c7; padding: 2rem; font-style: italic; }

/* Leaderboard */
.leaderboard { display: flex; flex-direction: column; gap: 0.75rem; }
.leaderboard-item { display: flex; align-items: center; gap: 1rem; padding: 0.75rem; background: #ecf0f1; border-radius: 8px; }
.rank { font-size: 1.2rem; font-weight: 700; color: #3498db; }
.name { flex: 1; font-weight: 600; color: #2c3e50; }

/* Lista de sitios */
.site-list { display: flex; flex-direction: column; gap: 0.5rem; }
.site-item { padding: 0.75rem; border-left: 4px solid #e74c3c; background: #f8f9fa; border-radius: 4px; }
.site-name { font-weight: 600; color: #2c3e50; }
.site-stats { font-size: 0.9rem; color: #7f8c8d; }

.toggle-container { text-align: center; margin-top: 1rem; }
.btn-toggle { background: none; border: 1px solid #bdc3c7; padding: 0.3rem 1rem; border-radius: 20px; cursor: pointer; }

@media (max-width: 768px) {
  .stats-grid { grid-template-columns: 1fr; }
  .form-actions-inline { flex-direction: column; }
}
</style>