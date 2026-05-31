import '../models/incident.dart';

abstract class IncidentsRepository {
  List<Incident> getIncidents();
  Future<void> addIncident(Incident incident);
  Future<void> clearHistory();
}
