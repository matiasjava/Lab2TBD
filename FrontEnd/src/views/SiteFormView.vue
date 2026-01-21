<template>
  <div class="site-form-view">
    <div class="container">
      <div class="form-header">
        <h1>{{ isEdit ? 'Editar Sitio' : 'Agregar Nuevo Sitio' }}</h1>
      </div>

      <ErrorMessage v-if="error" :message="error" @close="error = ''" />

      <form @submit.prevent="handleSubmit" class="site-form">
        <div class="form-row">
          <div class="form-group">
            <label for="nombre">Nombre del sitio *</label>
            <input
              id="nombre"
              v-model="formData.nombre"
              type="text"
              placeholder="Ej: Museo Nacional"
              required
            />
          </div>

          <div class="form-group">
            <label for="tipo">Tipo *</label>
            <select id="tipo" v-model="formData.tipo" required>
              <option value="">Selecciona un tipo</option>
              <option value="Parque">Parque</option>
              <option value="Museo">Museo</option>
              <option value="Restaurante">Restaurante</option>
              <option value="Playa">Playa</option>
              <option value="Monumento">Monumento</option>
              <option value="Teatro">Teatro</option>
              <option value="Otro">Otro</option>
            </select>
          </div>
        </div>

        <div class="form-group">
          <label for="descripcion">Descripción *</label>
          <textarea
            id="descripcion"
            v-model="formData.descripcion"
            placeholder="Describe el sitio turístico..."
            rows="5"
            required
          ></textarea>
        </div>

        <hr class="separator">

        <div class="location-section">
          <h3>📍 Ubicación</h3>
          <p class="help-text">Haz clic en el mapa para obtener las coordenadas automáticamente.</p>
          
          <div class="map-wrapper">
             <l-map 
               ref="map"
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
                 v-if="formData.latitud && formData.longitud"
                 :lat-lng="[formData.latitud, formData.longitud]"
               >
                 <l-tooltip>Ubicación seleccionada</l-tooltip>
               </l-marker>
             </l-map>
          </div>

          <div class="form-row mt-3">
            <div class="form-group">
              <label for="latitud">Latitud *</label>
              <input
                id="latitud"
                v-model.number="formData.latitud"
                type="number"
                step="any"
                placeholder="-33.4489"
                required
              />
            </div>

            <div class="form-group">
              <label for="longitud">Longitud *</label>
              <input
                id="longitud"
                v-model.number="formData.longitud"
                type="number"
                step="any"
                placeholder="-70.6693"
                required
              />
            </div>
          </div>
        </div>

        <div class="form-actions">
          <button type="button" @click="handleCancel" class="btn-cancel">
            Cancelar
          </button>
          <button type="submit" class="btn-submit" :disabled="loading">
            {{ loading ? 'Guardando...' : (isEdit ? 'Actualizar' : 'Crear Sitio') }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useSitesStore } from '@/stores/sites'
import ErrorMessage from '@/components/common/ErrorMessage.vue'
import { LMap, LTileLayer, LMarker, LTooltip } from '@vue-leaflet/vue-leaflet'
import 'leaflet/dist/leaflet.css'

const router = useRouter()
const route = useRoute()
const sitesStore = useSitesStore()

const siteId = computed(() => route.params.id)
const isEdit = computed(() => !!siteId.value)

const zoom = ref(13)
const center = ref([-33.4489, -70.6693])

const formData = reactive({
  nombre: '',
  tipo: '',
  descripcion: '',
  latitud: null,
  longitud: null
})

const loading = ref(false)
const error = ref('')

const onMapClick = (e) => {
  formData.latitud = parseFloat(e.latlng.lat.toFixed(6))
  formData.longitud = parseFloat(e.latlng.lng.toFixed(6))
}

const handleSubmit = async () => {
  error.value = ''
  loading.value = true

  try {
    const data = {
      nombre: formData.nombre,
      tipo: formData.tipo,
      descripcion: formData.descripcion,
      latitud: formData.latitud,
      longitud: formData.longitud
    }

    if (isEdit.value) {
      await sitesStore.updateSite(siteId.value, data)
    } else {
      await sitesStore.createSite(data)
    }

    router.push('/sitios')
  } catch (err) {
    error.value = sitesStore.error || 'Error al guardar el sitio'
  } finally {
    loading.value = false
  }
}

const handleCancel = () => {
  router.back()
}

onMounted(async () => {
  if (isEdit.value) {
    try {
      const site = await sitesStore.fetchById(siteId.value)
      formData.nombre = site.nombre
      formData.tipo = site.tipo
      formData.descripcion = site.descripcion
      formData.latitud = site.latitud
      formData.longitud = site.longitud

      if (site.latitud && site.longitud) {
        center.value = [site.latitud, site.longitud]
        zoom.value = 15
      }
    } catch (err) {
      error.value = 'Error al cargar el sitio'
    }
  } else {
    if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(pos => {
            center.value = [pos.coords.latitude, pos.coords.longitude]
        })
    }
  }
})
</script>

<style scoped>
.site-form-view {
  min-height: 100vh;
  background-color: #f8f9fa;
  padding-bottom: 3rem;
}

.container {
  max-width: 800px;
  margin: 0 auto;
  padding: 2rem;
}

.form-header { margin-bottom: 2rem; }
.form-header h1 { color: #2c3e50; margin: 0; }

.site-form {
  background-color: white;
  padding: 2rem;
  border-radius: 8px;
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.5rem;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.form-group label { color: #2c3e50; font-weight: 500; }

.form-group input,
.form-group select,
.form-group textarea {
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 1rem;
  font-family: inherit;
}

.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #3498db;
}

.form-group textarea { resize: vertical; }

.separator { border: 0; border-top: 1px solid #eee; margin: 1rem 0; }
.help-text { color: #7f8c8d; font-size: 0.9rem; margin-bottom: 0.5rem; }
.mt-3 { margin-top: 1rem; }

.map-wrapper {
  height: 350px;
  width: 100%;
  border-radius: 8px;
  overflow: hidden;
  border: 1px solid #ddd;
}
.map-container { height: 100%; width: 100%; }

.form-actions {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
  margin-top: 1rem;
}

.btn-cancel, .btn-submit {
  padding: 0.75rem 2rem;
  border: none;
  border-radius: 6px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.3s;
}

.btn-cancel { background-color: #ecf0f1; color: #2c3e50; }
.btn-cancel:hover { background-color: #dfe4e6; }
.btn-submit { background-color: #27ae60; color: white; }
.btn-submit:hover:not(:disabled) { background-color: #229954; }
.btn-submit:disabled { opacity: 0.6; cursor: not-allowed; }

@media (max-width: 768px) {
  .form-row { grid-template-columns: 1fr; }
}
</style>