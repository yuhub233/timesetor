<template>
  <div class="login-page">
    <div class="login-card">
      <h1 class="login-title">TimeSetor</h1>
      <p class="login-subtitle">不常规时间管理系统</p>
      <form @submit.prevent="handleSubmit" class="login-form">
        <div class="form-group">
          <label class="label">用户名</label>
          <input v-model="username" type="text" class="input" placeholder="请输入用户名" required />
        </div>
        <div class="form-group">
          <label class="label">密码</label>
          <input v-model="password" type="password" class="input" placeholder="请输入密码" required />
        </div>
        <p v-if="error" class="error-message">{{ error }}</p>
        <div class="login-actions">
          <button type="submit" class="btn btn-primary" :disabled="loading">{{ isRegister ? '注册' : '登录' }}</button>
          <button type="button" class="btn btn-secondary" @click="isRegister = !isRegister">{{ isRegister ? '已有账号？登录' : '没有账号？注册' }}</button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const authStore = useAuthStore()
const username = ref('')
const password = ref('')
const isRegister = ref(false)
const loading = ref(false)
const error = ref('')

async function handleSubmit() {
  if (!username.value || !password.value) { error.value = '请填写用户名和密码'; return }
  loading.value = true
  error.value = ''
  try {
    let result = isRegister.value ? await authStore.register(username.value, password.value) : await authStore.login(username.value, password.value)
    if (result.success) { router.push('/') } else { error.value = result.error }
  } finally { loading.value = false }
}
</script>

<style scoped>
.login-page { min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 1rem; }
.login-card { background: #1a1a2e; border-radius: 24px; padding: 3rem; width: 100%; max-width: 400px; }
.login-title { font-size: 2.5rem; font-weight: 700; text-align: center; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; margin-bottom: 0.5rem; }
.login-subtitle { text-align: center; color: #a0a0a0; margin-bottom: 2rem; }
.login-form { display: flex; flex-direction: column; gap: 0.5rem; }
.login-actions { display: flex; flex-direction: column; gap: 0.75rem; margin-top: 1rem; }
.error-message { color: #f5576c; font-size: 0.875rem; text-align: center; }
</style>