import '../../domain/models/first_aid_guide.dart';

abstract class FirstAidRepository {
  Future<void> seedFirstAidData();
  List<FirstAidGuide> getGuides();
  List<FirstAidGuide> searchGuides(String query);
  Future<void> toggleFavorite(String guideId);
  List<String> getFavorites();
}
