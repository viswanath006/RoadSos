import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';
import '../domain/models/crash_settings.dart';

class AccelerometerSample {
  final DateTime timestamp;
  final double x;
  final double y;
  final double z;
  final double magnitude; // in m/s²

  AccelerometerSample({
    required this.timestamp,
    required this.x,
    required this.y,
    required this.z,
  }) : magnitude = math.sqrt(x * x + y * y + z * z);
}

class GyroscopeSample {
  final DateTime timestamp;
  final double x;
  final double y;
  final double z;
  final double magnitude; // in rad/s

  GyroscopeSample({
    required this.timestamp,
    required this.x,
    required this.y,
    required this.z,
  }) : magnitude = math.sqrt(x * x + y * y + z * z);
}

class CrashDetectionEngine {
  CrashDetectionEngine();

  StreamSubscription<UserAccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  Stream<UserAccelerometerEvent>? _accelStreamOverride;
  Stream<GyroscopeEvent>? _gyroStreamOverride;

  final List<AccelerometerSample> _accelBuffer = [];
  final List<GyroscopeSample> _gyroBuffer = [];

  // 1.5 seconds sliding window
  static const Duration _windowDuration = Duration(milliseconds: 1500);
  
  // Cool-down to prevent multiple triggers (e.g. 10 seconds)
  DateTime? _lastTriggerTime;
  static const Duration _cooldownDuration = Duration(seconds: 10);

  bool _running = false;
  bool get isRunning => _running;

  CrashSettings? _settings;
  void Function(double peakAcc, double speedChg, double peakGyro)? _onCrashDetected;

  void start({
    required CrashSettings settings,
    required void Function(double peakAcc, double speedChg, double peakGyro) onCrashDetected,
    Stream<UserAccelerometerEvent>? accelStream,
    Stream<GyroscopeEvent>? gyroStream,
  }) {
    if (_running) stop();

    _settings = settings;
    _onCrashDetected = onCrashDetected;
    _accelStreamOverride = accelStream;
    _gyroStreamOverride = gyroStream;
    _running = true;

    _accelBuffer.clear();
    _gyroBuffer.clear();

    // Listen to user accelerometer (excludes gravity)
    _accelSubscription = (accelStream ?? userAccelerometerEvents).listen(
      _handleAccelerometerEvent,
      onError: (e) {
        // Handle stream error silently or log
      },
    );

    // Listen to gyroscope (rotation)
    _gyroSubscription = (gyroStream ?? gyroscopeEvents).listen(
      _handleGyroscopeEvent,
      onError: (e) {
        // Handle stream error silently or log
      },
    );
  }

  void stop() {
    _accelSubscription?.cancel();
    _accelSubscription = null;
    _gyroSubscription?.cancel();
    _gyroSubscription = null;
    _accelStreamOverride = null;
    _gyroStreamOverride = null;
    _running = false;
    _accelBuffer.clear();
    _gyroBuffer.clear();
  }

  void updateSettings(CrashSettings settings) {
    if (_running && _onCrashDetected != null) {
      start(
        settings: settings,
        onCrashDetected: _onCrashDetected!,
        accelStream: _accelStreamOverride,
        gyroStream: _gyroStreamOverride,
      );
    } else {
      _settings = settings;
    }
  }

  void _handleAccelerometerEvent(UserAccelerometerEvent event) {
    if (!_running || _settings == null) return;

    final now = DateTime.now();
    
    // Apply low-pass filter / moving average over the last 3 samples to smooth noise
    double x = event.x;
    double y = event.y;
    double z = event.z;

    if (_accelBuffer.isNotEmpty) {
      final prev = _accelBuffer.last;
      // 30% new value, 70% previous value (simple low-pass filter to reduce vibration noise)
      x = prev.x * 0.7 + x * 0.3;
      y = prev.y * 0.7 + y * 0.3;
      z = prev.z * 0.7 + z * 0.3;
    }

    final sample = AccelerometerSample(
      timestamp: now,
      x: x,
      y: y,
      z: z,
    );

    _accelBuffer.add(sample);
    _pruneAccelBuffer(now);

    _evaluateBuffer();
  }

  void _handleGyroscopeEvent(GyroscopeEvent event) {
    if (!_running) return;

    final now = DateTime.now();
    double x = event.x;
    double y = event.y;
    double z = event.z;

    if (_gyroBuffer.isNotEmpty) {
      final prev = _gyroBuffer.last;
      x = prev.x * 0.7 + x * 0.3;
      y = prev.y * 0.7 + y * 0.3;
      z = prev.z * 0.7 + z * 0.3;
    }

    final sample = GyroscopeSample(
      timestamp: now,
      x: x,
      y: y,
      z: z,
    );

    _gyroBuffer.add(sample);
    _pruneGyroBuffer(now);
  }

  void _pruneAccelBuffer(DateTime now) {
    _accelBuffer.removeWhere(
      (s) => now.difference(s.timestamp) > _windowDuration,
    );
  }

  void _pruneGyroBuffer(DateTime now) {
    _gyroBuffer.removeWhere(
      (s) => now.difference(s.timestamp) > _windowDuration,
    );
  }

  void _evaluateBuffer() {
    if (_accelBuffer.isEmpty || _settings == null) return;

    // Check cooldown
    final now = DateTime.now();
    if (_lastTriggerTime != null && now.difference(_lastTriggerTime!) < _cooldownDuration) {
      return;
    }

    // Find the maximum acceleration magnitude (peak) in our buffer
    AccelerometerSample? peakSample;
    int peakIndex = -1;
    for (int i = 0; i < _accelBuffer.length; i++) {
      final s = _accelBuffer[i];
      if (peakSample == null || s.magnitude > peakSample.magnitude) {
        peakSample = s;
        peakIndex = i;
      }
    }

    if (peakSample == null) return;

    // Convert magnitude from m/s² to Gs (1 G ≈ 9.80665 m/s²)
    final peakG = peakSample.magnitude / 9.80665;

    // If peak force is below impact threshold, we do not trigger
    if (peakG < _settings!.impactThreshold) {
      return;
    }

    // Peak force detected! Now calculate estimated speed change (delta V) in a 300ms window around peak
    // (150ms before, 150ms after the peak)
    final peakTime = peakSample.timestamp;
    final integrationStart = peakTime.subtract(const Duration(milliseconds: 150));
    final integrationEnd = peakTime.add(const Duration(milliseconds: 150));

    double speedChange = 0.0;
    AccelerometerSample? lastSampleInWindow;

    for (final s in _accelBuffer) {
      if (s.timestamp.isBefore(integrationStart) || s.timestamp.isAfter(integrationEnd)) {
        continue;
      }

      if (lastSampleInWindow != null) {
        final dt = s.timestamp.difference(lastSampleInWindow.timestamp).inMicroseconds / 1000000.0;
        // Integrate acceleration to get delta V (velocity change)
        speedChange += s.magnitude * dt;
      }
      lastSampleInWindow = s;
    }

    // Gyroscope check: find the maximum rotation rate in the same window (or within the 1.5s buffer)
    double peakGyro = 0.0;
    for (final s in _gyroBuffer) {
      if (s.magnitude > peakGyro) {
        peakGyro = s.magnitude;
      }
    }

    // Condition: Impact > threshold AND Speed Change > threshold AND Rotation > threshold
    if (speedChange >= _settings!.speedChangeThreshold && peakGyro >= _settings!.rotationThreshold) {
      // Trigger crash event!
      _lastTriggerTime = now;
      _onCrashDetected?.call(peakG, speedChange, peakGyro);
    }
  }
}
