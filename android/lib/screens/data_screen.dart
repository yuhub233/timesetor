import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});
  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  int _currentTab = 0;
  Map<String, dynamic>? _dailyRecord;
  List<dynamic> _summaries = [];
  bool _isLoading = false;
  
  @override
  void initState() { super.initState(); _fetchDailyData(); }
  
  Future<void> _fetchDailyData() async {
    setState(() => _isLoading = true);
    try { final response = await ApiService.get('/data/daily'); setState(() => _dailyRecord = response['daily_record']); } catch (_) {}
    setState(() => _isLoading = false);
  }
  
  Future<void> _fetchSummaries() async {
    setState(() => _isLoading = true);
    try { final response = await ApiService.get('/summaries'); setState(() => _summaries = response['summaries'] ?? []); } catch (_) {}
    setState(() => _isLoading = false);
  }
  
  Future<void> _generateSummary() async {
    try { await ApiService.post('/summaries/generate', {'type': 'daily'}); await _fetchSummaries(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('总结生成成功！'))); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('生成失败: $e'))); }
  }
  
  String _formatTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '--:--';
    try { final dateTime = DateTime.parse(isoString); return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}'; } catch (_) { return '--:--'; }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据统计')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: () { setState(() => _currentTab = 0); _fetchDailyData(); }, style: ElevatedButton.styleFrom(backgroundColor: _currentTab == 0 ? null : Colors.grey.withOpacity(0.2)), child: const Text('今日'))),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(onPressed: () { setState(() => _currentTab = 1); }, style: ElevatedButton.styleFrom(backgroundColor: _currentTab == 1 ? null : Colors.grey.withOpacity(0.2)), child: const Text('本周'))),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(onPressed: () { setState(() => _currentTab = 2); _fetchSummaries(); }, style: ElevatedButton.styleFrom(backgroundColor: _currentTab == 2 ? null : Colors.grey.withOpacity(0.2)), child: const Text('AI总结'))),
              ],
            ),
          ),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildContent(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent() {
    if (_currentTab == 0) return _buildDailyContent();
    if (_currentTab == 2) return _buildSummariesContent();
    return const Center(child: Text('暂无数据'));
  }
  
  Widget _buildDailyContent() {
    if (_dailyRecord == null) return const Center(child: Text('暂无今日数据'));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildDataRow('起床时间', _formatTime(_dailyRecord!['real_wake_time'])),
              _buildDataRow('不常规起床', _dailyRecord!['real_wake_time_display'] ?? '--:--'),
              _buildDataRow('娱乐时长', '${_dailyRecord!['actual_entertainment_minutes'] ?? 0} 分钟'),
              _buildDataRow('学习时长', '${_dailyRecord!['actual_study_minutes'] ?? 0} 分钟'),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSummariesContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton(onPressed: _generateSummary, child: const Text('生成今日总结')),
          const SizedBox(height: 16),
          if (_summaries.isEmpty) const Center(child: Text('暂无AI总结')) else ..._summaries.map((summary) => Card(
            color: const Color(0xFF1A1A2E),
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(summary['summary_type'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF667EEA))),
                  const SizedBox(height: 8),
                  Text(summary['summary_text'] ?? ''),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
  
  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: TextStyle(color: Colors.grey[400])), Text(value, style: const TextStyle(fontWeight: FontWeight.w600))],
      ),
    );
  }
}