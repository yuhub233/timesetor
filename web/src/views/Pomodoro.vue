<template>
  <div class="pomodoro-page">
    <div class="pomodoro-timer card text-center">
      <h2 class="card-title">番茄钟</h2>
      <div class="timer-display">{{ formatTime(remainingSeconds) }}</div>
      <div class="timer-progress"><div class="progress-bar" :style="{ width: progressPercent + '%' }"></div></div>
      <div class="timer-controls mt-3">
        <button v-if="!isRunning" @click="startTimer" class="btn btn-primary">开始</button>
        <button v-else @click="pauseTimer" class="btn btn-secondary">暂停</button>
        <button @click="resetTimer" class="btn btn-secondary">重置</button>
      </div>
      <div class="duration-selector mt-3">
        <label class="label">时长（分钟）</label>
        <div class="duration-options">
          <button v-for="duration in durations" :key="duration" @click="selectDuration(duration)" class="btn" :class="selectedDuration === duration ? 'btn-primary' : 'btn-secondary'">{{ duration }}</button>
        </div>
      </div>
    </div>
    <div class="pomodoro-stats card">
      <h3 class="card-title">今日统计</h3>
      <div class="stats-grid">
        <div class="stat-item"><span class="stat-value">{{ completedCount }}</span><span class="stat-label">完成番茄</span></div>
        <div class="stat-item"><span class="stat-value">{{ totalMinutes }}</span><span class="stat-label">总分钟数</span></div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import api from '../utils/api'

const durations = [15, 25, 30, 45, 60]
const selectedDuration = ref(25)
const remainingSeconds = ref(25 * 60)
const isRunning = ref(false)
const sessionId = ref(null)
const completedCount = ref(0)
const totalMinutes = ref(0)
let timerInterval = null

const progressPercent = computed(() => ((selectedDuration.value * 60 - remainingSeconds.value) / (selectedDuration.value * 60)) * 100)

function formatTime(seconds) {
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60
  return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
}

async function startTimer() {
  if (!sessionId.value) {
    try { const response = await api.post('/pomodoro/start', { duration_minutes: selectedDuration.value, session_type: 'work' }); sessionId.value = response.data.session_id } catch { return }
  }
  isRunning.value = true
  timerInterval = setInterval(() => { if (remainingSeconds.value > 0) remainingSeconds.value--; else completeTimer() }, 1000)
}

function pauseTimer() { isRunning.value = false; if (timerInterval) { clearInterval(timerInterval); timerInterval = null } }

async function resetTimer() { pauseTimer(); remainingSeconds.value = selectedDuration.value * 60; sessionId.value = null }

async function completeTimer() {
  pauseTimer()
  if (sessionId.value) { try { await api.post('/pomodoro/end', { session_id: sessionId.value, actual_duration_minutes: selectedDuration.value, status: 'completed' }); completedCount.value++; totalMinutes.value += selectedDuration.value } catch {} }
  alert('番茄钟完成！'); resetTimer()
}

function selectDuration(duration) { if (!isRunning.value) { selectedDuration.value = duration; remainingSeconds.value = duration * 60 } }

async function fetchStats() { try { const response = await api.get('/data/daily'); const sessions = response.data.pomodoro_sessions || []; completedCount.value = sessions.filter(s => s.status === 'completed').length; totalMinutes.value = sessions.reduce((sum, s) => sum + (s.actual_duration_minutes || 0), 0) } catch {} }

onMounted(() => fetchStats())
onUnmounted(() => pauseTimer())
</script>

<style scoped>
.pomodoro-page { max-width: 500px; margin: 0 auto; }
.timer-display { font-size: 5rem; font-weight: 700; font-variant-numeric: tabular-nums; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; margin: 1rem 0; }
.timer-progress { height: 8px; background: rgba(255, 255, 255, 0.1); border-radius: 4px; overflow: hidden; }
.progress-bar { height: 100%; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); transition: width 1s linear; }
.timer-controls { display: flex; gap: 1rem; justify-content: center; }
.duration-options { display: flex; gap: 0.5rem; flex-wrap: wrap; justify-content: center; }
.duration-options .btn { min-width: 50px; padding: 0.5rem 1rem; }
.stats-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 1rem; }
.stat-item { text-align: center; padding: 1rem; background: rgba(255, 255, 255, 0.05); border-radius: 8px; }
.stat-value { display: block; font-size: 2rem; font-weight: 700; color: #667eea; }
.stat-label { display: block; font-size: 0.875rem; color: #a0a0a0; margin-top: 0.25rem; }
</style>