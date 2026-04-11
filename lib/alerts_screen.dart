import 'package:flutter/material.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        backgroundColor: colorScheme.primaryContainer,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: colorScheme.primary),
            const SizedBox(height: 16),
            const Text(
              'Notifications are not set up yet.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}