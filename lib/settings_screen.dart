import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _espIpController = TextEditingController(text: '192.168.1.100');
  final _rateController = TextEditingController(text: '16.08');
  final _litersPerPulseController = TextEditingController(text: '1.0');
  final _leakThresholdController = TextEditingController(text: '0.02');
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _espIpController.text = prefs.getString('esp_ip') ?? '192.168.1.100';
      _rateController.text =
          (prefs.getDouble('water_rate') ?? 16.08).toString();
      _litersPerPulseController.text =
          (prefs.getDouble('liters_per_pulse') ?? 1.0).toString();
      _leakThresholdController.text =
          (prefs.getDouble('leak_threshold') ?? 0.02).toString();
      _notificationsEnabled =
          prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('esp_ip', _espIpController.text);
    await prefs.setDouble(
        'water_rate', double.tryParse(_rateController.text) ?? 16.08);
    await prefs.setDouble('liters_per_pulse',
        double.tryParse(_litersPerPulseController.text) ?? 1.0);
    await prefs.setDouble('leak_threshold',
        double.tryParse(_leakThresholdController.text) ?? 0.02);
    await prefs.setBool('notifications_enabled', _notificationsEnabled);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _espIpController.dispose();
    _rateController.dispose();
    _litersPerPulseController.dispose();
    _leakThresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: colorScheme.primaryContainer,
        actions: [
          TextButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- IoT Device ---
          _SectionHeader('IoT Device (ESP32-CAM)'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _espIpController,
                    decoration: const InputDecoration(
                      labelText: 'ESP32-CAM IP Address',
                      hintText: '192.168.1.100',
                      prefixIcon: Icon(Icons.router),
                      border: OutlineInputBorder(),
                      helperText:
                          'Local IP assigned to your ESP32-CAM on Wi-Fi',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'MQTT Broker (optional)',
                      hintText: 'mqtt://broker.local:1883',
                      prefixIcon: Icon(Icons.cloud_outlined),
                      border: OutlineInputBorder(),
                      helperText:
                          'Leave blank if using direct HTTP POST to Firebase',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // --- Sensor Calibration ---
          _SectionHeader('Sensor Calibration (TCRT5000 IR Optical)'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.sensors,
                            color: colorScheme.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'TCRT5000 IR Optical Sensor:\n'
                            'Detects the reflective spot on your meter\'s '
                            'low-flow dial. Each pulse corresponds to a fixed '
                            'volume of water (typically 1 liter on most '
                            'Philippine residential meters). Adjust below if '
                            'your meter has a different resolution.',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _litersPerPulseController,
                    decoration: const InputDecoration(
                      labelText: 'Liters per pulse (L/pulse)',
                      hintText: '1.0',
                      prefixIcon: Icon(Icons.sensors_outlined),
                      border: OutlineInputBorder(),
                      helperText:
                          'Common values: 1.0 L (standard), 0.5 L, 0.1 L — '
                          'check your meter face for the "1 imp = X L" label',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _leakThresholdController,
                    decoration: const InputDecoration(
                      labelText: 'Leak detection threshold (L/min)',
                      hintText: '0.02',
                      prefixIcon: Icon(Icons.water_damage_outlined),
                      border: OutlineInputBorder(),
                      helperText:
                          'Alert if flow stays above this rate with no taps open.\n'
                          'TCRT5000 can detect as low as ~0.01 L/min.',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // --- Camera ---
          _SectionHeader('ESP32-CAM Settings'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.camera_alt_outlined,
                            color: colorScheme.secondary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'The ESP32-CAM periodically photographs the meter '
                            'face. Images are uploaded to Firebase Storage. '
                            'You can view the latest photo in the Dashboard '
                            'to visually verify the reading.',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Camera capture interval (seconds)',
                      hintText: '60',
                      prefixIcon: Icon(Icons.timer_outlined),
                      border: OutlineInputBorder(),
                      helperText:
                          'How often the ESP32-CAM takes a meter photo',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // --- Billing ---
          _SectionHeader('Water Rate (Philippines)'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _rateController,
                    decoration: const InputDecoration(
                      labelText: 'Rate per cubic meter (₱)',
                      hintText: '16.08',
                      prefixIcon: Icon(Icons.currency_exchange),
                      border: OutlineInputBorder(),
                      helperText: 'MWSS Tier 1 default: ₱16.08 / cu.m',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // --- Notifications ---
          _SectionHeader('Notifications'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable Alerts'),
                  subtitle: const Text(
                      'Leak detection & high usage notifications'),
                  value: _notificationsEnabled,
                  onChanged: (v) => setState(() => _notificationsEnabled = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- About ---
          _SectionHeader('About'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: const Column(
              children: [
                ListTile(
                    title: Text('App Version'),
                    trailing: Text('1.0.0')),
                ListTile(
                    title: Text('Project'),
                    trailing: Text('Water Meter Electronic Reader')),
                ListTile(
                    title: Text('Microcontroller'),
                    trailing: Text('ESP32-CAM')),
                ListTile(
                    title: Text('Sensor'),
                    trailing: Text('TCRT5000 IR Optical')),
                ListTile(
                    title: Text('Backend'),
                    trailing: Text('Flutter + Firebase')),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}