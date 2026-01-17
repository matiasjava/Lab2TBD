<template>
  <div class="site-card" @click="goToSite">
    <div class="site-image">
      <div v-if="loading" class="loading-placeholder">
        <span class="spinner">↻</span>
      </div>

      <img 
        v-else-if="imagenUrl" 
        :src="imagenUrl" 
        :alt="site.nombre" 
        @error="handleImageError"
      />
      
      <div v-else class="no-image">
        <span>Sin imagen</span>
      </div>
      
      <span class="site-type">{{ site.tipo }}</span>
    </div>
    
    <div class="site-content">
      <h3 class="site-name">{{ site.nombre }}</h3>
      <p class="site-description">{{ truncateDescription(site.descripcion) }}</p>
      
      <div class="site-footer">
        <RatingStars :rating="site.calificacionPromedio || 0" />
        <span class="reviews-count">
          {{ site.totalreseñas || 0 }} reseñas
        </span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useRouter } from 'vue-router'
import { ref, onMounted } from 'vue'
// IMPORTANTE: Ajusta la ruta según dónde guardaste el archivo que me mostraste
import { photosService } from '@/services/photosService' 
import RatingStars from './RatingStars.vue'

const props = defineProps({
  site: {
    type: Object,
    required: true
  }
})

const router = useRouter()
const imagenUrl = ref(null)
const loading = ref(true)

// === Lógica de carga de imagen usando tu servicio ===
const loadSiteImage = async () => {
  try {
    loading.value = true
    
    // Usamos tu servicio. Como devuelve response.data, recibimos el array directo.
    const fotos = await photosService.getBySiteId(props.site.id)
    
    // Verificamos si llegó algo y tomamos la primera
    if (fotos && Array.isArray(fotos) && fotos.length > 0) {
      imagenUrl.value = fotos[0].url
    }
  } catch (error) {
    console.error(`Error cargando foto para sitio ${props.site.id}:`, error)
  } finally {
    loading.value = false
  }
}

// Ejecutamos la carga apenas aparece la tarjeta
onMounted(() => {
  loadSiteImage()
})

const handleImageError = () => {
  // Si la URL falla (ej. 404), borramos la variable para que salga el placeholder
  imagenUrl.value = null
}

// === Funciones auxiliares ===
const truncateDescription = (text) => {
  if (!text) return ''
  return text.length > 100 ? text.substring(0, 100) + '...' : text
}

const goToSite = () => {
  router.push(`/sitios/${props.site.id}`)
}
</script>

<style scoped>
/* Estilos Base */
.site-card {
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  overflow: hidden;
  cursor: pointer;
  transition: transform 0.3s, box-shadow 0.3s;
  background-color: white;
  display: flex;
  flex-direction: column;
}

.site-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.site-image {
  position: relative;
  width: 100%;
  height: 200px;
  background-color: #f8f9fa;
}

.site-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

/* Estilos para los estados "Sin Imagen" y "Cargando" */
.no-image, .loading-placeholder {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #7f8c8d;
  font-weight: 500;
  background-color: #ecf0f1;
}

.spinner {
  animation: spin 1s linear infinite;
  font-size: 1.5rem;
  display: block;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.site-type {
  position: absolute;
  top: 10px;
  right: 10px;
  background-color: rgba(52, 152, 219, 0.9);
  color: white;
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  font-size: 0.85rem;
  font-weight: 600;
}

.site-content {
  padding: 1rem;
  flex-grow: 1;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.site-name {
  margin: 0 0 0.5rem 0;
  font-size: 1.25rem;
  color: #2c3e50;
}

.site-description {
  color: #7f8c8d;
  margin: 0 0 1rem 0;
  font-size: 0.9rem;
  line-height: 1.4;
}

.site-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: auto;
}

.reviews-count {
  color: #95a5a6;
  font-size: 0.9rem;
}
</style>