import 'package:hive/hive.dart';
import '../../domain/models/user_profile.dart';

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 6;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      bloodGroup: fields[0] as String? ?? '',
      allergies: fields[1] as String? ?? '',
      conditions: fields[2] as String? ?? '',
      notes: fields[3] as String? ?? '',
      primaryContactName: fields[4] as String? ?? '',
      primaryContactPhone: fields[5] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.bloodGroup)
      ..writeByte(1)
      ..write(obj.allergies)
      ..writeByte(2)
      ..write(obj.conditions)
      ..writeByte(3)
      ..write(obj.notes)
      ..writeByte(4)
      ..write(obj.primaryContactName)
      ..writeByte(5)
      ..write(obj.primaryContactPhone);
  }
}
