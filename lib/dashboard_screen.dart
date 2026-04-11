import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'reading_card.dart';
import 'flow_gauge.dart';
import 'cost_summary_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const double phpPerLiter = 16.08 / 1000.0;

  @override
  Widget build(BuildContext context) {
    final meterRef = FirebaseDatabase.instance.ref('meter');
    final historyRef = FirebaseDatabase.instance.ref('history');
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: StreamBuilder<DatabaseEvent>(
        stream: meterRef.onValue,
        builder: (context, meterSnapshot) {
          final meterHasData =
              meterSnapshot.hasData && meterSnapshot.data!.snapshot.value != null;

          final meterData = meterHasData
              ? Map<String, dynamic>.from(
                  meterSnapshot.data!.snapshot.value as Map,
                )
              : <String, dynamic>{};

          final pulsesPerSecond =
              ((meterData['pulsesPerSecond'] ?? 0) as num).toDouble();
          final flowRate = ((meterData['flowRate'] ?? 0) as num).toDouble();
          final totalLiters = ((meterData['totalLiters'] ?? 0) as num).toDouble();

          return StreamBuilder<DatabaseEvent>(
            stream: historyRef.onValue,
            builder: (context, historySnapshot) {
              final historyPoints =
                  _parseHistory(historySnapshot.data?.snapshot.value);

              final todayLiters = _usageForToday(historyPoints);
              final monthlyLiters = _usageForCurrentMonth(historyPoints);

              return CustomScrollView(
                slivers: [
                  SliverAppBar.large(
                    expandedHeight: 140,
                    backgroundColor: colorScheme.primaryContainer,
                    flexibleSpace: FlexibleSpaceBar(
                      title: const Text('Water Meter Reader'),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.primaryContainer,
                              colorScheme.primary.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _ConnectionChip(isConnected: meterHasData),
                      ),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        FlowGauge(
                          flowRate: flowRate,
                        ),
                        const SizedBox(height: 16),

                        ReadingCard(
                          title: 'Current Reading',
                          icon: Icons.speed,
                          value: totalLiters.toStringAsFixed(2),
                          unit: 'Liters',
                          subtitle: 'Total cumulative usage from ESP32 pulses',
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 12),

                        CostSummaryCard(
                          totalLiters: totalLiters,
                          dailyLiters: todayLiters,
                          monthlyLiters: monthlyLiters,
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: ReadingCard(
                                title: "Today's Usage",
                                icon: Icons.today,
                                value: todayLiters.toStringAsFixed(1),
                                unit: 'L',
                                color: colorScheme.secondary,
                                compact: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ReadingCard(
                                title: 'Flow Rate',
                                icon: Icons.water_outlined,
                                value: flowRate.toStringAsFixed(2),
                                unit: 'L/s',
                                color: colorScheme.tertiary,
                                compact: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        _DeviceInfoCard(
                          isConnected: meterHasData,
                          totalLiters: totalLiters,
                          flowRate: flowRate,
                          estimatedCost: totalLiters * phpPerLiter,
                          todayLiters: todayLiters,
                          monthlyLiters: monthlyLiters,
                        ),
                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
                ],
              );
            },
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

      DateTime? dt;
      if (timestamp < 10000000000) {
        dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      } else if (timestamp < 10000000000000) {
        dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }

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

  double _usageForToday(List<_HistoryPoint> points) {
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final startTotal = _latestTotalAtOrBefore(points, dayStart);
    final endTotal = _latestTotalBefore(points, dayEnd);

    return (endTotal - startTotal).clamp(0.0, double.infinity);
  }

  double _usageForCurrentMonth(List<_HistoryPoint> points) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonth = now.month == 12
        ? DateTime(now.year + 1, 1, 1)
        : DateTime(now.year, now.month + 1, 1);

    final startTotal = _latestTotalAtOrBefore(points, monthStart);
    final endTotal = _latestTotalBefore(points, nextMonth);

    return (endTotal - startTotal).clamp(0.0, double.infinity);
  }

  double _latestTotalAtOrBefore(List<_HistoryPoint> points, DateTime moment) {
    double total = 0.0;
    for (final p in points) {
      if (!p.timestamp.isAfter(moment)) {
        total = p.totalLiters;
      } else {
        break;
      }
    }
    return total;
  }

  double _latestTotalBefore(List<_HistoryPoint> points, DateTime moment) {
    double total = 0.0;
    for (final p in points) {
      if (p.timestamp.isBefore(moment)) {
        total = p.totalLiters;
      } else {
        break;
      }
    }
    return total;
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

class _ConnectionChip extends StatelessWidget {
  final bool isConnected;
  const _ConnectionChip({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        isConnected ? Icons.wifi : Icons.wifi_off,
        size: 16,
        color: isConnected ? Colors.green : Colors.red,
      ),
      label: Text(
        isConnected ? 'ESP32 Online' : 'Offline',
        style: TextStyle(
          color: isConnected ? Colors.green : Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: isConnected
          ? Colors.green.withOpacity(0.1)
          : Colors.red.withOpacity(0.1),
      side: BorderSide.none,
    );
  }
}

class _DeviceInfoCard extends StatelessWidget {
  final bool isConnected;
  final double totalLiters;
  final double flowRate;
  final double estimatedCost;
  final double todayLiters;
  final double monthlyLiters;

  const _DeviceInfoCard({
    required this.isConnected,
    required this.totalLiters,
    required this.flowRate,
    required this.estimatedCost,
    required this.todayLiters,
    required this.monthlyLiters,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.developer_board, color: colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'IoT Device',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow('Microcontroller', 'ESP32'),
            _InfoRow('Sensor', 'TCRT5000 IR Optical'),
            _InfoRow('Protocol', 'WiFi HTTP → Firebase'),
            _InfoRow('Status', isConnected ? 'Connected' : 'Disconnected'),
            _InfoRow('Flow Rate', '${flowRate.toStringAsFixed(2)} L/s'),
            _InfoRow('Today', '${todayLiters.toStringAsFixed(2)} L'),
            _InfoRow('This Month', '${monthlyLiters.toStringAsFixed(2)} L'),
            _InfoRow('Total Usage', '${totalLiters.toStringAsFixed(2)} L'),
            _InfoRow('Estimated Cost', '₱${estimatedCost.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}