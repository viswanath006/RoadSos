import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/connectivity_banner.dart';
import '../../domain/models/emergency_contact.dart';
import '../providers/contacts_provider.dart';
import 'contact_form_screen.dart';

class ContactListScreen extends ConsumerWidget {
  const ContactListScreen({super.key});

  void _openContactForm(BuildContext context, [EmergencyContact? contact]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ContactFormScreen(contact: contact),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Emergency Contacts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (contacts.length < 10)
            IconButton(
              icon: const Icon(Icons.add, size: 28),
              onPressed: () => _openContactForm(context),
            ),
        ],
      ),
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: contacts.isEmpty
                ? const _EmptyContactsState()
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: contacts.length,
                          itemBuilder: (context, index) {
                            final contact = contacts[index];
                            return _ContactCard(
                              contact: contact,
                              onEdit: () => _openContactForm(context, contact),
                            );
                          },
                        ),
                      ),
                      // Bottom count indicator
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'You can add up to 10 contacts',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${contacts.length} / 10',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.sosRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyContactsState extends StatelessWidget {
  const _EmptyContactsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.people_alt_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          const Text(
            'No Trusted Contacts Yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add up to 10 family members, friends, or guardians who should receive your GPS coordinates in an emergency.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              height: 1.5,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ContactFormScreen(),
                ),
              );
            },
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Add Your First Contact'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sosRed,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends ConsumerWidget {
  const _ContactCard({
    required this.contact,
    required this.onEdit,
  });

  final EmergencyContact contact;
  final VoidCallback onEdit;

  Future<void> _makeCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Color _getAvatarColor(String name) {
    final nameHash = name.hashCode;
    final List<Color> colors = [
      Colors.purple.shade100,
      Colors.pink.shade100,
      Colors.blue.shade100,
      Colors.teal.shade100,
      Colors.orange.shade100,
    ];
    return colors[nameHash % colors.length];
  }

  Color _getTextColor(String name) {
    final nameHash = name.hashCode;
    final List<Color> colors = [
      Colors.purple.shade900,
      Colors.pink.shade900,
      Colors.blue.shade900,
      Colors.teal.shade900,
      Colors.orange.shade900,
    ];
    return colors[nameHash % colors.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarColor = _getAvatarColor(contact.name);
    final textColor = _getTextColor(contact.name);
    final firstLetter = contact.name.trim().isNotEmpty ? contact.name.trim()[0].toUpperCase() : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: contact.isPrimary ? AppTheme.sosRed.withOpacity(0.4) : Colors.grey.shade200,
          width: contact.isPrimary ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: avatarColor,
                radius: 24,
                child: Text(
                  firstLetter,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Name, relationship, phone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            contact.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (contact.isPrimary) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Primary',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact.phoneNumber,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Phone Call button on the right
              IconButton(
                icon: const Icon(Icons.phone_rounded, color: Colors.blue),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  padding: const EdgeInsets.all(10),
                ),
                onPressed: () => _makeCall(contact.phoneNumber),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
