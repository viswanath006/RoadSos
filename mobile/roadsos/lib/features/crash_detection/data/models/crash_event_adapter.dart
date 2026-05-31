import 'package:hive/hive.dart';
import '../../domain/models/crash_event.dart';

class CrashEventAdapter extends TypeAdapter<CrashEvent> {
  @override
  final int typeId = 5;

  @override
  CrashEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CrashEvent(
      id: fields[0] as String,
      timestamp: DateTime.parse(fields[1] as String),
      peakAcceleration: fields[2] as double,
      speedChange: fields[3] as double,
      peakGyroscope: fields[4] as double,
      latitude: fields[5] as double?,
      longitude: fields[6] as double?,
      userResponse: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CrashEvent obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp.toIso8601String())
      ..writeByte(2)
      ..write(obj.peakAcceleration)
      ..writeByte(3)
      ..write(obj.speedChange)
      ..writeByte(4)
      ..write(obj.peakGyroscope)
      ..writeByte(5)
      ..write(obj.latitude)
      ..writeByte(6)
      ..write(obj.longitude)
      ..writeByte(7)
      ..write(obj.userResponse);
  }
}
