<template>
  <div class="routes-container">
    <h2 class="title">Rutas Turísticas</h2>
    
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
      <p class="empty-hint"></p>
      <button @click="fetchRutas" class="retry-btn">Actualizar</button>
    </div>

    <div v-else class="routes-grid">
      <div v-for="ruta in rutas" :key="ruta.id" class="route-card">
        <div class="card-header">
          <h3>{{ ruta.nombre }}</h3>
          <span class="route-id">#{{ ruta.id }}</span>
        </div>
        
        <p class="description">{{ ruta.descripcion }}</p>
        
        <div class="distance-section">
          <div class="distance-badge">
            📏 {{ formatDistance(ruta.longitudKm) }}
          </div>
          <div class="distance-detail">
            Calculado con ST_Length de PostGIS
          </div>
        </div>
        
        <div class="card-footer">
          <span class="author">👤 {{ ruta.nombreUsuario || 'Usuario' }}</span>
          <span class="date">{{ formatDate(ruta.fechaCreacion) }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'

const rutas = ref([])
const loading = ref(true)
const error = ref(null)
const API_URL = 'http://localhost:8090/api/rutas'

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
  max-width: 1200px; 
  margin: 0 auto; 
}

.title { 
  text-align: center; 
  margin-bottom: 30px; 
  color: #2c3e50;
  font-size: 2rem;
  font-weight: 600;
}

.routes-grid { 
  display: grid; 
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr)); 
  gap: 24px; 
}

.route-card {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  border-left: 4px solid #3498db;
  transition: transform 0.2s, box-shadow 0.2s;
}

.route-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 4px 16px rgba(0,0,0,0.15);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 12px;
}

.card-header h3 {
  margin: 0;
  color: #2c3e50;
  font-size: 1.3rem;
  flex: 1;
}

.route-id {
  background: #ecf0f1;
  padding: 4px 10px;
  border-radius: 12px;
  font-size: 0.85rem;
  color: #7f8c8d;
  font-weight: 600;
}

.description {
  color: #555;
  line-height: 1.6;
  margin: 12px 0;
}

.distance-section {
  margin: 16px 0;
  padding: 12px;
  background: #f8f9fa;
  border-radius: 8px;
}

.distance-badge {
  font-weight: bold;
  font-size: 1.2rem;
  color: #27ae60;
  margin-bottom: 4px;
}

.distance-detail {
  font-size: 0.75rem;
  color: #7f8c8d;
  font-style: italic;
}

.card-footer { 
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 16px; 
  padding-top: 16px; 
  border-top: 1px solid #ecf0f1; 
}

.author {
  color: #34495e;
  font-weight: 500;
}

.date {
  color: #95a5a6;
  font-size: 0.9rem;
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
  margin-top: 10px;
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

.empty-hint {
  font-size: 0.95rem;
  color: #95a5a6;
  font-style: italic;
  margin-top: 16px;
  margin-bottom: 20px;
}
</style>