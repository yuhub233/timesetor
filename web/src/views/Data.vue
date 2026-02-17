<template>
  <div class="data-page">
    <div class="data-tabs card">
      <button v-for="tab in tabs" :key="tab.value" @click="activeTab = tab.value" class="btn" :class="activeTab === tab.value ? 'btn-primary' : 'btn-secondary'">{{ tab.label }}</button>
    </div>
    <div v-if="activeTab === 'daily'" class="daily-data">
      <div class="card">
        <h3 class="card-title">今日数据</h3>
        <div v-if="dailyRecord" class="data-grid">
          <div class="data-item"><span class="data-label">起床时间</span><span class="data-value">{{ formatTime(dailyRecord.real_wake_time) }}</span></div>
          <div class="data-item"><span class="data-label">不常规起床</span><span class="data-value">{{ dailyRecord.real_wake_time_display || '--:--' }}</span></div>
          <div class="data-item"><span class="data-label">娱乐时长</span><span class="data-value">{{ dailyRecord.actual_entertainment_minutes || 0 }} 分钟</span></div>
          <div class="data-item"><span class="data-label">学习时长</span><span class="data-value">{{ dailyRecord.actual_study_minutes || 0 }} 分钟</span></div>
        </div>
        <p v-else class="text-muted">暂无今日数据</p>
      </div>
    </div>
    <div v-if="activeTab === 'weekly'" class="weekly-data">
      <div class="card">
        <h3 class="card-title">本周数据</h3>
        <p v-if="!weeklyRecords.length" class="text-muted">暂无本周数据</p>
      </div>
    </div>
    <div v-if="activeTab === 'summaries'" class="summaries-data">
      <div class="card">
        <h3 class="card-title">AI 总结</h3>
        <button @click="generateSummary" class="btn btn-primary mb-2">生成今日总结</button>
        <p v-if="!summaries.length" class="text-muted">暂无AI总结</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'
import api from '../utils/api'

const tabs = [{ value: 'daily', label: '今日' }, { value: 'weekly', label: '本周' }, { value: 'summaries', label: 'AI总结' }]
const activeTab = ref('daily')
const dailyRecord = ref(null)
const weeklyRecords = ref([])
const summaries = ref([])

function formatTime(isoString) { if (!isoString) return '--:--'; const date = new Date(isoString); return date.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' }) }

async function fetchDailyData() { try { const response = await api.get('/data/daily'); dailyRecord.value = response.data.daily_record } catch {} }
async function fetchWeeklyData() { try { const response = await api.get('/data/weekly'); weeklyRecords.value = response.data.records || [] } catch {} }
async function fetchSummaries() { try { const response = await api.get('/summaries'); summaries.value = response.data.summaries || [] } catch {} }

async function generateSummary() {
  try { await api.post('/summaries/generate', { type: 'daily' }); await fetchSummaries(); alert('总结生成成功！') } catch (error) { alert(error.response?.data?.error || '生成失败') }
}

watch(activeTab, (newTab) => { if (newTab === 'daily') fetchDailyData(); if (newTab === 'weekly') fetchWeeklyData(); if (newTab === 'summaries') fetchSummaries() })
onMounted(() => fetchDailyData())
</script>

<style scoped>
.data-page { max-width: 800px; margin: 0 auto; }
.data-tabs { display: flex; gap: 0.5rem; margin-bottom: 1.5rem; }
.data-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 1rem; }
.data-item { padding: 1rem; background: rgba(255, 255, 255, 0.05); border-radius: 8px; }
.data-label { display: block; font-size: 0.875rem; color: #a0a0a0; margin-bottom: 0.25rem; }
.data-value { font-size: 1.25rem; font-weight: 600; }
</style>