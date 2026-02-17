<template>
  <div class="app">
    <nav v-if="authStore.isLoggedIn" class="nav">
      <router-link to="/" class="nav-link">时间</router-link>
      <router-link to="/pomodoro" class="nav-link">番茄钟</router-link>
      <router-link to="/data" class="nav-link">数据</router-link>
      <router-link to="/settings" class="nav-link">设置</router-link>
    </nav>
    <main class="main">
      <router-view />
    </main>
  </div>
</template>

<script setup>
import { useAuthStore } from './stores/auth'
import { onMounted } from 'vue'

const authStore = useAuthStore()

onMounted(() => {
  authStore.checkAuth()
})
</script>

<style scoped>
.app {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}
.nav {
  background: #1a1a2e;
  padding: 1rem;
  display: flex;
  justify-content: center;
  gap: 2rem;
}
.nav-link {
  color: #a0a0a0;
  text-decoration: none;
  padding: 0.5rem 1rem;
  border-radius: 8px;
  transition: all 0.3s;
}
.nav-link:hover,
.nav-link.router-link-active {
  color: #fff;
  background: rgba(255, 255, 255, 0.1);
}
.main {
  flex: 1;
  padding: 2rem;
}
</style>