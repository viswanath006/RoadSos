import 'package:hive/hive.dart';
import '../../domain/models/first_aid_guide.dart';

class FirstAidGuideAdapter extends TypeAdapter<FirstAidGuide> {
  @override
  final int typeId = 3;

  @override
  FirstAidGuide read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FirstAidGuide(
      id: fields[0] as String,
      title: fields[1] as String,
      category: fields[2] as String,
      steps: (fields[3] as List).cast<String>(),
      disclaimer: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FirstAidGuide obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.steps)
      ..writeByte(4)
      ..write(obj.disclaimer);
  }
}
