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
  DateTime? _lastSpeedTime;

  // Constants
  static const double gForceThreshold = 3.0 * 9.81; // 3G in m/s^2 
  static const double speedDropThresholdKmph = 25.0; // kmph
  static const int triggerWindowSeconds = 3; 

  void startMonitoring() {
    // Monitor Accelerometer (User G-Forces excluding gravity)
    _accelerometerSubscription = userAccelerometerEventStream().listen((event) {
      double gForce = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));
      
      if (gForce > gForceThreshold) {
        _lastGForceSpikeTime = DateTime.now();
        _checkTriggers();
      }
    });

    // Monitor Speed via GPS
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 10),
    ).listen((Position position) {
      double currentSpeedKmph = position.speed * 3.6; // convert m/s to km/h
      
      if (_lastSpeedTime != null) {
        double speedDrop = _lastSpeedKmph - currentSpeedKmph;
        if (speedDrop > speedDropThresholdKmph) {
          // If speed drops significantly, evaluate
          _checkTriggers();
        }
      }

      _lastSpeedKmph = currentSpeedKmph;
      _lastSpeedTime = DateTime.now();
    });
  }

  void _checkTriggers() {
    if (_lastGForceSpikeTime != null && _lastSpeedTime != null) {
      final difference = _lastSpeedTime!.difference(_lastGForceSpikeTime!).inSeconds.abs();
      if (difference <= triggerWindowSeconds && !_isAccidentDetected) {
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
    notifyListeners();
  }

  void stopMonitoring() {
    _accelerometerSubscription?.cancel();
    _positionSubscription?.cancel();
  }
}
