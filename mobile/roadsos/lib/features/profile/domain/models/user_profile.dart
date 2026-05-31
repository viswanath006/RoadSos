class UserProfile {
  const UserProfile({
    required this.bloodGroup,
    required this.allergies,
    required this.conditions,
    required this.notes,
    required this.primaryContactName,
    required this.primaryContactPhone,
  });

  final String bloodGroup;
  final String allergies;
  final String conditions;
  final String notes;
  final String primaryContactName;
  final String primaryContactPhone;

  factory UserProfile.empty() {
    return const UserProfile(
      bloodGroup: '',
      allergies: '',
      conditions: '',
      notes: '',
      primaryContactName: '',
      primaryContactPhone: '',
    );
  }

  UserProfile copyWith({
    String? bloodGroup,
    String? allergies,
    String? conditions,
    String? notes,
    String? primaryContactName,
    String? primaryContactPhone,
  }) {
    return UserProfile(
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      conditions: conditions ?? this.conditions,
      notes: notes ?? this.notes,
      primaryContactName: primaryContactName ?? this.primaryContactName,
      primaryContactPhone: primaryContactPhone ?? this.primaryContactPhone,
    );
  }
}
