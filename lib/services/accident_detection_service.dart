import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class AccidentDetectionService extends ChangeNotifier {
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<Position>? _positionSubscription;

  bool _isAccidentDetected = false;
  bool get isAccidentDetected => _isAccidentDetected;

  // The timestamp when a high G-force was detected
  DateTime? _lastGForceSpikeTime;

  // To track speed drops
  double _lastSpeedKmph = 0.0;
  DateTime? _lastSpeedDropTime;

  // Constants
  static const double gForceThreshold = 3.0 * 9.81; // 3G in m/s^2
  static const double highSpeedThresholdKmph = 30.0; // must have been above this
  static const double lowSpeedThresholdKmph = 5.0; // must drop to near this
  static const int triggerWindowSeconds = 3;

  void startMonitoring() {
    // Avoid duplicate subscriptions
    _accelerometerSubscription?.cancel();
    _positionSubscription?.cancel();

    // Monitor Accelerometer (User G-Forces excluding gravity)
    try {
      _accelerometerSubscription =
          userAccelerometerEventStream().listen((event) {
        double gForce =
            sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));

        if (gForce > gForceThreshold) {
          _lastGForceSpikeTime = DateTime.now();
          debugPrint(
              '[AccidentDetection] G-force spike detected: ${(gForce / 9.81).toStringAsFixed(1)}G');
          _checkTriggers();
        }
      });
    } catch (e) {
      debugPrint('[AccidentDetection] Accelerometer not available: $e');
    }

    // Monitor Speed via GPS
    try {
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best, distanceFilter: 10),
      ).listen((Position position) {
        double currentSpeedKmph =
            position.speed * 3.6; // convert m/s to km/h

        // Check for sudden speed drop: was going >30 km/h, now near 0
        if (_lastSpeedKmph > highSpeedThresholdKmph &&
            currentSpeedKmph < lowSpeedThresholdKmph) {
          _lastSpeedDropTime = DateTime.now();
          debugPrint(
              '[AccidentDetection] Speed drop detected: ${_lastSpeedKmph.toStringAsFixed(0)} → ${currentSpeedKmph.toStringAsFixed(0)} km/h');
          _checkTriggers();
        }

        _lastSpeedKmph = currentSpeedKmph;
      });
    } catch (e) {
      debugPrint('[AccidentDetection] GPS stream not available: $e');
    }
  }

  void _checkTriggers() {
    if (_lastGForceSpikeTime != null && _lastSpeedDropTime != null) {
      final difference =
          _lastSpeedDropTime!.difference(_lastGForceSpikeTime!).inSeconds.abs();
      if (difference <= triggerWindowSeconds && !_isAccidentDetected) {
        debugPrint(
            '[AccidentDetection] ACCIDENT DETECTED! Both triggers within $difference seconds.');
        _triggerAccidentDetected();
      }
    }
  }

  void _triggerAccidentDetected() {
    _isAccidentDetected = true;
    notifyListeners();
  }

  void resetDetection() {
    _isAccidentDetected = false;
    _lastGForceSpikeTime = null;
    _lastSpeedDropTime = null;
    notifyListeners();
  }

  void stopMonitoring() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
