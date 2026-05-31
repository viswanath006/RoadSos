import 'package:hive/hive.dart';
import '../../domain/models/crash_settings.dart';

class CrashSettingsAdapter extends TypeAdapter<CrashSettings> {
  @override
  final int typeId = 4;

  @override
  CrashSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CrashSettings(
      enabled: fields[0] as bool,
      sensitivity: CrashSensitivity.values[fields[1] as int],
      impactThreshold: fields[2] as double,
      speedChangeThreshold: fields[3] as double,
      rotationThreshold: fields[4] as double,
      countdownDuration: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CrashSettings obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.enabled)
      ..writeByte(1)
      ..write(obj.sensitivity.index)
      ..writeByte(2)
      ..write(obj.impactThreshold)
      ..writeByte(3)
      ..write(obj.speedChangeThreshold)
      ..writeByte(4)
      ..write(obj.rotationThreshold)
      ..writeByte(5)
      ..write(obj.countdownDuration);
  }
}
