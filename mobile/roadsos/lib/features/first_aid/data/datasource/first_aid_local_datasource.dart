import 'package:hive/hive.dart';
import '../../domain/models/first_aid_guide.dart';

abstract class FirstAidLocalDataSource {
  Future<void> seedFirstAidData();
  List<FirstAidGuide> getGuides();
  List<FirstAidGuide> searchGuides(String query);
  Future<void> toggleFavorite(String guideId);
  List<String> getFavorites();
}

class FirstAidLocalDataSourceImpl implements FirstAidLocalDataSource {
  FirstAidLocalDataSourceImpl({
    Box<FirstAidGuide>? guidesBox,
    Box<String>? favoritesBox,
    Box? settingsBox,
  })  : _guidesBox = guidesBox ?? Hive.box<FirstAidGuide>('first_aid_box'),
        _favoritesBox = favoritesBox ?? Hive.box<String>('favorites_box'),
        _settingsBox = settingsBox ?? Hive.box('offline_settings_box');

  final Box<FirstAidGuide> _guidesBox;
  final Box<String> _favoritesBox;
  final Box _settingsBox;

  @override
  Future<void> seedFirstAidData() async {
    final isSeeded = _settingsBox.get('is_seeded', defaultValue: false) as bool;
    if (isSeeded) return;

    final defaultGuides = [
      const FirstAidGuide(
        id: 'bleeding',
        title: 'Bleeding Control',
        category: 'Trauma',
        steps: [
          'Apply direct pressure on the wound with a clean cloth or sterile bandage.',
          'Elevate the injured area above the heart level if possible to reduce blood flow.',
          'Keep pressure applied until bleeding stops; do not remove the cloth if soaked, add another on top.',
          'Seek immediate medical assistance or call emergency services if bleeding is severe or doesn\'t stop.'
        ],
        disclaimer: 'Educational guidance only. Follow official medical protocols.',
      ),
      const FirstAidGuide(
        id: 'fracture',
        title: 'Fracture & Splinting',
        category: 'Trauma',
        steps: [
          'Immobilize the injured area using splints or bandages; do not try to realign the bone.',
          'Avoid unnecessary movement to prevent further tissue or nerve damage.',
          'Apply a cold pack wrapped in a cloth to reduce swelling, if skin is unbroken.',
          'Call emergency services immediately and keep the patient calm.'
        ],
        disclaimer: 'Educational guidance only. Follow official medical protocols.',
      ),
      const FirstAidGuide(
        id: 'burns',
        title: 'Burns & Scalds',
        category: 'Thermal',
        steps: [
          'Cool the burn immediately under cool running water for at least 10 minutes.',
          'Do not apply ice, butter, ointments, or adhesive bandages directly to the burn.',
          'Cover the burned area loosely with a clean, sterile cloth or cling wrap.',
          'Seek medical attention for deep burns, facial burns, or burns covering large areas.'
        ],
        disclaimer: 'Educational guidance only. Follow official medical protocols.',
      ),
      const FirstAidGuide(
        id: 'unconscious',
        title: 'Unconscious Victim',
        category: 'Medical',
        steps: [
          'Check responsiveness by gently shaking shoulders and asking loudly if they are okay.',
          'Check breathing by listening and watching chest movement for up to 10 seconds.',
          'Place in the recovery position (on their side) if they are breathing to keep airway clear.',
          'Call an ambulance immediately and monitor breathing until assistance arrives.'
        ],
        disclaimer: 'Educational guidance only. Follow official medical protocols.',
      ),
      const FirstAidGuide(
        id: 'accident_victim',
        title: 'Road Accident Victim',
        category: 'Trauma',
        steps: [
          'Ensure the scene is safe for you and the victim before approaching (hazard lights, safety triangles).',
          'Call emergency services immediately, detailing coordinates and number of victims.',
          'Do not move the victim unless there is an immediate threat of fire, explosion, or hazard (suspect spinal injury).',
          'Keep the victim warm and calm; monitor their level of consciousness and breathing.'
        ],
        disclaimer: 'Educational guidance only. Follow official medical protocols.',
      ),
      const FirstAidGuide(
        id: 'cpr',
        title: 'CPR Basics',
        category: 'Life Support',
        steps: [
          'Check responsiveness and breathing; if unresponsive and not breathing, start CPR.',
          'Call emergency services and request an AED if available.',
          'Perform chest compressions: push hard and fast in the center of the chest (100-120 per minute, 2 inches deep).',
          'If trained, give 2 rescue breaths after every 30 compressions; otherwise, perform hands-only CPR.'
        ],
        disclaimer: 'Educational guidance only. Follow official medical protocols.',
      ),
    ];

    for (final guide in defaultGuides) {
      await _guidesBox.put(guide.id, guide);
    }
    await _settingsBox.put('is_seeded', true);
  }

  @override
  List<FirstAidGuide> getGuides() {
    return _guidesBox.values.toList();
  }

  @override
  List<FirstAidGuide> searchGuides(String query) {
    if (query.trim().isEmpty) return getGuides();
    final lowerQuery = query.toLowerCase();
    return _guidesBox.values.where((guide) {
      return guide.title.toLowerCase().contains(lowerQuery) ||
          guide.category.toLowerCase().contains(lowerQuery) ||
          guide.steps.any((s) => s.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  @override
  Future<void> toggleFavorite(String guideId) async {
    if (_favoritesBox.containsKey(guideId)) {
      await _favoritesBox.delete(guideId);
    } else {
      await _favoritesBox.put(guideId, guideId);
    }
  }

  @override
  List<String> getFavorites() {
    return _favoritesBox.values.toList();
  }
}
