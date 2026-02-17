import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  int _currentTab = 0;
  int _currentPeriod = 0;
  Map<String, dynamic>? _dailyRecord;
  List<dynamic> _periodRecords = [];
  List<dynamic> _summaries = [];
  bool _isLoading = false;
  String? _summaryTypeFilter;
  
  final List<String> _periodLabels = ['今日', '昨日', '本周', '本月', '本年'];
  
  @override
  void initState() {
    super.initState();
    _fetchData();
  }
  
  Future<void> _fetchData() async {
    switch (_currentTab) {
      case 0:
        await _fetchDailyData();
        break;
      case 1:
        await _fetchPeriodData();
        break;
      case 2:
        await _fetchSummaries();
        break;
    }
  }
  
  Future<void> _fetchDailyData() async {
    setState(() => _isLoading = true);
    try {
      DateTime targetDate;
      if (_currentPeriod == 1) {
        targetDate = DateTime.now().subtract(const Duration(days: 1));
      } else {
        targetDate = DateTime.now();
      }
      
      final response = await ApiService.get('/data/daily?date=${targetDate.toIso8601String().split('T')[0]}');
      setState(() => _dailyRecord = response['daily_record']);
    } catch (_) {
      setState(() => _dailyRecord = null);
    }
    setState(() => _isLoading = false);
  }
  
  Future<void> _fetchPeriodData() async {
    setState(() => _isLoading = true);
    try {
      String endpoint;
      switch (_currentPeriod) {
        case 0:
        case 1:
          endpoint = '/data/daily';
          break;
        case 2:
          endpoint = '/data/weekly';
          break;
        case 3:
          endpoint = '/data/monthly';
          break;
        case 4:
          endpoint = '/data/yearly';
          break;
        default:
          endpoint = '/data/weekly';
      }
      
      final response = await ApiService.get(endpoint);
      setState(() => _periodRecords = response['records'] ?? []);
    } catch (_) {
      setState(() => _periodRecords = []);
    }
    setState(() => _isLoading = false);
  }
  
  Future<void> _fetchSummaries() async {
    setState(() => _isLoading = true);
    try {
      String? typeParam;
      if (_summaryTypeFilter != null && _summaryTypeFilter != 'all') {
        typeParam = _summaryTypeFilter;
      }
      
      final url = typeParam != null ? '/summaries?type=$typeParam' : '/summaries';
      final response = await ApiService.get(url);
      setState(() => _summaries = response['summaries'] ?? []);
    } catch (_) {
      setState(() => _summaries = []);
    }
    setState(() => _isLoading = false);
  }
  
  Future<void> _generateSummary() async {
    try {
      await ApiService.post('/summaries/generate', {'type': 'daily'});
      await _fetchSummaries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('总结生成成功！')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e')),
        );
      }
    }
  }
  
  String _formatTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '--:--';
    try {
      final dateTime = DateTime.parse(isoString);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '--:--';
    }
  }
  
  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.month}/${date.day}';
    } catch (_) {
      return '';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据统计')),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildTab('数据', 0, () {
            setState(() => _currentTab = 0);
            _fetchDailyData();
          }),
          const SizedBox(width: 8),
          _buildTab('趋势', 1, () {
            setState(() => _currentTab = 1);
            _fetchPeriodData();
          }),
          const SizedBox(width: 8),
          _buildTab('AI总结', 2, () {
            setState(() => _currentTab = 2);
            _fetchSummaries();
          }),
        ],
      ),
    );
  }
  
  Widget _buildTab(String label, int index, VoidCallback onTap) {
    final isSelected = _currentTab == index;
    return Expanded(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? null : Colors.grey.withOpacity(0.2),
          foregroundColor: isSelected ? null : Colors.grey,
        ),
        child: Text(label),
      ),
    );
  }
  
  Widget _buildContent() {
    switch (_currentTab) {
      case 0:
        return _buildDailyContent();
      case 1:
        return _buildTrendContent();
      case 2:
        return _buildSummariesContent();
      default:
        return const SizedBox();
    }
  }
  
  Widget _buildDailyContent() {
    return Column(
      children: [
        _buildPeriodSelector(),
        Expanded(
          child: _dailyRecord == null
              ? const Center(child: Text('暂无数据'))
              : SingleChildScrollView(
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
                          _buildDataRow('休息时长', '${_dailyRecord!['actual_rest_minutes'] ?? 0} 分钟'),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
  
  Widget _buildPeriodSelector() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _periodLabels.length,
        itemBuilder: (context, index) {
          final isSelected = _currentPeriod == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_periodLabels[index]),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _currentPeriod = index);
                _fetchDailyData();
              },
              selectedColor: const Color(0xFF667EEA),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildTrendContent() {
    return Column(
      children: [
        _buildTrendPeriodSelector(),
        Expanded(
          child: _periodRecords.isEmpty
              ? const Center(child: Text('暂无数据'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _periodRecords.length,
                  itemBuilder: (context, index) {
                    final record = _periodRecords[index];
                    return Card(
                      color: const Color(0xFF1A1A2E),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(_formatDate(record['date'])),
                        subtitle: Text(
                          '娱乐: ${record['actual_entertainment_minutes'] ?? 0}分钟 | '
                          '学习: ${record['actual_study_minutes'] ?? 0}分钟',
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildTrendPeriodSelector() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ['本周', '本月', '本年'].length,
        itemBuilder: (context, index) {
          final periods = [2, 3, 4];
          final labels = ['本周', '本月', '本年'];
          final isSelected = _currentPeriod == periods[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(labels[index]),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _currentPeriod = periods[index]);
                _fetchPeriodData();
              },
              selectedColor: const Color(0xFF667EEA),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildSummariesContent() {
    return Column(
      children: [
        _buildSummaryFilter(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _generateSummary,
            child: const Text('生成今日总结'),
          ),
        ),
        Expanded(
          child: _summaries.isEmpty
              ? const Center(child: Text('暂无AI总结'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _summaries.length,
                  itemBuilder: (context, index) {
                    final summary = _summaries[index];
                    return Card(
                      color: const Color(0xFF1A1A2E),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _getSummaryTypeLabel(summary['summary_type']),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF667EEA),
                                  ),
                                ),
                                Text(
                                  _formatDate(summary['period_start']),
                                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(summary['summary_text'] ?? ''),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildSummaryFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          final filters = [null, 'daily', 'weekly', 'monthly', 'yearly'];
          final labels = ['全部', '日总结', '周总结', '月总结', '年总结'];
          final isSelected = _summaryTypeFilter == filters[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(labels[index]),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _summaryTypeFilter = filters[index]);
                _fetchSummaries();
              },
              selectedColor: const Color(0xFF667EEA),
            ),
          );
        },
      ),
    );
  }
  
  String _getSummaryTypeLabel(String? type) {
    switch (type) {
      case 'daily':
        return '日总结';
      case 'weekly':
        return '周总结';
      case 'monthly':
        return '月总结';
      case 'yearly':
        return '年总结';
      default:
        return '总结';
    }
  }
  
  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
