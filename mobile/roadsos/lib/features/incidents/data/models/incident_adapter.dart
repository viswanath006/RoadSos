import 'package:hive/hive.dart';
import '../../domain/models/incident.dart';

class IncidentAdapter extends TypeAdapter<Incident> {
  @override
  final int typeId = 1;

  @override
  Incident read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Incident(
      id: fields[0] as String,
      timestamp: DateTime.parse(fields[1] as String),
      latitude: fields[2] as double,
      longitude: fields[3] as double,
      alertSent: fields[4] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Incident obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp.toIso8601String())
      ..writeByte(2)
      ..write(obj.latitude)
      ..writeByte(3)
      ..write(obj.longitude)
      ..writeByte(4)
      ..write(obj.alertSent);
  }
}
