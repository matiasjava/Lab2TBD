<template>
  <div class="site-form-view">
    <div class="container">
      <div class="form-header">
        <h1>Nueva Ruta Turística</h1>
        <p class="subtitle">Define una ruta conectando múltiples coordenadas</p>
      </div>

      <ErrorMessage v-if="error" :message="error" @close="error = null" />

      <form @submit.prevent="handleSubmit" class="site-form">
        <div class="form-row">
          <div class="form-group full-width">
            <label for="nombre">Nombre de la Ruta *</label>
            <input
              id="nombre"
              v-model="formData.nombre"
              type="text"
              placeholder="Ej: Ruta Patrimonial Santiago"
              required
            />
          </div>
        </div>

        <div class="form-group">
          <label for="descripcion">Descripción *</label>
          <textarea
            id="descripcion"
            v-model="formData.descripcion"
            placeholder="Describe qué lugares recorre esta ruta..."
            rows="3"
            required
          ></textarea>
        </div>

        <hr class="separator" />

        <div class="coordinates-section">
          <h3>📍 Puntos de la Ruta (Coordenadas)</h3>
          <p class="help-text">Agrega los puntos en orden secuencial para formar el camino.</p>

          <div v-for="(punto, index) in puntos" :key="index" class="coordinate-row">
            <div class="point-index">#{{ index + 1 }}</div>
            
            <div class="form-group">
              <label>Latitud</label>
              <input
                v-model.number="punto.lat"
                type="number"
                step="any"
                placeholder="-33.xxx"
                required
              />
            </div>

            <div class="form-group">
              <label>Longitud</label>
              <input
                v-model.number="punto.lon"
                type="number"
                step="any"
                placeholder="-70.xxx"
                required
              />
            </div>

            <button 
              type="button" 
              class="btn-remove" 
              @click="removePoint(index)"
              v-if="puntos.length > 1"
              title="Eliminar punto"
            >
              🗑️
            </button>
          </div>

          <button type="button" @click="addPoint" class="btn-add-point">
            + Agregar otro punto
          </button>
        </div>

        <div class="form-actions">
          <button type="button" @click="handleCancel" class="btn-cancel">
            Cancelar
          </button>
          <button type="submit" class="btn-submit" :disabled="loading">
            {{ loading ? 'Guardando...' : 'Crear Ruta' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { rutasService } from '@/services/routesService'
import { authService } from '@/services/authService'
import ErrorMessage from '@/components/common/ErrorMessage.vue'

const router = useRouter()

const formData = reactive({
  nombre: '',
  descripcion: ''
})

const puntos = ref([
  { lat: null, lon: null },
  { lat: null, lon: null }
])

const loading = ref(false)
const error = ref(null)

const addPoint = () => {
  puntos.value.push({ lat: null, lon: null })
}

const removePoint = (index) => {
  if (puntos.value.length > 1) {
    puntos.value.splice(index, 1)
  }
}

const handleSubmit = async () => {
  error.value = null
  loading.value = true

  try {
    const user = authService.getCurrentUser()
    
    if (!user || !user.id) {
      authService.logout()
      router.push('/login')
      throw new Error("Tu sesión ha expirado. Por favor ingresa nuevamente.")
    }

    const validCoords = puntos.value.every(p => p.lat !== null && p.lon !== null)
    if (!validCoords) {
      throw new Error("Por favor completa todas las coordenadas.")
    }

    const coordenadasList = puntos.value.map(p => [p.lat, p.lon])

    const payload = {
      nombre: formData.nombre,
      descripcion: formData.descripcion,
      idUsuario: user.id,
      coordenadas: coordenadasList
    }

    await rutasService.create(payload)

    router.push('/rutas')

  } catch (err) {
    console.error(err)
    if (err.response?.status === 401) {
        error.value = "No autorizado. Inicia sesión nuevamente."
    } else {
        error.value = err.response?.data || err.message || 'Error al crear la ruta'
    }
  } finally {
    loading.value = false
  }
}

const handleCancel = () => {
  router.back()
}

onMounted(() => {
    if (!authService.isAuthenticated()) {
        router.push('/login')
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
.subtitle { color: #7f8c8d; font-size: 0.9rem; margin-top: 0.5rem; }

.site-form {
  background-color: white;
  padding: 2rem;
  border-radius: 8px;
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  box-shadow: 0 2px 10px rgba(0,0,0,0.05);
}

.form-row {
  display: flex;
  gap: 1.5rem;
}
.full-width { width: 100%; }

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  flex: 1;
}

.form-group label {
  color: #2c3e50;
  font-weight: 500;
}

.form-group input,
.form-group textarea {
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 1rem;
  font-family: inherit;
}

.form-group input:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #3498db;
}

.separator {
  border: 0;
  border-top: 1px solid #eee;
  margin: 1rem 0;
}

.coordinates-section h3 {
  font-size: 1.1rem;
  color: #2c3e50;
  margin-bottom: 0.5rem;
}

.help-text {
  font-size: 0.85rem;
  color: #7f8c8d;
  margin-bottom: 1.5rem;
}

.coordinate-row {
  display: flex;
  align-items: flex-end;
  gap: 1rem;
  margin-bottom: 1rem;
  background: #f8f9fa;
  padding: 1rem;
  border-radius: 6px;
  border: 1px solid #eee;
}

.point-index {
  font-weight: bold;
  color: #bdc3c7;
  padding-bottom: 12px;
  font-size: 1.2rem;
}

.btn-remove {
  background: #e74c3c;
  color: white;
  border: none;
  padding: 0.75rem;
  border-radius: 6px;
  cursor: pointer;
  height: 42px;
  transition: background 0.2s;
}
.btn-remove:hover { background: #c0392b; }

.btn-add-point {
  background: none;
  border: 2px dashed #3498db;
  color: #3498db;
  width: 100%;
  padding: 0.8rem;
  border-radius: 6px;
  font-weight: 600;
  cursor: pointer;
  margin-top: 0.5rem;
  transition: all 0.2s;
}
.btn-add-point:hover {
  background: #eaf6fd;
}

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
  .coordinate-row {
    flex-direction: column;
    align-items: stretch;
  }
  .btn-remove { width: 100%; }
}
</style>