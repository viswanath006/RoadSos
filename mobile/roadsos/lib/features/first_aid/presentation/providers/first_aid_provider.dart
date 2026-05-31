import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasource/first_aid_local_datasource.dart';
import '../../data/repositories/first_aid_repository_impl.dart';
import '../../domain/models/first_aid_guide.dart';
import '../../domain/repositories/first_aid_repository.dart';

final firstAidLocalDataSourceProvider = Provider<FirstAidLocalDataSource>((ref) {
  return FirstAidLocalDataSourceImpl();
});

final firstAidRepositoryProvider = Provider<FirstAidRepository>((ref) {
  final localDataSource = ref.watch(firstAidLocalDataSourceProvider);
  return FirstAidRepositoryImpl(localDataSource: localDataSource);
});

final firstAidSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final firstAidGuidesProvider =
    StateNotifierProvider.autoDispose<FirstAidGuidesNotifier, List<FirstAidGuide>>((ref) {
  final repository = ref.watch(firstAidRepositoryProvider);
  final query = ref.watch(firstAidSearchQueryProvider);
  return FirstAidGuidesNotifier(repository, query);
});

class FirstAidGuidesNotifier extends StateNotifier<List<FirstAidGuide>> {
  FirstAidGuidesNotifier(this._repository, this._query) : super([]) {
    search();
  }

  final FirstAidRepository _repository;
  final String _query;

  void search() {
    state = _repository.searchGuides(_query);
  }
}

final favoritesProvider =
    StateNotifierProvider.autoDispose<FavoritesNotifier, List<String>>((ref) {
  final repository = ref.watch(firstAidRepositoryProvider);
  return FavoritesNotifier(repository);
});

class FavoritesNotifier extends StateNotifier<List<String>> {
  FavoritesNotifier(this._repository) : super([]) {
    loadFavorites();
  }

  final FirstAidRepository _repository;

  void loadFavorites() {
    state = _repository.getFavorites();
  }

  Future<void> toggleFavorite(String guideId) async {
    await _repository.toggleFavorite(guideId);
    loadFavorites();
  }

  bool isFavorite(String guideId) {
    return state.contains(guideId);
  }
}
