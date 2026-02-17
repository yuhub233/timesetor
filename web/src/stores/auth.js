import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '../utils/api'

export const useAuthStore = defineStore('auth', () => {
  const token = ref(localStorage.getItem('token') || '')
  const userId = ref(localStorage.getItem('userId') || '')
  const settings = ref(JSON.parse(localStorage.getItem('settings') || '{}'))
  const isLoggedIn = computed(() => !!token.value)

  async function login(username, password) {
    try {
      const response = await api.post('/auth/login', { username, password })
      token.value = response.data.token
      userId.value = response.data.user_id
      settings.value = response.data.settings || {}
      localStorage.setItem('token', token.value)
      localStorage.setItem('userId', userId.value)
      localStorage.setItem('settings', JSON.stringify(settings.value))
      return { success: true }
    } catch (error) {
      return { success: false, error: error.response?.data?.error || '登录失败' }
    }
  }

  async function register(username, password) {
    try {
      const response = await api.post('/auth/register', { username, password })
      token.value = response.data.token
      userId.value = response.data.user_id
      localStorage.setItem('token', token.value)
      localStorage.setItem('userId', userId.value)
      return { success: true }
    } catch (error) {
      return { success: false, error: error.response?.data?.error || '注册失败' }
    }
  }

  function logout() {
    token.value = ''
    userId.value = ''
    settings.value = {}
    localStorage.removeItem('token')
    localStorage.removeItem('userId')
    localStorage.removeItem('settings')
  }

  function checkAuth() { return !!token.value }

  async function updateSettings(newSettings) {
    try {
      await api.put('/user/settings', { settings: newSettings })
      settings.value = { ...settings.value, ...newSettings }
      localStorage.setItem('settings', JSON.stringify(settings.value))
      return { success: true }
    } catch (error) {
      return { success: false, error: error.response?.data?.error || '保存失败' }
    }
  }

  return { token, userId, settings, isLoggedIn, login, register, logout, checkAuth, updateSettings }
})