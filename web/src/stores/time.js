import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '../utils/api'

export const useTimeStore = defineStore('time', () => {
  const virtualTime = ref('')
  const realTime = ref('')
  const currentSpeed = ref(1.0)
  const currentActivity = ref('rest')
  const status = ref('unknown')
  const isAwake = computed(() => status.value === 'awake')
  let updateInterval = null

  async function fetchCurrentTime() {
    try {
      const response = await api.get('/time/current')
      status.value = response.data.status
      virtualTime.value = response.data.virtual_time_display || ''
      realTime.value = response.data.real_time || ''
      currentSpeed.value = response.data.current_speed || 1.0
      currentActivity.value = response.data.current_activity || 'rest'
      return response.data
    } catch (error) { return null }
  }

  async function recordWake() {
    try {
      const response = await api.post('/time/wake')
      status.value = 'awake'
      startAutoUpdate()
      return { success: true, data: response.data }
    } catch (error) {
      return { success: false, error: error.response?.data?.error || '记录起床失败' }
    }
  }

  async function recordSleep() {
    try {
      await api.post('/time/sleep')
      status.value = 'sleep'
      stopAutoUpdate()
      return { success: true }
    } catch (error) {
      return { success: false, error: error.response?.data?.error || '记录睡觉失败' }
    }
  }

  async function updateActivity(activityType, appName = null) {
    try {
      const response = await api.post('/activity/update', { activity_type: activityType, app_name: appName })
      currentActivity.value = response.data.activity_type
      currentSpeed.value = response.data.speed
      return { success: true }
    } catch (error) { return { success: false } }
  }

  function startAutoUpdate() {
    if (updateInterval) return
    updateInterval = setInterval(fetchCurrentTime, 1000)
  }

  function stopAutoUpdate() {
    if (updateInterval) { clearInterval(updateInterval); updateInterval = null }
  }

  return { virtualTime, realTime, currentSpeed, currentActivity, status, isAwake, fetchCurrentTime, recordWake, recordSleep, updateActivity, startAutoUpdate, stopAutoUpdate }
})