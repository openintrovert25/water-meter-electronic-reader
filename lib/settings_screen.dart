import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _rateController = TextEditingController(text: '16.08');
  final _litersPerPulseController = TextEditingController(text: '1.0');
  final _leakThresholdController = TextEditingController(text: '0.02');

  bool _notificationsEnabled = true;

  final _meterRef = FirebaseDatabase.instance.ref('meter');
  final _historyRef = FirebaseDatabase.instance.ref('history');

  bool _deviceConnected = false;
  DateTime? _lastUpdate;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _listenToDeviceStatus();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rateController.text =
          (prefs.getDouble('water_rate') ?? 16.08).toString();
      _litersPerPulseController.text =
          (prefs.getDouble('liters_per_pulse') ?? 1.0).toString();
      _leakThresholdController.text =
          (prefs.getDouble('leak_threshold') ?? 0.02).toString();
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(
      'water_rate',
      double.tryParse(_rateController.text) ?? 16.08,
    );
    await prefs.setDouble(
      'liters_per_pulse',
      double.tryParse(_litersPerPulseController.text) ?? 1.0,
    );
    await prefs.setDouble(
      'leak_threshold',
      double.tryParse(_leakThresholdController.text) ?? 0.02,
    );
    await prefs.setBool('notifications_enabled', _notificationsEnabled);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _listenToDeviceStatus() {
    _meterRef.onValue.listen((event) {
      final hasData = event.snapshot.value != null;
      if (mounted) {
        setState(() {
          _deviceConnected = hasData;
        });
      }
    });

    _historyRef.limitToLast(1).onValue.listen((event) {
      if (event.snapshot.value == null) return;

      final map = Map<String, dynamic>.from(event.snapshot.value as Map);
      if (map.isEmpty) return;

      final latest = Map<String, dynamic>.from(map.values.first as Map);
      final rawTimestamp = latest['timestamp'];

      if (rawTimestamp is num) {
        final ts = rawTimestamp.toInt();
        DateTime? dt;

        // supports seconds or milliseconds
        if (ts < 10000000000) {
          dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
        } else if (ts < 10000000000000) {
          dt = DateTime.fromMillisecondsSinceEpoch(ts);
        }

        if (mounted) {
          setState(() {
            _lastUpdate = dt;
          });
        }
      }
    });
  }

  Future<void> _resetUsageData() async {
    final confirmed = await _confirmAction(
      title: 'Reset Water Usage',
      message:
          'This will clear current meter data and history in Firebase. '
          'If the ESP32 is still running, it may send fresh values again.',
      confirmText: 'Reset',
      confirmColor: Colors.orange,
    );

    if (confirmed != true) return;

    await _meterRef.remove();
    await _historyRef.remove();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Firebase usage data reset'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _clearHistory() async {
    final confirmed = await _confirmAction(
      title: 'Clear History',
      message: 'This will delete all saved history records from Firebase.',
      confirmText: 'Clear',
      confirmColor: Colors.red,
    );

    if (confirmed != true) return;

    await _historyRef.remove();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('History cleared'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  String _formatLastUpdate() {
    if (_lastUpdate == null) return 'No history yet';
    return DateFormat('MMM d, h:mm:ss a').format(_lastUpdate!);
  }

  @override
  void dispose() {
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
          _SectionHeader('IoT Device (ESP32)'),
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
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Connection',
                      prefixIcon: const Icon(Icons.cloud_done_outlined),
                      border: const OutlineInputBorder(),
                      hintText: 'Firebase Realtime Database',
                      helperText:
                          'Live data is sent by the ESP32 through Firebase',
                      suffixText: 'Cloud',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Device Status',
                      prefixIcon: Icon(
                        _deviceConnected ? Icons.wifi : Icons.wifi_off,
                        color: _deviceConnected ? Colors.green : Colors.red,
                      ),
                      border: const OutlineInputBorder(),
                      hintText: _deviceConnected ? 'Connected' : 'Disconnected',
                      helperText: 'Current live connection state',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Last Update',
                      prefixIcon: const Icon(Icons.update_outlined),
                      border: const OutlineInputBorder(),
                      hintText: _formatLastUpdate(),
                      helperText: 'Based on the latest history snapshot',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

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
                        Icon(Icons.sensors, color: colorScheme.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'TCRT5000 IR Optical Sensor:\n'
                            'Detects the reflective point on your water meter. '
                            'Adjust the calibration below if your meter uses a different pulse-to-liter ratio.',
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
                      prefixIcon: Icon(Icons.tune),
                      border: OutlineInputBorder(),
                      helperText:
                          'Adjust this based on your actual meter accuracy',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _leakThresholdController,
                    decoration: const InputDecoration(
                      labelText: 'Leak Alert Threshold (L/min)',
                      hintText: '0.02',
                      prefixIcon: Icon(Icons.water_damage_outlined),
                      border: OutlineInputBorder(),
                      helperText:
                          'Show an alert when flow stays above this threshold',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          _SectionHeader('Water Rate (Philippines)'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
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
            ),
          ),

          const SizedBox(height: 16),

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
                    'Leak detection and high usage notifications',
                  ),
                  value: _notificationsEnabled,
                  onChanged: (v) => setState(() => _notificationsEnabled = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _SectionHeader('Actions'),
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
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _resetUsageData,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Reset Water Usage'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _clearHistory,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Clear History Data'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

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
                  trailing: Text('1.0.0'),
                ),
                ListTile(
                  title: Text('Project'),
                  trailing: Text('Water Meter Electronic Reader'),
                ),
                ListTile(
                  title: Text('Microcontroller'),
                  trailing: Text('ESP32'),
                ),
                ListTile(
                  title: Text('Sensor'),
                  trailing: Text('TCRT5000 IR Optical'),
                ),
                ListTile(
                  title: Text('Backend'),
                  trailing: Text('Flutter + Firebase'),
                ),
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