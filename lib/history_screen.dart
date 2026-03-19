import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF15171E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Usage History', style: TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildMonthSummary('March 2024', '42.5', '1,147.50'),
          _buildMonthSummary('February 2024', '38.2', '1,031.40'),
          _buildMonthSummary('January 2024', '45.0', '1,215.00'),
          _buildMonthSummary('December 2023', '50.1', '1,352.70'),
        ],
      ),
    );
  }

  Widget _buildMonthSummary(String month, String consumption, String cost) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF22252E), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(month, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('$consumption m³ used', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Text('₱$cost', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}