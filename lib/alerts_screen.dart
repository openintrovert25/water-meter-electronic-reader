import 'package:flutter/material.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF15171E), // Matching dark theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Alert Notifications', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context), // Goes back to Dashboard
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDetailedAlert(
              'Possible Leak Detected!',
              '> 60 liters used in the last hour\nLocation: Main Pipe A\nStatus: Unresolved',
              'Today, 7:10 AM',
              Colors.orange
          ),
          const SizedBox(height: 16),
          _buildDetailedAlert(
              'High Usage Alert',
              'Usage exceeded 500 L/hr\nTypical usage: 150 L/hr',
              'Yesterday, 9:23 PM',
              Colors.orange
          ),
          const SizedBox(height: 16),
          _buildDetailedAlert(
              'System Maintenance',
              'Scheduled server maintenance completed successfully.',
              'March 15, 10:00 AM',
              Colors.blueAccent
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedAlert(String title, String desc, String time, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF22252E), // Card color from design
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: iconColor, size: 28),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const Divider(color: Colors.white10, height: 24),
          Text(time, style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}