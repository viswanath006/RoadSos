import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../domain/models/crash_settings.dart';
import '../../domain/models/crash_event.dart';
import '../../application/crash_detection_engine.dart';
import '../../../sos/application/sos_provider.dart';
import '../../../sos/application/sos_alert_service.dart';

// Settings provider
final crashSettingsProvider = StateNotifierProvider<CrashSettingsNotifier, CrashSettings>((ref) {
  return CrashSettingsNotifier();
});

class CrashSettingsNotifier extends StateNotifier<CrashSettings> {
  CrashSettingsNotifier() : super(CrashSettings.defaultSettings()) {
    _loadSettings();
  }

  late final Box<CrashSettings> _box;

  void _loadSettings() {
    _box = Hive.box<CrashSettings>('crash_settings_box');
    final saved = _box.get('settings');
    if (saved != null) {
      state = saved;
    } else {
      _box.put('settings', state);
    }
  }

  Future<void> updateSettings(CrashSettings settings) async {
    state = settings;
    await _box.put('settings', settings);
  }

  Future<void> toggleEnabled(bool enabled) async {
    final updated = state.copyWith(enabled: enabled);
    await updateSettings(updated);
  }

  Future<void> setSensitivity(CrashSensitivity sensitivity) async {
    double impact = state.impactThreshold;
    double speed = state.speedChangeThreshold;
    double rotation = state.rotationThreshold;

    switch (sensitivity) {
      case CrashSensitivity.low:
        impact = 6.0;
        speed = 12.0;
        rotation = 5.0;
        break;
      case CrashSensitivity.medium:
        impact = 4.5;
        speed = 8.0;
        rotation = 3.5;
        break;
      case CrashSensitivity.high:
        impact = 3.0;
        speed = 5.0;
        rotation = 2.0;
        break;
      case CrashSensitivity.custom:
        // User custom values, do not override
        break;
    }

    final updated = state.copyWith(
      sensitivity: sensitivity,
      impactThreshold: impact,
      speedChangeThreshold: speed,
      rotationThreshold: rotation,
    );
    await updateSettings(updated);
  }

  Future<void> setCustomThresholds({
    required double impact,
    required double speed,
    required double rotation,
  }) async {
    final updated = state.copyWith(
      sensitivity: CrashSensitivity.custom,
      impactThreshold: impact,
      speedChangeThreshold: speed,
      rotationThreshold: rotation,
    );
    await updateSettings(updated);
  }

  Future<void> setCountdownDuration(int duration) async {
    final updated = state.copyWith(countdownDuration: duration);
    await updateSettings(updated);
  }
}

// Crash events log provider
final crashEventLogProvider = StateNotifierProvider<CrashEventLogNotifier, List<CrashEvent>>((ref) {
  return CrashEventLogNotifier();
});

class CrashEventLogNotifier extends StateNotifier<List<CrashEvent>> {
  CrashEventLogNotifier() : super([]) {
    _loadEvents();
  }

  late final Box<CrashEvent> _box;

  void _loadEvents() {
    _box = Hive.box<CrashEvent>('crash_events_box');
    state = _box.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> logEvent(CrashEvent event) async {
    await _box.put(event.id, event);
    _loadEvents();
  }

  Future<void> clearHistory() async {
    await _box.clear();
    state = [];
  }
}

// Active crash detection state provider
enum CrashDetectionStatus {
  idle,
  monitoring,
  alerting,
  sendingSos,
  sosSent,
  error
}

class CrashDetectionState {
  final CrashDetectionStatus status;
  final int countdownSecondsLeft;
  final double? peakAcc;
  final double? speedChg;
  final double? peakGyro;
  final String? errorMessage;

  CrashDetectionState({
    required this.status,
    required this.countdownSecondsLeft,
    this.peakAcc,
    this.speedChg,
    this.peakGyro,
    this.errorMessage,
  });

  factory CrashDetectionState.idle() => CrashDetectionState(
        status: CrashDetectionStatus.idle,
        countdownSecondsLeft: 0,
      );

  CrashDetectionState copyWith({
    CrashDetectionStatus? status,
    int? countdownSecondsLeft,
    double? peakAcc,
    double? speedChg,
    double? peakGyro,
    String? errorMessage,
  }) {
    return CrashDetectionState(
      status: status ?? this.status,
      countdownSecondsLeft: countdownSecondsLeft ?? this.countdownSecondsLeft,
      peakAcc: peakAcc ?? this.peakAcc,
      speedChg: speedChg ?? this.speedChg,
      peakGyro: peakGyro ?? this.peakGyro,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final crashDetectionProvider = StateNotifierProvider<CrashDetectionNotifier, CrashDetectionState>((ref) {
  return CrashDetectionNotifier(ref);
});

class CrashDetectionNotifier extends StateNotifier<CrashDetectionState> {
  CrashDetectionNotifier(this._ref) : super(CrashDetectionState.idle()) {
    // Watch settings to start/stop engine
    _ref.listen<CrashSettings>(crashSettingsProvider, (previous, next) {
      _onSettingsChanged(next);
    });

    // Initialize engine with initial settings
    final initialSettings = _ref.read(crashSettingsProvider);
    _onSettingsChanged(initialSettings);
  }

  final Ref _ref;
  final CrashDetectionEngine _engine = CrashDetectionEngine();
  Timer? _countdownTimer;

  void _onSettingsChanged(CrashSettings settings) {
    if (settings.enabled) {
      if (!_engine.isRunning) {
        state = state.copyWith(status: CrashDetectionStatus.monitoring);
        _engine.start(
          settings: settings,
          onCrashDetected: _onCrashDetected,
        );
      } else {
        _engine.updateSettings(settings);
      }
    } else {
      if (_engine.isRunning) {
        _engine.stop();
      }
      if (state.status == CrashDetectionStatus.monitoring || state.status == CrashDetectionStatus.idle) {
        state = CrashDetectionState.idle();
      }
    }
  }

  void _onCrashDetected(double peakAcc, double speedChg, double peakGyro) {
    // Prevent double triggers
    if (state.status == CrashDetectionStatus.alerting ||
        state.status == CrashDetectionStatus.sendingSos ||
        state.status == CrashDetectionStatus.sosSent) {
      return;
    }

    final settings = _ref.read(crashSettingsProvider);
    state = CrashDetectionState(
      status: CrashDetectionStatus.alerting,
      countdownSecondsLeft: settings.countdownDuration,
      peakAcc: peakAcc,
      speedChg: speedChg,
      peakGyro: peakGyro,
    );

    // Start countdown timer
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.countdownSecondsLeft <= 1) {
        timer.cancel();
        triggerAutoSos();
      } else {
        state = state.copyWith(
          countdownSecondsLeft: state.countdownSecondsLeft - 1,
        );
      }
    });
  }

  void cancelAlert() {
    _countdownTimer?.cancel();
    _countdownTimer = null;

    _logCrashEvent(response: 'safe');

    final settings = _ref.read(crashSettingsProvider);
    state = CrashDetectionState(
      status: settings.enabled
          ? CrashDetectionStatus.monitoring
          : CrashDetectionStatus.idle,
      countdownSecondsLeft: 0,
    );
  }

  Future<void> triggerAutoSos() async {
    _countdownTimer?.cancel();
    _countdownTimer = null;

    state = state.copyWith(status: CrashDetectionStatus.sendingSos);

    try {
      final locationService = _ref.read(locationServiceProvider);
      final location = await locationService.getCurrentLocation();

      // Trigger existing SOS broadcast
      await _ref.read(sosAlertProvider.notifier).sendSosAlert(
            latitude: location.latitude,
            longitude: location.longitude,
          );

      _logCrashEvent(
        response: 'no_response',
        lat: location.latitude,
        lng: location.longitude,
      );

      state = state.copyWith(status: CrashDetectionStatus.sosSent);
    } catch (e) {
      _logCrashEvent(response: 'no_response');
      state = state.copyWith(
        status: CrashDetectionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> triggerImmediateHelp() async {
    _countdownTimer?.cancel();
    _countdownTimer = null;

    state = state.copyWith(status: CrashDetectionStatus.sendingSos);

    try {
      final locationService = _ref.read(locationServiceProvider);
      final location = await locationService.getCurrentLocation();

      await _ref.read(sosAlertProvider.notifier).sendSosAlert(
            latitude: location.latitude,
            longitude: location.longitude,
          );

      _logCrashEvent(
        response: 'help_needed',
        lat: location.latitude,
        lng: location.longitude,
      );

      state = state.copyWith(status: CrashDetectionStatus.sosSent);
    } catch (e) {
      _logCrashEvent(response: 'help_needed');
      state = state.copyWith(
        status: CrashDetectionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void resetToMonitoring() {
    final settings = _ref.read(crashSettingsProvider);
    state = CrashDetectionState(
      status: settings.enabled
          ? CrashDetectionStatus.monitoring
          : CrashDetectionStatus.idle,
      countdownSecondsLeft: 0,
    );
  }



  void _logCrashEvent({required String response, double? lat, double? lng}) {
    final event = CrashEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      peakAcceleration: state.peakAcc ?? 0.0,
      speedChange: state.speedChg ?? 0.0,
      peakGyroscope: state.peakGyro ?? 0.0,
      latitude: lat,
      longitude: lng,
      userResponse: response,
    );
    _ref.read(crashEventLogProvider.notifier).logEvent(event);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _engine.stop();
    super.dispose();
  }
}
