enum CrashSensitivity { low, medium, high, custom }

class CrashSettings {
  const CrashSettings({
    required this.enabled,
    required this.sensitivity,
    required this.impactThreshold,
    required this.speedChangeThreshold,
    required this.rotationThreshold,
    required this.countdownDuration,
  });

  final bool enabled;
  final CrashSensitivity sensitivity;
  final double impactThreshold;      // in G-forces (e.g. 4.5 G)
  final double speedChangeThreshold; // in m/s (e.g. 8.0 m/s)
  final double rotationThreshold;    // in rad/s (e.g. 3.5 rad/s)
  final int countdownDuration;       // in seconds (e.g. 15 seconds)

  factory CrashSettings.defaultSettings() {
    return const CrashSettings(
      enabled: false,
      sensitivity: CrashSensitivity.medium,
      impactThreshold: 4.5,
      speedChangeThreshold: 8.0,
      rotationThreshold: 3.5,
      countdownDuration: 15,
    );
  }

  CrashSettings copyWith({
    bool? enabled,
    CrashSensitivity? sensitivity,
    double? impactThreshold,
    double? speedChangeThreshold,
    double? rotationThreshold,
    int? countdownDuration,
  }) {
    return CrashSettings(
      enabled: enabled ?? this.enabled,
      sensitivity: sensitivity ?? this.sensitivity,
      impactThreshold: impactThreshold ?? this.impactThreshold,
      speedChangeThreshold: speedChangeThreshold ?? this.speedChangeThreshold,
      rotationThreshold: rotationThreshold ?? this.rotationThreshold,
      countdownDuration: countdownDuration ?? this.countdownDuration,
    );
  }
}
