import 'package:hive/hive.dart';

import '../../../services/domain/emergency_service.dart';
import '../../../services/domain/service_type.dart';

class EmergencyServiceAdapter extends TypeAdapter<EmergencyService> {
  @override
  final int typeId = 2;

  @override
  EmergencyService read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    final typeName = fields[2] as String;
    final serviceType = ServiceType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => ServiceType.hospital,
    );

    return EmergencyService(
      id: fields[0] as String,
      name: fields[1] as String,
      type: serviceType,
      latitude: fields[3] as double,
      longitude: fields[4] as double,
      distance: fields[5] as double?,
      phone: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EmergencyService obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type.name)
      ..writeByte(3)
      ..write(obj.latitude)
      ..writeByte(4)
      ..write(obj.longitude)
      ..writeByte(5)
      ..write(obj.distance)
      ..writeByte(6)
      ..write(obj.phone);
  }
}
