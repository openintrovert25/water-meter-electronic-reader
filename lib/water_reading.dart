/// Represents a single water meter reading captured by the ESP32-CAM
/// using the TCRT5000 IR optical sensor to detect dial/digit rotation.
class WaterReading {
  final DateTime timestamp;
  final double liters;       // Cumulative reading in liters (from optical pulse count)
  final double flowRate;     // Calculated flow rate in L/min (derived from delta liters / delta time)
  final double costPhp;      // Estimated cost in Philippine Peso
  final String? imageUrl;    // Optional: URL of the captured meter image (from ESP32-CAM)

  const WaterReading({
    required this.timestamp,
    required this.liters,
    required this.flowRate,
    required this.costPhp,
    this.imageUrl,
  });

  /// Creates a WaterReading from the JSON payload sent by the ESP32-CAM via HTTP POST.
  ///
  /// ESP32-CAM sends:
  ///   { "timestamp": "...", "liters": 123.4, "flow_rate": 1.2,
  ///     "cost_php": 0.50, "image_url": "http://..." (optional) }
  factory WaterReading.fromJson(Map<String, dynamic> json) {
    return WaterReading(
      timestamp: DateTime.parse(json['timestamp'] as String),
      liters: (json['liters'] as num).toDouble(),
      flowRate: (json['flow_rate'] as num).toDouble(),
      costPhp: (json['cost_php'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'liters': liters,
    'flow_rate': flowRate,
    'cost_php': costPhp,
    if (imageUrl != null) 'image_url': imageUrl,
  };

  /// Consumption in liters for a specific period
  static double periodConsumption(List<WaterReading> readings) {
    if (readings.length < 2) return 0;
    return readings.last.liters - readings.first.liters;
  }
}

/// Aggregated usage for a day/week/month view
class UsageSummary {
  final DateTime date;
  final double totalLiters;
  final double totalCostPhp;

  const UsageSummary({
    required this.date,
    required this.totalLiters,
    required this.totalCostPhp,
  });
}

enum AlertType { leak, highUsage, offline, normal }

class WaterAlert {
  final String id;
  final AlertType type;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  const WaterAlert({
    required this.id,
    required this.type,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  WaterAlert copyWith({bool? isRead}) {
    return WaterAlert(
      id: id,
      type: type,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}