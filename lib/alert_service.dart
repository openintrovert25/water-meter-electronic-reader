import 'package:flutter/foundation.dart';

class AppAlert {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;

  AppAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
  });
}

class AlertService {
  AlertService._();
  static final AlertService instance = AlertService._();

  final ValueNotifier<List<AppAlert>> alerts = ValueNotifier<List<AppAlert>>([]);

  DateTime? _lastHighFlowAlert;
  DateTime? _lastLeakAlert;
  DateTime? _lastOfflineAlert;

  bool _isInHighFlowState = false;
  bool _isInLeakState = false;
  bool _isOfflineState = false;

  void checkStatus({
    required bool isConnected,
    required double flowRate,
  }) {
    final now = DateTime.now();

    if (!isConnected) {
      if (!_isOfflineState && _canSend(_lastOfflineAlert, const Duration(minutes: 5))) {
        _addAlert(
          title: 'Device Offline',
          message: 'ESP32 is not sending data right now.',
          timestamp: now,
        );
        _lastOfflineAlert = now;
      }
      _isOfflineState = true;
    } else {
      _isOfflineState = false;
    }

    if (flowRate >= 0.80) {
      if (!_isInHighFlowState && _canSend(_lastHighFlowAlert, const Duration(minutes: 3))) {
        _addAlert(
          title: 'High Water Flow',
          message: 'Flow rate is ${flowRate.toStringAsFixed(2)} L/s.',
          timestamp: now,
        );
        _lastHighFlowAlert = now;
      }
      _isInHighFlowState = true;
    } else {
      _isInHighFlowState = false;
    }

    if (flowRate >= 1.50) {
      if (!_isInLeakState && _canSend(_lastLeakAlert, const Duration(minutes: 3))) {
        _addAlert(
          title: 'Possible Leak',
          message: 'Very high continuous flow detected: ${flowRate.toStringAsFixed(2)} L/s.',
          timestamp: now,
        );
        _lastLeakAlert = now;
      }
      _isInLeakState = true;
    } else {
      _isInLeakState = false;
    }
  }

  bool _canSend(DateTime? lastTime, Duration cooldown) {
    if (lastTime == null) return true;
    return DateTime.now().difference(lastTime) >= cooldown;
  }

  void _addAlert({
    required String title,
    required String message,
    required DateTime timestamp,
  }) {
    final newAlert = AppAlert(
      id: timestamp.microsecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: timestamp,
    );

    alerts.value = [newAlert, ...alerts.value];
  }

  void removeAlert(String id) {
    alerts.value = alerts.value.where((a) => a.id != id).toList();
  }

  void clearAll() {
    alerts.value = [];
  }
}