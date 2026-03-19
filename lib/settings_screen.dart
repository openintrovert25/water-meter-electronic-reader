import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF15171E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('IOT DEVICE CONFIG', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildSettingItem(Icons.router, 'Device ID', 'ARD-WATER-001'),
          _buildSettingItem(Icons.straighten, 'Sensor Calibration', '450 pulses/liter'),
          const Divider(color: Colors.white10, height: 32),
          const Text('BILLING CONFIG', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildSettingItem(Icons.payments, 'Rate per m³', '₱27.00'),
          _buildSettingItem(Icons.calendar_today, 'Billing Cycle', 'Every 15th'),
          const Divider(color: Colors.white10, height: 32),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              // 1. Get SharedPreferences instance
              SharedPreferences prefs = await SharedPreferences.getInstance();

              // 2. Set isLoggedIn to false so the app doesn't auto-login next time
              await prefs.setBool('isLoggedIn', false);

              // 3. Navigate back to LoginScreen and clear the navigation stack
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false, // This prevents the user from clicking 'back' to the dashboard
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(value, style: const TextStyle(color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}