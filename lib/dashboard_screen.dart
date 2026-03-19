import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'login_screen.dart';
import 'alerts_screen.dart';
import 'settings_screen.dart';
import 'history_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Index to track which bottom navigation tab is selected
  int _selectedIndex = 0;
  String _selectedTimeframe = 'Daily';
  // Function to handle tab switching
  void _onItemTapped(int index) {
    if (index == 1) { // History Icon
      Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
    } else if (index == 2) { // Alerts Icon
      Navigator.push(context, MaterialPageRoute(builder: (context) => const AlertsScreen()));
    } else if (index == 3) { // Settings Icon
      Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }
  List<FlSpot> _getChartData() {
    switch (_selectedTimeframe) {
      case 'Weekly':
        return const [FlSpot(0, 2000), FlSpot(1, 1500), FlSpot(2, 3000), FlSpot(3, 2200), FlSpot(4, 1800)];
      case 'Monthly':
        return const [FlSpot(0, 1000), FlSpot(1, 2800), FlSpot(2, 1200), FlSpot(3, 3900), FlSpot(4, 2500)];
      case 'Daily':
      default:
        return const [FlSpot(0, 1000), FlSpot(1, 1200), FlSpot(2, 2000), FlSpot(3, 2500), FlSpot(4, 3500), FlSpot(5, 4000)];
    }
  }


  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF15171E), // Dark background from design
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.white),
        actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () {
            // Navigate to the Settings Screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Icon and Title
            Row(
              children: [
                // Icon placeholder for the water meter image
                const Icon(Icons.water_drop, color: Colors.blueAccent, size: 40),
                const SizedBox(width: 12),
                const Text(
                  'Water Usage Monitoring',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Top Info Cards (Reading and Cost)
            Row(
              children: [
                Expanded(child: _buildInfoCard('Current Reading', '01234.57', 'm³', 'Today so far: 34.5 liters')),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard('Cost (PHP)', '₱975.50', '', 'Estimated Monthly Bill')),
              ],
            ),
            const SizedBox(height: 24),

            // Usage Toggle (Daily/Weekly/Monthly)
            _buildToggleBar(),
            const SizedBox(height: 16),

            // Usage Graph
            const Text('Daily Usage', style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              height: 200,
              padding: const EdgeInsets.only(top: 20, right: 20),
              decoration: BoxDecoration(color: const Color(0xFF22252E), borderRadius: BorderRadius.circular(16)),
              child: _buildMainChart(),
            ),
            const SizedBox(height: 24),

            // Alerts Section
            const Text('Alerts >>', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildAlertCard(context, 'Possible Leak Detected!', '> 60 liters used in the last hour'),
            const SizedBox(height: 12),
            _buildAlertCard(context, 'High Usage Alert', 'Usage exceeded 500 L/hr'),
          ],
        ),
      ),


      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF15171E),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  // Helper for info cards
  Widget _buildInfoCard(String title, String value, String unit, String sub) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF22252E), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text('$value $unit', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  // Helper for the Daily/Weekly/Monthly toggle
  Widget _buildToggleBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFF22252E), borderRadius: BorderRadius.circular(25)),
      child: Row(
        children: ['Daily', 'Weekly', 'Monthly'].map((timeframe) {
          bool isSelected = _selectedTimeframe == timeframe;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTimeframe = timeframe;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blueAccent.withOpacity(0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    timeframe == 'Daily' ? 'Daily Usage' : timeframe,
                    style: TextStyle(
                      color: isSelected ? Colors.blueAccent : Colors.grey,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // The Graph using fl_chart
  Widget _buildMainChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10), // Usage numbers in white
              ),
              reservedSize: 35,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // --- DYNAMIC DATE LOGIC ---
                String text = '';
                int index = value.toInt();

                if (_selectedTimeframe == 'Daily') {
                  // Show dates like Apr 1, Apr 2
                  List<String> days = ['Apr 1', 'Apr 2', 'Apr 3', 'Apr 4', 'Apr 5', 'Apr 7'];
                  if (index >= 0 && index < days.length) text = days[index];
                } else if (_selectedTimeframe == 'Weekly') {
                  // Show days of the week
                  List<String> weeks = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  if (index >= 0 && index < weeks.length) text = weeks[index];
                } else if (_selectedTimeframe == 'Monthly') {
                  // Show month names
                  List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                  if (index >= 0 && index < months.length) text = months[index];
                }

                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(
                    text,
                    style: const TextStyle(color: Colors.white, fontSize: 10), // Labels in white
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _getChartData(), // Calls our function to get coordinates
            isCurved: true,
            color: Colors.blueAccent,
            barWidth: 4,
            belowBarData: BarAreaData(show: true, color: Colors.blueAccent.withOpacity(0.1)),
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}

  // Helper for alert cards
Widget _buildAlertCard(BuildContext context, String title, String details) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: const Color(0xFF22252E), // Card background
        borderRadius: BorderRadius.circular(16)
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(details, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () {
            // Now 'context' is defined and usable!
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AlertsScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D47A1), // Blue button
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text('VIEW', style: TextStyle(color: Colors.white, fontSize: 12)),
        )
      ],
    ),
  );
}