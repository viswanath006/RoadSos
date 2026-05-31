import 'package:hive/hive.dart';
import '../../domain/models/incident.dart';
import '../../domain/repositories/incidents_repository.dart';

class IncidentsRepositoryImpl implements IncidentsRepository {
  IncidentsRepositoryImpl({Box<Incident>? box})
      : _box = box ?? Hive.box<Incident>('incidents_box');

  final Box<Incident> _box;

  @override
  List<Incident> getIncidents() {
    final list = _box.values.toList();
    // Sort so most recent incident is at the top
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  @override
  Future<void> addIncident(Incident incident) async {
    await _box.put(incident.id, incident);
  }

  @override
  Future<void> clearHistory() async {
    await _box.clear();
  }
}
