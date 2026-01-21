import api from './api'

export const rutasService = {
  async getAll() {
    const response = await api.get('/rutas')
    return response.data
  },

  async create(rutaData) {
    const response = await api.post('/rutas', rutaData)
    return response.data 
  }
}