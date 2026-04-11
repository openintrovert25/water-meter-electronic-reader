import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _ref = FirebaseDatabase.instance.ref('history');

  static const double phpPerLiter = 16.08 / 1000.0;

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
      body: StreamBuilder<DatabaseEvent>(
        stream: _ref.onValue,
        builder: (context, snapshot) {
          final points = _parseHistory(snapshot.data?.snapshot.value);

          return TabBarView(
            controller: _tabController,
            children: [
              _UsageChart(
                summaries: _buildDailySummaries(points, 7),
                label: 'Last 7 Days',
              ),
              _UsageChart(
                summaries: _buildDailySummaries(points, 30),
                label: 'Last 30 Days',
              ),
              _UsageChart(
                summaries: _buildDailySummaries(points, 90),
                label: 'Last 90 Days',
              ),
            ],
          );
        },
      ),
    );
  }

  List<_HistoryPoint> _parseHistory(Object? raw) {
    if (raw == null) return [];

    final map = Map<String, dynamic>.from(raw as Map);
    final points = <_HistoryPoint>[];

    for (final value in map.values) {
      final item = Map<String, dynamic>.from(value as Map);

      final rawTimestamp = item['timestamp'];
      final rawTotalLiters = item['totalLiters'];

      if (rawTimestamp == null || rawTotalLiters == null) continue;

      final timestamp = (rawTimestamp as num).toInt();
      final totalLiters = (rawTotalLiters as num).toDouble();

      final dt = _normalizeTimestamp(timestamp);
      if (dt != null) {
        points.add(
          _HistoryPoint(
            timestamp: dt,
            totalLiters: totalLiters,
          ),
        );
      }
    }

    points.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return points;
  }

  DateTime? _normalizeTimestamp(int ts) {
    // if timestamp is in seconds, convert to milliseconds
    if (ts < 10000000000) {
      return DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    }
    // if timestamp is already in milliseconds
    if (ts < 10000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(ts);
    }
    return null;
  }

  List<_UsageSummary> _buildDailySummaries(List<_HistoryPoint> points, int days) {
    final summaries = <_UsageSummary>[];
    final now = DateTime.now();

    for (int i = days - 1; i >= 0; i--) {
      final dayStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dayEnd = dayStart.add(const Duration(days: 1));

      final pointsForDay = points
          .where((p) =>
              !p.timestamp.isBefore(dayStart) && p.timestamp.isBefore(dayEnd))
          .toList();

      double liters = 0.0;

      if (pointsForDay.isNotEmpty) {
        final first = pointsForDay.first.totalLiters;
        final last = pointsForDay.last.totalLiters;
        liters = (last - first).clamp(0.0, double.infinity);
      }

      summaries.add(
        _UsageSummary(
          date: dayStart,
          totalLiters: liters,
          totalCostPhp: liters * phpPerLiter,
        ),
      );
    }

    return summaries;
  }
}

class _HistoryPoint {
  final DateTime timestamp;
  final double totalLiters;

  _HistoryPoint({
    required this.timestamp,
    required this.totalLiters,
  });
}

class _UsageSummary {
  final DateTime date;
  final double totalLiters;
  final double totalCostPhp;

  _UsageSummary({
    required this.date,
    required this.totalLiters,
    required this.totalCostPhp,
  });
}

class _UsageChart extends StatelessWidget {
  final List<_UsageSummary> summaries;
  final String label;

  const _UsageChart({
    required this.summaries,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final totalLiters = summaries.fold(0.0, (sum, s) => sum + s.totalLiters);
    final totalCost = summaries.fold(0.0, (sum, s) => sum + s.totalCostPhp);

    final maxLiters = summaries.isEmpty
        ? 100.0
        : summaries.map((s) => s.totalLiters).reduce((a, b) => a > b ? a : b);

    final yMax = maxLiters == 0 ? 100.0 : maxLiters * 1.2;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'Total: ${totalLiters.toStringAsFixed(1)} L | Est. Cost: ₱${totalCost.toStringAsFixed(2)}',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),

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
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= summaries.length) return const SizedBox();

                        final step = summaries.length > 60
                            ? 15
                            : summaries.length > 30
                                ? 7
                                : 1;

                        if (idx % step != 0) return const SizedBox();

                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('M/d').format(summaries[idx].date),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
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
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Date',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Usage (L)',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Cost (₱)',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                ...summaries.reversed.take(10).map(
                  (s) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: colorScheme.outlineVariant,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(DateFormat('MMM d').format(s.date))),
                        Expanded(
                          child: Text(
                            s.totalLiters.toStringAsFixed(1),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '₱${s.totalCostPhp.toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}