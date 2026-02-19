import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('数据统计'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '今日'),
              Tab(text: '昨日'),
              Tab(text: '本周'),
              Tab(text: 'AI总结'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDataTab('今日数据'),
            _buildDataTab('昨日数据'),
            _buildDataTab('本周数据'),
            _buildSummaryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTab(String title) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            color: AppConstants.cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('休息', '0h 0m', AppConstants.restColor),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard('娱乐', '0h 0m', AppConstants.entertainmentColor),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard('学习', '0h 0m', AppConstants.studyColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: AppConstants.cardColor,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('暂无详细数据'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            color: AppConstants.cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI总结',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('日总结'),
                        selected: true,
                        onSelected: (_) {},
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('周总结'),
                        selected: false,
                        onSelected: (_) {},
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('月总结'),
                        selected: false,
                        onSelected: (_) {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('暂无AI总结'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
