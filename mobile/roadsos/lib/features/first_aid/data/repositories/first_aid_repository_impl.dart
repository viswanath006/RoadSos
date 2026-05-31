import '../../domain/models/first_aid_guide.dart';
import '../../domain/repositories/first_aid_repository.dart';
import '../datasource/first_aid_local_datasource.dart';

class FirstAidRepositoryImpl implements FirstAidRepository {
  FirstAidRepositoryImpl({
    required FirstAidLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  final FirstAidLocalDataSource _localDataSource;

  @override
  Future<void> seedFirstAidData() => _localDataSource.seedFirstAidData();

  @override
  List<FirstAidGuide> getGuides() => _localDataSource.getGuides();

  @override
  List<FirstAidGuide> searchGuides(String query) =>
      _localDataSource.searchGuides(query);

  @override
  Future<void> toggleFavorite(String guideId) =>
      _localDataSource.toggleFavorite(guideId);

  @override
  List<String> getFavorites() => _localDataSource.getFavorites();
}
