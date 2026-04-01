import 'dart:async';
import 'package:flutter/material.dart';
import 'iot_service.dart';
import 'water_reading.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _service = IotService();
  StreamSubscription<WaterAlert>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = _service.alertStream.listen((_) {
      if (mounted) setState(() {});
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
    final alerts = _service.alerts;
    final unreadCount = alerts.where((a) => !a.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Alerts'),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Badge(label: Text('$unreadCount')),
            ],
          ],
        ),
        backgroundColor: colorScheme.primaryContainer,
        actions: [
          if (alerts.isNotEmpty)
            TextButton(
              onPressed: () {
                for (final a in alerts) {
                  _service.markAlertRead(a.id);
                }
                setState(() {});
              },
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: alerts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: colorScheme.primary),
                  const SizedBox(height: 16),
                  const Text('No alerts — all good!',
                      style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return _AlertTile(
                  alert: alert,
                  onTap: () {
                    _service.markAlertRead(alert.id);
                    setState(() {});
                  },
                );
              },
            ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final WaterAlert alert;
  final VoidCallback onTap;

  const _AlertTile({required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (icon, color, bgColor) = switch (alert.type) {
      AlertType.leak => (
          Icons.water_damage,
          Colors.orange,
          Colors.orange.withOpacity(0.1)
        ),
      AlertType.highUsage => (
          Icons.warning_amber,
          Colors.red,
          Colors.red.withOpacity(0.1)
        ),
      AlertType.offline => (
          Icons.wifi_off,
          Colors.grey,
          Colors.grey.withOpacity(0.1)
        ),
      AlertType.normal => (
          Icons.info_outline,
          colorScheme.primary,
          colorScheme.primaryContainer
        ),
    };

    return Card(
      elevation: 0,
      color: alert.isRead ? null : bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: alert.isRead ? colorScheme.outlineVariant : color.withOpacity(0.4),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          alert.message,
          style: TextStyle(
            fontWeight: alert.isRead ? FontWeight.normal : FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          _formatTime(alert.timestamp),
          style: TextStyle(
              color: colorScheme.onSurfaceVariant, fontSize: 12),
        ),
        trailing: !alert.isRead
            ? Icon(Icons.circle, size: 8, color: color)
            : null,
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
