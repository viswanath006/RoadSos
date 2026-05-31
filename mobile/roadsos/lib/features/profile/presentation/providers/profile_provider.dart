import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../domain/models/user_profile.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, UserProfile>((ref) {
  return ProfileNotifier();
});

class ProfileNotifier extends StateNotifier<UserProfile> {
  ProfileNotifier() : super(UserProfile.empty()) {
    _loadProfile();
  }

  late final Box<UserProfile> _box;

  void _loadProfile() {
    _box = Hive.box<UserProfile>('user_profile_box');
    final saved = _box.get('profile');
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    state = profile;
    await _box.put('profile', profile);
  }
}
