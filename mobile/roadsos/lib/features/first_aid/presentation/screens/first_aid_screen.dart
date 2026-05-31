import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/first_aid_guide.dart';
import '../providers/first_aid_provider.dart';
import 'first_aid_detail_screen.dart';
import 'ai_first_aid_screen.dart';

class FirstAidScreen extends ConsumerStatefulWidget {
  const FirstAidScreen({super.key});

  @override
  ConsumerState<FirstAidScreen> createState() => _FirstAidScreenState();
}

class _FirstAidScreenState extends ConsumerState<FirstAidScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openGuideDetail(FirstAidGuide guide) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FirstAidDetailScreen(guide: guide),
      ),
    );
  }

  Widget _buildCategoryTile({
    required String title,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final guides = ref.watch(firstAidGuidesProvider);
    final searchQuery = ref.watch(firstAidSearchQueryProvider);

    // Filtered guides if searching
    final filteredGuides = guides.where((guide) {
      if (searchQuery.isEmpty) return true;
      return guide.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          guide.steps.any((s) => s.toLowerCase().contains(searchQuery.toLowerCase()));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search bleeding, burns, CPR...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                onChanged: (value) {
                  ref.read(firstAidSearchQueryProvider.notifier).state = value;
                },
              )
            : const Text(
                'First Aid',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search_rounded, size: 28),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  ref.read(firstAidSearchQueryProvider.notifier).state = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _isSearching
              ? _buildSearchResults(filteredGuides)
              : ListView(
                  children: [
                    _buildCategoryTile(
                      title: 'Bleeding',
                      icon: Icons.water_drop_rounded,
                      color: const Color(0xFFD32F2F),
                      backgroundColor: const Color(0xFFFFEBEE),
                      onTap: () => _navigateToGuide(guides, 'bleeding'),
                    ),
                    _buildCategoryTile(
                      title: 'Fractures',
                      icon: Icons.construction_rounded,
                      color: Colors.orange.shade800,
                      backgroundColor: const Color(0xFFFFF3E0),
                      onTap: () => _navigateToGuide(guides, 'fracture'),
                    ),
                    _buildCategoryTile(
                      title: 'Burns',
                      icon: Icons.local_fire_department_rounded,
                      color: Colors.purple.shade700,
                      backgroundColor: const Color(0xFFF3E5F5),
                      onTap: () => _navigateToGuide(guides, 'burns'),
                    ),
                    _buildCategoryTile(
                      title: 'Unconscious Victim',
                      icon: Icons.person_rounded,
                      color: Colors.blue.shade700,
                      backgroundColor: const Color(0xFFE3F2FD),
                      onTap: () => _navigateToGuide(guides, 'unconscious'),
                    ),
                    _buildCategoryTile(
                      title: 'Road Accident Victim',
                      icon: Icons.car_crash_rounded,
                      color: Colors.green.shade700,
                      backgroundColor: const Color(0xFFE8F5E9),
                      onTap: () => _navigateToGuide(guides, 'accident_victim'),
                    ),
                    _buildCategoryTile(
                      title: 'CPR Basics',
                      icon: Icons.add_box_rounded,
                      color: Colors.red.shade800,
                      backgroundColor: const Color(0xFFFFEBEE),
                      onTap: () => _navigateToGuide(guides, 'cpr'),
                    ),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.psychology_outlined),
        label: const Text('ASK AI ASSISTANT'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AiFirstAidScreen(),
            ),
          );
        },
      ),
    );
  }

  void _navigateToGuide(List<FirstAidGuide> guides, String id) {
    final guide = guides.firstWhere(
      (g) => g.id == id,
      orElse: () => FirstAidGuide(
        id: id,
        title: id == 'cpr' ? 'CPR Basics' : 'Guide Details',
        category: 'First Aid',
        steps: const [],
        disclaimer: '',
      ),
    );
    _openGuideDetail(guide);
  }

  Widget _buildSearchResults(List<FirstAidGuide> results) {
    if (results.isEmpty) {
      return const Center(
        child: Text(
          'No guides found matching search query.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final guide = results[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            title: Text(
              guide.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              guide.category,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openGuideDetail(guide),
          ),
        );
      },
    );
  }
}
