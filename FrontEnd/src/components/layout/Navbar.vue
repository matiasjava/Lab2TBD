<template>
  <nav class="navbar">
    <div class="navbar-container">
      <div class="navbar-brand">
        <router-link to="/" class="brand-link">
          <h1>TurismoMap</h1>
        </router-link>
      </div>

      <div class="navbar-menu" :class="{ 'is-active': isMenuOpen }">
        <div class="navbar-start">
          <router-link v-if="isAuthenticated" to="/sitios" class="navbar-item">
            Explorar Sitios
          </router-link>
          <router-link v-if="isAuthenticated" to="/sitios/cercanos" class="navbar-item">
            Buscar Cercanos
          </router-link>
          <router-link v-if="isAuthenticated" to="/mis-listas" class="navbar-item">
            Mis Listas
          </router-link>
          <router-link v-if="isAuthenticated" to="/estadisticas" class="navbar-item">
            Estadísticas
          </router-link>
          <router-link v-if="isAuthenticated" to="/rutas" class="navbar-item">
            Rutas Turísticas
          </router-link>
        </div>

        <div class="navbar-end">
          <template v-if="isAuthenticated">
            <router-link to="/perfil" class="navbar-item">
              {{ user?.nombre || 'Mi Perfil' }}
            </router-link>
            <button @click="handleLogout" class="navbar-item btn-logout">
              Cerrar Sesión
            </button>
          </template>
          <template v-else>
            <router-link to="/login" class="navbar-item">Iniciar Sesión</router-link>
            <router-link to="/registro" class="navbar-item btn-primary">Registrarse</router-link>
          </template>
        </div>
      </div>
    </div>
  </nav>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth' 

const router = useRouter()
const authStore = useAuthStore()
const isMenuOpen = ref(false)

const isAuthenticated = computed(() => authStore.isAuthenticated)
const user = computed(() => authStore.user)

const handleLogout = () => {
  authStore.logout()
  router.push('/login')
}
</script>

<style scoped>
.navbar {
  background-color: #2c3e50; 
  padding: 0.8rem 0;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.navbar-container {
  max-width: 1200px;
  margin: 0 auto;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 1rem;
}

.navbar-brand h1 {
  margin: 0;
  font-size: 1.5rem;
  color: white;
}

.brand-link { text-decoration: none; }

.navbar-menu {
  display: flex;
  flex: 1;
  justify-content: space-between;
  margin-left: 2rem;
  align-items: center;
}

.navbar-start, .navbar-end {
  display: flex;
  align-items: center;
  gap: 1rem;
}


.navbar-item {
  color: #ecf0f1; 
  text-decoration: none;
  padding: 0.5rem 0.8rem;
  border-radius: 4px;
  transition: background-color 0.3s;
  background: transparent;
  border: none;
  cursor: pointer;
  font-size: 0.95rem;
  font-family: inherit;
}


.navbar-item:hover, .router-link-active {
  background-color: rgba(255, 255, 255, 0.15);
  color: white;
}

.btn-primary {
  background-color: #3498db;
  padding: 0.5rem 1.2rem;
}

.btn-logout {
  background-color: #e74c3c;
  padding: 0.4rem 1rem;
}
</style>