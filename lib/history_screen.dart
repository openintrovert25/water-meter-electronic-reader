import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'iot_service.dart';
import 'water_reading.dart';
import 'package:intl/intl.dart' show DateFormat;

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final _service = IotService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usage History'),
        backgroundColor: colorScheme.primaryContainer,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UsageChart(
            summaries: _service.getDailySummaries(7),
            label: 'Last 7 Days',
          ),
          _UsageChart(
            summaries: _service.getDailySummaries(30),
            label: 'Last 30 Days',
          ),
          _UsageChart(
            summaries: _service.getDailySummaries(90),
            label: 'Last 90 Days',
          ),
        ],
      ),
    );
  }
}

class _UsageChart extends StatelessWidget {
  final List<UsageSummary> summaries;
  final String label;

  const _UsageChart({required this.summaries, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxLiters = summaries.isEmpty
        ? 100.0
        : summaries.map((s) => s.totalLiters).reduce((a, b) => a > b ? a : b);
    final yMax = maxLiters == 0 ? 100.0 : maxLiters * 1.2;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            'Total: ${summaries.fold(0.0, (sum, s) => sum + s.totalLiters).toStringAsFixed(1)} L  '
            '|  Est. Cost: ₱${summaries.fold(0.0, (sum, s) => sum + s.totalCostPhp).toStringAsFixed(2)}',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),

          // Bar chart
          SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                maxY: yMax,
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(1)} L',
                        TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= summaries.length) return const SizedBox();
                        final date = summaries[idx].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('M/d').format(date),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}L',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: yMax / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.outlineVariant,
                    strokeWidth: 0.5,
                  ),
                ),
                barGroups: summaries.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.totalLiters,
                        color: colorScheme.primary,
                        width: summaries.length <= 10 ? 20 : 8,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Table summary
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: const [
                      Expanded(
                          child: Text('Date',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(
                          child: Text('Usage (L)',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(
                          child: Text('Cost (₱)',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                // Rows
                ...summaries.reversed.take(10).map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                            top: BorderSide(color: colorScheme.outlineVariant, width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              child:
                                  Text(DateFormat('MMM d').format(s.date))),
                          Expanded(
                              child: Text(
                                  s.totalLiters.toStringAsFixed(1),
                                  textAlign: TextAlign.right)),
                          Expanded(
                              child: Text(
                                  '₱${s.totalCostPhp.toStringAsFixed(2)}',
                                  textAlign: TextAlign.right)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
