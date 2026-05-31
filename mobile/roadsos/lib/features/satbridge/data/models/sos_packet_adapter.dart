import 'package:hive/hive.dart';
import '../../domain/sos_packet.dart';

class SosPacketAdapter extends TypeAdapter<SosPacket> {
  @override
  final int typeId = 7;

  @override
  SosPacket read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SosPacket(
      uid: fields[0] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(fields[1] as int),
      latitude: fields[2] as double,
      longitude: fields[3] as double,
      persons: fields[4] as int,
      severity: fields[5] as String,
      injured: fields[6] as int,
      children: fields[7] as int,
      elderly: fields[8] as int,
      hasFood: fields[9] as bool,
      hasWater: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SosPacket obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.timestamp.millisecondsSinceEpoch)
      ..writeByte(2)
      ..write(obj.latitude)
      ..writeByte(3)
      ..write(obj.longitude)
      ..writeByte(4)
      ..write(obj.persons)
      ..writeByte(5)
      ..write(obj.severity)
      ..writeByte(6)
      ..write(obj.injured)
      ..writeByte(7)
      ..write(obj.children)
      ..writeByte(8)
      ..write(obj.elderly)
      ..writeByte(9)
      ..write(obj.hasFood)
      ..writeByte(10)
      ..write(obj.hasWater);
  }
}
