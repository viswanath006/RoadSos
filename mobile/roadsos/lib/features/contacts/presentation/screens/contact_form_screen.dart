import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/emergency_contact.dart';
import '../providers/contacts_provider.dart';

class ContactFormScreen extends ConsumerStatefulWidget {
  const ContactFormScreen({super.key, this.contact});

  final EmergencyContact? contact;

  @override
  ConsumerState<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends ConsumerState<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  String _relationship = 'Friend';
  bool _isPrimary = false;

  final List<String> _relationships = [
    'Friend',
    'Parent',
    'Spouse',
    'Sibling',
    'Child',
    'Relative',
    'Guardian',
    'Doctor',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    final contact = widget.contact;
    if (contact != null) {
      _nameController = TextEditingController(text: contact.name);
      _phoneController = TextEditingController(text: contact.phoneNumber);
      _relationship = _relationships.contains(contact.relationship)
          ? contact.relationship
          : 'Other';
      _isPrimary = contact.isPrimary;
    } else {
      _nameController = TextEditingController();
      _phoneController = TextEditingController();
      _isPrimary = ref.read(contactsProvider).isEmpty; // Default first contact to primary
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final id = widget.contact?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final newContact = EmergencyContact(
      id: id,
      name: _nameController.text.trim(),
      relationship: _relationship,
      phoneNumber: _phoneController.text.trim(),
      isPrimary: _isPrimary,
    );

    try {
      if (widget.contact == null) {
        await ref.read(contactsProvider.notifier).addContact(newContact);
      } else {
        await ref.read(contactsProvider.notifier).updateContact(newContact);
      }
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.contact == null ? 'Contact Saved Successfully' : 'Contact Updated Successfully'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.sosRed,
          ),
        );
      }
    }
  }

  void _delete() {
    if (widget.contact == null) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact?'),
        content: Text('Are you sure you want to remove ${widget.contact!.name} from emergency contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(contactsProvider.notifier).deleteContact(widget.contact!.id);
              Navigator.of(context).pop(); // pop dialog
              Navigator.of(context).pop(); // pop screen
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.sosRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.contact != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Contact' : 'Add Contact',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.sosRed),
              onPressed: _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 8),
                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Name',
                        labelStyle: const TextStyle(color: AppTheme.textSecondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.sosRed, width: 2),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 24),

                    // Relationship Dropdown
                    DropdownButtonFormField<String>(
                      value: _relationship,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Relationship',
                        labelStyle: const TextStyle(color: AppTheme.textSecondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.sosRed, width: 2),
                        ),
                      ),
                      items: _relationships.map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(r),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _relationship = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Phone Number Field
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: const TextStyle(color: AppTheme.textSecondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.sosRed, width: 2),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter a phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Primary Contact Toggle
                    SwitchListTile(
                      title: const Text(
                        'Set as Primary Contact',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      value: _isPrimary,
                      activeColor: AppTheme.sosRed,
                      onChanged: ref.read(contactsProvider).isEmpty && widget.contact == null
                          ? null // Force first contact as primary
                          : (val) {
                              setState(() {
                                _isPrimary = val;
                              });
                            },
                    ),
                  ],
                ),
              ),

              // Save Button at bottom
              Padding(
                padding: const EdgeInsets.all(24),
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.sosRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'SAVE CONTACT',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
