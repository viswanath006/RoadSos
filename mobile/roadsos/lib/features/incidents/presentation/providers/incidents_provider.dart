import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/incident.dart';
import '../../domain/repositories/incidents_repository.dart';
import '../../data/repositories/incidents_repository_impl.dart';

final incidentsRepositoryProvider = Provider<IncidentsRepository>((ref) {
  return IncidentsRepositoryImpl();
});

final incidentsProvider =
    StateNotifierProvider<IncidentsNotifier, List<Incident>>((ref) {
  final repository = ref.watch(incidentsRepositoryProvider);
  return IncidentsNotifier(repository);
});

class IncidentsNotifier extends StateNotifier<List<Incident>> {
  IncidentsNotifier(this._repository) : super([]) {
    loadIncidents();
  }

  final IncidentsRepository _repository;

  void loadIncidents() {
    state = _repository.getIncidents();
  }

  Future<void> logIncident({
    required double latitude,
    required double longitude,
    required bool alertSent,
  }) async {
    final incident = Incident(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      alertSent: alertSent,
    );
    await _repository.addIncident(incident);
    loadIncidents();
  }

  Future<void> clearHistory() async {
    await _repository.clearHistory();
    loadIncidents();
  }
}
