import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:roadsos/features/crash_detection/domain/models/crash_settings.dart';
import 'package:roadsos/features/crash_detection/application/crash_detection_engine.dart';

void main() {
  group('CrashDetectionEngine Unit Tests', () {
    late CrashDetectionEngine engine;
    late StreamController<UserAccelerometerEvent> accelController;
    late StreamController<GyroscopeEvent> gyroController;
    late CrashSettings defaultSettings;

    setUp(() {
      engine = CrashDetectionEngine();
      accelController = StreamController<UserAccelerometerEvent>.broadcast();
      gyroController = StreamController<GyroscopeEvent>.broadcast();
      defaultSettings = CrashSettings.defaultSettings(); // Medium Preset: 4.5G force, 8.0 m/s speed change, 3.5 rad/s rotation
    });

    tearDown(() {
      engine.stop();
      accelController.close();
      gyroController.close();
    });

    test('should NOT trigger crash during normal state (static / zero forces)', () async {
      bool triggered = false;
      engine.start(
        settings: defaultSettings,
        accelStream: accelController.stream,
        gyroStream: gyroController.stream,
        onCrashDetected: (peakAcc, speedChg, peakGyro) {
          triggered = true;
        },
      );

      // Send some low movement data
      for (int i = 0; i < 20; i++) {
        accelController.add(UserAccelerometerEvent(0.1, 0.1, 0.1, DateTime.now()));
        gyroController.add(GyroscopeEvent(0.01, 0.01, 0.01, DateTime.now()));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      expect(triggered, isFalse);
    });

    test('should NOT trigger crash from a drop simulation (high impact force, low velocity change)', () async {
      bool triggered = false;
      engine.start(
        settings: defaultSettings,
        accelStream: accelController.stream,
        gyroStream: gyroController.stream,
        onCrashDetected: (peakAcc, speedChg, peakGyro) {
          triggered = true;
        },
      );

      // Simulate a phone drop:
      // 1. Free fall (0 user acceleration) for 300ms
      for (int i = 0; i < 15; i++) {
        accelController.add(UserAccelerometerEvent(0.0, 0.0, 0.0, DateTime.now()));
        gyroController.add(GyroscopeEvent(0.5, 0.5, 0.5, DateTime.now()));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      // 2. High deceleration impact spike (e.g., 6.0 G force) lasting 40ms
      // 6.0 G = 6.0 * 9.80665 ≈ 58.8 m/s²
      accelController.add(UserAccelerometerEvent(0, 0, 58.8, DateTime.now()));
      gyroController.add(GyroscopeEvent(1.0, 1.0, 1.0, DateTime.now()));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      accelController.add(UserAccelerometerEvent(0, 0, 58.8, DateTime.now()));
      gyroController.add(GyroscopeEvent(1.0, 1.0, 1.0, DateTime.now()));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // 3. Resting (0 user acceleration)
      for (int i = 0; i < 15; i++) {
        accelController.add(UserAccelerometerEvent(0, 0, 0, DateTime.now()));
        gyroController.add(GyroscopeEvent(0.1, 0.1, 0.1, DateTime.now()));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      // Total speed change calculation:
      // peak is 58.8 m/s²
      // integration is over ~300ms window (around peak index)
      // two samples of 58.8 * 0.02s dt ≈ 2.35 m/s speed change
      // Since 2.35 m/s < 8.0 m/s threshold, it shouldn't trigger!
      expect(triggered, isFalse);
    });

    test('should trigger crash when high impact force AND speed change AND rotation rate are met', () async {
      bool triggered = false;
      double detectedPeakG = 0.0;
      double detectedSpeedChg = 0.0;

      engine.start(
        settings: defaultSettings,
        accelStream: accelController.stream,
        gyroStream: gyroController.stream,
        onCrashDetected: (peakAcc, speedChg, peakGyro) {
          triggered = true;
          detectedPeakG = peakAcc;
          detectedSpeedChg = speedChg;
        },
      );

      // Simulate a major collision:
      // High deceleration sustained over a slightly longer window (e.g. 160ms of 6.0 G deceleration)
      // 6.0 G = 58.8 m/s²
      // Over 8 samples at 50Hz, speed change is 58.8 * 8 * 0.02 = 9.4 m/s (exceeds 8.0 m/s threshold)
      
      // Gyroscope experiences heavy spin/rotation (e.g., 4.0 rad/s exceeds 3.5 rad/s threshold)
      for (int i = 0; i < 8; i++) {
        accelController.add(UserAccelerometerEvent(0, 0, 58.8, DateTime.now()));
        gyroController.add(GyroscopeEvent(4.0, 2.0, 1.0, DateTime.now()));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      // Send subsequent resting state
      for (int i = 0; i < 10; i++) {
        accelController.add(UserAccelerometerEvent(0.1, 0.1, 0.1, DateTime.now()));
        gyroController.add(GyroscopeEvent(0.1, 0.1, 0.1, DateTime.now()));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      expect(triggered, isTrue);
      expect(detectedPeakG, closeTo(6.0, 0.2));
      expect(detectedSpeedChg, greaterThanOrEqualTo(8.0));
    });

    group('Sensitivity Settings Changes', () {
      test('should trigger with lower thresholds when sensitivity is set to High', () async {
        bool triggered = false;
        
        // High preset thresholds: 3.0 G force, 5.0 m/s speed change, 2.0 rad/s rotation
        final highSensitivitySettings = defaultSettings.copyWith(
          sensitivity: CrashSensitivity.high,
          impactThreshold: 3.0,
          speedChangeThreshold: 5.0,
          rotationThreshold: 2.0,
        );

        engine.start(
          settings: highSensitivitySettings,
          accelStream: accelController.stream,
          gyroStream: gyroController.stream,
          onCrashDetected: (peakAcc, speedChg, peakGyro) {
            triggered = true;
          },
        );

        // Simulate minor impact (e.g., 3.5 G force = 34.3 m/s²)
        // Speed change: 34.3 * 8 * 0.02 = 5.48 m/s (exceeds 5.0 m/s threshold)
        // Rotation: 2.2 rad/s (exceeds 2.0 rad/s threshold)
        for (int i = 0; i < 8; i++) {
          accelController.add(UserAccelerometerEvent(0, 0, 34.3, DateTime.now()));
          gyroController.add(GyroscopeEvent(2.2, 0.0, 0.0, DateTime.now()));
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }

        // Resting
        for (int i = 0; i < 5; i++) {
          accelController.add(UserAccelerometerEvent(0.1, 0.1, 0.1, DateTime.now()));
          gyroController.add(GyroscopeEvent(0.1, 0.1, 0.1, DateTime.now()));
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }

        expect(triggered, isTrue);
      });
    });
  });
}
