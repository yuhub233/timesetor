<template>
  <div class="settings-page">
    <div class="card">
      <h2 class="card-title">时间设置</h2>
      <div class="form-group"><label class="label">目标起床时间</label><input v-model="settings.target_wake_time" type="time" class="input" /></div>
      <div class="form-group"><label class="label">目标睡觉时间</label><input v-model="settings.target_sleep_time" type="time" class="input" /></div>
      <div class="form-group"><label class="label">目标娱乐时长（小时）</label><input v-model.number="settings.target_entertainment_hours" type="number" step="0.5" min="0" max="12" class="input" /></div>
      <div class="form-group"><label class="label">目标学习时长（小时）</label><input v-model.number="settings.target_study_hours" type="number" step="0.5" min="0" max="12" class="input" /></div>
      <div class="form-group"><label class="label">时间靠拢速率 (0.05 - 0.5)</label><input v-model.number="settings.time_approach_rate" type="number" step="0.05" min="0.05" max="0.5" class="input" /></div>
      <button @click="saveSettings" class="btn btn-primary" :disabled="saving">{{ saving ? '保存中...' : '保存设置' }}</button>
      <p v-if="message" class="mt-2" :class="messageType">{{ message }}</p>
    </div>
    <div class="card">
      <h2 class="card-title">账户</h2>
      <p class="text-muted mb-2">用户ID: {{ authStore.userId }}</p>
      <button @click="logout" class="btn btn-danger">退出登录</button>
    </div>
    <div class="card">
      <h2 class="card-title">关于</h2>
      <p class="text-muted">TimeSetor v1.0.0<br>不常规时间管理系统</p>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const authStore = useAuthStore()
const settings = reactive({ target_wake_time: '08:00', target_sleep_time: '23:00', target_entertainment_hours: 2, target_study_hours: 4, time_approach_rate: 0.1 })
const saving = ref(false)
const message = ref('')
const messageType = ref('')

onMounted(() => { if (authStore.settings) Object.assign(settings, authStore.settings) })

async function saveSettings() {
  saving.value = true; message.value = ''
  const result = await authStore.updateSettings(settings)
  saving.value = false
  if (result.success) { message.value = '设置已保存'; messageType.value = 'text-success' } else { message.value = result.error; messageType.value = 'text-error' }
  setTimeout(() => { message.value = '' }, 3000)
}

function logout() { if (confirm('确定要退出登录吗？')) { authStore.logout(); router.push('/login') } }
</script>

<style scoped>
.settings-page { max-width: 500px; margin: 0 auto; }
.text-success { color: #4ade80; }
.text-error { color: #f5576c; }
input[type="time"] { color-scheme: dark; }
</style>