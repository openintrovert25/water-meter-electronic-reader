import 'dart:async';
import 'package:flutter/material.dart';
import 'iot_service.dart';
import 'water_reading.dart';
import 'reading_card.dart';
import 'flow_gauge.dart';
import 'cost_summary_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = IotService();
  StreamSubscription<WaterReading>? _sub;
  WaterReading? _latestReading;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _service.initialize();
    setState(() => _isConnected = _service.isConnected);

    _sub = _service.readingStream.listen((reading) {
      if (mounted) setState(() => _latestReading = reading);
    });

    _service.connectionStream.listen((connected) {
      if (mounted) setState(() => _isConnected = connected);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
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
                child: _ConnectionChip(isConnected: _isConnected),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // --- Live flow gauge ---
                FlowGauge(
                  flowRate: _latestReading?.flowRate ?? 0,
                ),
                const SizedBox(height: 16),

                // --- ESP32-CAM meter image (shown when imageUrl is available) ---
                if (_latestReading?.imageUrl != null &&
                    _latestReading!.imageUrl!.isNotEmpty)
                  _MeterImageCard(imageUrl: _latestReading!.imageUrl!),
                if (_latestReading?.imageUrl != null &&
                    _latestReading!.imageUrl!.isNotEmpty)
                  const SizedBox(height: 12),

                // --- Current reading ---
                ReadingCard(
                  title: 'Current Reading',
                  icon: Icons.speed,
                  value: _service.totalLiters.toStringAsFixed(2),
                  unit: 'Liters',
                  subtitle: 'Total cumulative usage (TCRT5000 optical pulses)',
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 12),

                // --- Cost summary ---
                CostSummaryCard(
                  totalLiters: _service.totalLiters,
                  dailyLiters: _getDailyUsage(),
                  monthlyLiters: _getMonthlyUsage(),
                ),
                const SizedBox(height: 12),

                // --- Quick stats row ---
                Row(
                  children: [
                    Expanded(
                      child: ReadingCard(
                        title: "Today's Usage",
                        icon: Icons.today,
                        value: _getDailyUsage().toStringAsFixed(1),
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
                        value: (_latestReading?.flowRate ?? 0)
                            .toStringAsFixed(2),
                        unit: 'L/min',
                        color: colorScheme.tertiary,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // --- IoT device info ---
                _DeviceInfoCard(isConnected: _isConnected),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  double _getDailyUsage() {
    final readings = _service.getReadingsForPeriod(const Duration(hours: 24));
    return WaterReading.periodConsumption(readings);
  }

  double _getMonthlyUsage() {
    final readings = _service.getReadingsForPeriod(const Duration(days: 30));
    return WaterReading.periodConsumption(readings);
  }
}

// ---------------------------------------------------------------------------
// Meter Image Card — shows the latest photo taken by the ESP32-CAM
// ---------------------------------------------------------------------------
class _MeterImageCard extends StatelessWidget {
  final String imageUrl;
  const _MeterImageCard({required this.imageUrl});

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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.camera_alt_outlined, color: colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Latest Meter Photo (ESP32-CAM)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                    height: 180,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 100,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_outlined,
                          color: colorScheme.onSurfaceVariant),
                      const SizedBox(height: 4),
                      Text('Image unavailable',
                          style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Connection chip
// ---------------------------------------------------------------------------
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
        isConnected ? 'ESP32-CAM Online' : 'Offline',
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

// ---------------------------------------------------------------------------
// Device info card
// ---------------------------------------------------------------------------
class _DeviceInfoCard extends StatelessWidget {
  final bool isConnected;
  const _DeviceInfoCard({required this.isConnected});

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
            _InfoRow('Microcontroller', 'ESP32-CAM (AI-Thinker)'),
            _InfoRow('Sensor', 'TCRT5000 IR Optical'),
            _InfoRow('Camera', 'OV2640 (2MP)'),
            _InfoRow('Protocol', 'HTTP POST → Firebase'),
            _InfoRow('Status', isConnected ? 'Connected' : 'Disconnected'),
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
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}