import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'water_reading.dart';

/// IoT Service with Firebase Firestore backend.
///
/// Hardware:
///   - ESP32-CAM module (AI-Thinker)
///   - TCRT5000 IR Optical sensor — detects reflective pulses from the water
///     meter's dial/low-flow indicator (1 pulse = configurable liters,
///     typically 1 pulse = 0.001 m³ = 1 liter on most Philippine residential
///     meters; adjust [litersPerPulse] in Settings).
///
/// How it works:
///   1. TCRT5000 emits IR light toward the spinning dial/reflector on the meter.
///   2. Each time the reflective marker passes, the sensor outputs a HIGH pulse.
///   3. ESP32 counts pulses → converts to liters → POSTs to Firestore via HTTP.
///   4. ESP32-CAM periodically captures a photo of the meter face and uploads it
///      to Firebase Storage; the download URL is stored alongside the reading.
///
/// Firestore structure:
///   users/{uid}/readings/{auto-id} →
///     { timestamp, liters, flowRate, costPhp, imageUrl? }
///   users/{uid}/alerts/{auto-id}   →
///     { type, message, timestamp, isRead }
///
/// To disable simulation and use real ESP32-CAM data, remove _startSimulation()
/// from initialize() — Firestore listeners will handle all real-time updates.
class IotService {
  static final IotService _instance = IotService._internal();
  factory IotService() => _instance;
  IotService._internal();

  // --- Sensor constants ---
  /// TCRT5000: each IR pulse = 1 liter (0.001 m³) by default.
  /// Adjust via Settings if your meter has a different resolution.
  static const double litersPerPulse = 1.0;

  /// MWSS Tier 1 rate: ₱16.08 per cubic meter = ₱0.01608 per liter.
  static const double phpPerLiter = 16.08 / 1000.0;

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final _readings = <WaterReading>[];
  final _alerts = <WaterAlert>[];
  double _totalLiters = 0;
  bool _isConnected = false;

  final _readingController = StreamController<WaterReading>.broadcast();
  final _alertController = StreamController<WaterAlert>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  StreamSubscription<QuerySnapshot>? _readingsSub;
  StreamSubscription<QuerySnapshot>? _alertsSub;
  Timer? _simulationTimer;

  Stream<WaterReading> get readingStream => _readingController.stream;
  Stream<WaterAlert> get alertStream => _alertController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected;
  double get totalLiters => _totalLiters;
  double get totalCostPhp => _totalLiters * phpPerLiter;
  double get currentFlowRate =>
      _readings.isEmpty ? 0 : _readings.last.flowRate;

  List<WaterReading> get readings => List.unmodifiable(_readings);
  List<WaterAlert> get alerts => List.unmodifiable(_alerts);

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference get _readingsCol =>
      _db.collection('users').doc(_uid).collection('readings');

  CollectionReference get _alertsCol =>
      _db.collection('users').doc(_uid).collection('alerts');

  Future<void> initialize() async {
    if (_uid == null) return;
    _listenToReadings();
    _listenToAlerts();
    _isConnected = true;
    _connectionController.add(true);
    // ↓ Remove this line once your ESP32-CAM is posting real data
    _startSimulation();
  }

  // ---------------------------------------------------------------------------
  // Real-time Firestore listeners
  // ---------------------------------------------------------------------------

  void _listenToReadings() {
    _readingsSub = _readingsCol
        .orderBy('timestamp', descending: false)
        .limitToLast(200)
        .snapshots()
        .listen((snapshot) {
      _readings.clear();
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        _readings.add(WaterReading(
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          liters: (data['liters'] as num).toDouble(),
          flowRate: (data['flowRate'] as num).toDouble(),
          costPhp: (data['costPhp'] as num).toDouble(),
          imageUrl: data['imageUrl'] as String?,
        ));
      }
      if (_readings.isNotEmpty) {
        _totalLiters = _readings.last.liters;
        _readingController.add(_readings.last);
      }
    }, onError: (e) {
      _isConnected = false;
      _connectionController.add(false);
    });
  }

  void _listenToAlerts() {
    _alertsSub = _alertsCol
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      _alerts.clear();
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        _alerts.add(WaterAlert(
          id: doc.id,
          type: AlertType.values.byName(data['type'] as String),
          message: data['message'] as String,
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          isRead: data['isRead'] as bool? ?? false,
        ));
      }
      if (_alerts.isNotEmpty) _alertController.add(_alerts.first);
    });
  }

  // ---------------------------------------------------------------------------
  // Write reading to Firestore
  // The ESP32-CAM POSTs to a Firebase Cloud Function (or directly via REST API)
  // which then calls Firestore. The Flutter app listens via snapshots above.
  // ---------------------------------------------------------------------------
  Future<void> saveReading(WaterReading reading) async {
    if (_uid == null) return;
    try {
      await _readingsCol.add({
        'timestamp': Timestamp.fromDate(reading.timestamp),
        'liters': reading.liters,
        'flowRate': reading.flowRate,
        'costPhp': reading.costPhp,
        if (reading.imageUrl != null) 'imageUrl': reading.imageUrl,
      });
      await _checkForAlerts(reading);
    } catch (e) {
      // Silently fail — simulation continues even if Firestore is unreachable
    }
  }

  // ---------------------------------------------------------------------------
  // Alert detection
  // ---------------------------------------------------------------------------
  Future<void> _checkForAlerts(WaterReading reading) async {
    // High usage: flow rate > 10 L/min
    if (reading.flowRate > 10.0) {
      await _saveAlert(WaterAlert(
        id: '',
        type: AlertType.highUsage,
        message:
            'High flow rate detected: ${reading.flowRate.toStringAsFixed(1)} L/min',
        timestamp: DateTime.now(),
      ));
    }
    // Possible leak: very low but non-zero continuous flow
    // TCRT5000 sensitivity: even a slow drip (>0.02 L/min) is detectable
    if (reading.flowRate > 0.02 && reading.flowRate < 0.5) {
      await _saveAlert(WaterAlert(
        id: '',
        type: AlertType.leak,
        message:
            'Possible leak: ${reading.flowRate.toStringAsFixed(3)} L/min continuous flow detected',
        timestamp: DateTime.now(),
      ));
    }
  }

  Future<void> _saveAlert(WaterAlert alert) async {
    if (_uid == null) return;
    await _alertsCol.add({
      'type': alert.type.name,
      'message': alert.message,
      'timestamp': Timestamp.fromDate(alert.timestamp),
      'isRead': false,
    });
  }

  Future<void> markAlertRead(String id) async {
    if (_uid == null) return;
    await _alertsCol.doc(id).update({'isRead': true});
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------
  List<WaterReading> getReadingsForPeriod(Duration period) {
    final cutoff = DateTime.now().subtract(period);
    return _readings.where((r) => r.timestamp.isAfter(cutoff)).toList();
  }

  List<UsageSummary> getDailySummaries(int days) {
    final summaries = <UsageSummary>[];
    final now = DateTime.now();
    for (int i = days - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final dayReadings = _readings
          .where((r) =>
              r.timestamp.year == day.year &&
              r.timestamp.month == day.month &&
              r.timestamp.day == day.day)
          .toList();
      final liters = dayReadings.isEmpty
          ? 0.0
          : WaterReading.periodConsumption(dayReadings);
      summaries.add(UsageSummary(
        date: day,
        totalLiters: liters,
        totalCostPhp: liters * phpPerLiter,
      ));
    }
    return summaries;
  }

  // ---------------------------------------------------------------------------
  // Simulation — REMOVE _startSimulation() call once ESP32-CAM is live
  //
  // Simulates TCRT5000 IR pulses:
  //   - Each tick = 3 seconds (matches typical ESP32 POST interval)
  //   - Random flow between 0–3 L/min (residential average ~1–2 L/min active)
  //   - litersPerPulse = 1.0 L → delta liters = flowRate/60 * interval_seconds
  // ---------------------------------------------------------------------------
  void _startSimulation() {
    final rng = Random();
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      // Simulate realistic TCRT5000 pulse-derived flow (0 to 3 L/min)
      final flowRate = rng.nextDouble() * 3.0;
      // liters accumulated in this 3-second window
      final litersDelta = (flowRate / 60.0) * 3.0;
      _totalLiters += litersDelta;

      await saveReading(WaterReading(
        timestamp: DateTime.now(),
        liters: _totalLiters,
        flowRate: flowRate,
        costPhp: _totalLiters * phpPerLiter,
        // imageUrl is null in simulation; real ESP32-CAM will provide this
      ));
    });
  }

  void dispose() {
    _simulationTimer?.cancel();
    _readingsSub?.cancel();
    _alertsSub?.cancel();
    _readingController.close();
    _alertController.close();
    _connectionController.close();
  }
}