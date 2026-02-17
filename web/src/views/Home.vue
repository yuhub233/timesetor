<template>
  <div class="home-page">
    <div v-if="!timeStore.isAwake" class="wake-prompt card text-center">
      <h2 class="mb-2">早安！</h2>
      <p class="text-muted mb-3">点击下方按钮记录起床时间</p>
      <button @click="handleWake" class="btn btn-primary btn-lg">起床</button>
    </div>
    <template v-else>
      <div class="time-card card text-center">
        <div class="time-display">{{ timeStore.virtualTime || '--:--' }}</div>
        <p class="text-muted mt-2">真实时间: {{ formatRealTime(timeStore.realTime) }}</p>
      </div>
      <div class="activity-card card">
        <h3 class="card-title">当前活动</h3>
        <div class="activity-buttons">
          <button v-for="activity in activities" :key="activity.value" @click="setActivity(activity.value)" class="btn" :class="timeStore.currentActivity === activity.value ? 'btn-primary' : 'btn-secondary'">{{ activity.label }}</button>
        </div>
      </div>
      <div class="sleep-card card text-center">
        <button @click="handleSleep" class="btn btn-danger">睡觉</button>
      </div>
    </template>
  </div>
</template>

<script setup>
import { computed, onMounted, onUnmounted } from 'vue'
import { useTimeStore } from '../stores/time'

const timeStore = useTimeStore()
const activities = [{ value: 'rest', label: '休息' }, { value: 'entertainment', label: '娱乐' }, { value: 'study', label: '学习' }]

function formatRealTime(isoString) {
  if (!isoString) return '--:--'
  const date = new Date(isoString)
  return date.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })
}

async function handleWake() {
  const result = await timeStore.recordWake()
  if (!result.success) alert(result.error)
}

async function handleSleep() {
  if (confirm('确定要记录睡觉时间吗？')) {
    const result = await timeStore.recordSleep()
    if (!result.success) alert(result.error)
  }
}

async function setActivity(activity) { await timeStore.updateActivity(activity) }

onMounted(async () => { await timeStore.fetchCurrentTime(); if (timeStore.isAwake) timeStore.startAutoUpdate() })
onUnmounted(() => timeStore.stopAutoUpdate())
</script>

<style scoped>
.home-page { max-width: 600px; margin: 0 auto; }
.time-card { padding: 3rem 2rem; }
.btn-lg { padding: 1rem 3rem; font-size: 1.25rem; }
.activity-buttons { display: flex; gap: 1rem; flex-wrap: wrap; }
.activity-buttons .btn { flex: 1; min-width: 100px; }
.wake-prompt { padding: 4rem 2rem; }
</style>