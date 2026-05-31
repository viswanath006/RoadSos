import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../crash_detection/presentation/screens/crash_settings_screen.dart';
import '../../../localization/presentation/screens/language_settings_screen.dart';
import '../../domain/models/user_profile.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bloodGroupController;
  late TextEditingController _allergiesController;
  late TextEditingController _conditionsController;
  late TextEditingController _notesController;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _bloodGroupController = TextEditingController(text: profile.bloodGroup);
    _allergiesController = TextEditingController(text: profile.allergies);
    _conditionsController = TextEditingController(text: profile.conditions);
    _notesController = TextEditingController(text: profile.notes);
  }

  @override
  void dispose() {
    _bloodGroupController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final updated = ref.read(profileProvider).copyWith(
            bloodGroup: _bloodGroupController.text.trim(),
            allergies: _allergiesController.text.trim(),
            conditions: _conditionsController.text.trim(),
            notes: _notesController.text.trim(),
          );
      ref.read(profileProvider.notifier).saveProfile(updated);
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medical profile updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save_rounded : Icons.edit_note_rounded),
            color: _isEditing ? Colors.green : AppTheme.sosRed,
            iconSize: 28,
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Avatar Card
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.sosRed.withOpacity(0.1),
                      child: const Icon(
                        Icons.health_and_safety_rounded,
                        size: 60,
                        color: AppTheme.sosRed,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Emergency Medical ID',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Information accessible by first responders',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Medical Profile Fields
              Text(
                'MEDICAL INFORMATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.sosRed.withOpacity(0.8),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),

              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _bloodGroupController,
                        label: 'Blood Group',
                        icon: Icons.bloodtype_outlined,
                        hint: 'e.g. O+ or AB-',
                        enabled: _isEditing,
                      ),
                      const Divider(height: 24),
                      _buildTextField(
                        controller: _allergiesController,
                        label: 'Allergies',
                        icon: Icons.warning_amber_rounded,
                        hint: 'e.g. Penicillin, Peanuts or None',
                        enabled: _isEditing,
                      ),
                      const Divider(height: 24),
                      _buildTextField(
                        controller: _conditionsController,
                        label: 'Medical Conditions',
                        icon: Icons.medical_services_outlined,
                        hint: 'e.g. Asthma, Diabetes or None',
                        enabled: _isEditing,
                      ),
                      const Divider(height: 24),
                      _buildTextField(
                        controller: _notesController,
                        label: 'Emergency Notes',
                        icon: Icons.note_alt_outlined,
                        hint: 'Any other crucial information...',
                        enabled: _isEditing,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Preferences Section
              Text(
                'APP SETTINGS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary.withOpacity(0.8),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.car_crash_outlined,
                      color: Colors.orange.shade700,
                      title: 'Crash Detection Settings',
                      subtitle: 'Configure automated SOS triggers',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const CrashSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildSettingsTile(
                      icon: Icons.g_translate_outlined,
                      color: Colors.blue.shade700,
                      title: 'Language Settings',
                      subtitle: 'Change app localization',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const LanguageSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    required bool enabled,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.sosRed),
        border: enabled ? const OutlineInputBorder() : InputBorder.none,
        contentPadding: enabled
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
            : EdgeInsets.zero,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
