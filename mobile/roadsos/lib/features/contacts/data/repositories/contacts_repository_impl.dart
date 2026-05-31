import 'package:hive/hive.dart';
import '../../domain/models/emergency_contact.dart';
import '../../domain/repositories/contacts_repository.dart';

class ContactsRepositoryImpl implements ContactsRepository {
  ContactsRepositoryImpl({Box<EmergencyContact>? box})
      : _box = box ?? Hive.box<EmergencyContact>('contacts_box');

  final Box<EmergencyContact> _box;

  @override
  List<EmergencyContact> getContacts() {
    return _box.values.toList();
  }

  @override
  Future<void> addContact(EmergencyContact contact) async {
    final contacts = getContacts();
    if (contacts.length >= 10) {
      throw Exception('Maximum contact limit of 10 reached.');
    }

    bool isPrimary = contact.isPrimary;
    if (contacts.isEmpty) {
      isPrimary = true; // Default first contact to primary
    }

    final newContact = contact.copyWith(isPrimary: isPrimary);

    if (isPrimary) {
      await _clearOtherPrimaries('');
    }

    await _box.put(newContact.id, newContact);
  }

  @override
  Future<void> updateContact(EmergencyContact contact) async {
    if (contact.isPrimary) {
      await _clearOtherPrimaries(contact.id);
    }
    await _box.put(contact.id, contact);
  }

  @override
  Future<void> deleteContact(String id) async {
    final deletedContact = _box.get(id);
    await _box.delete(id);

    // If primary was deleted, assign a remaining contact as primary
    if (deletedContact != null && deletedContact.isPrimary) {
      final remaining = getContacts();
      if (remaining.isNotEmpty) {
        final first = remaining.first;
        await _box.put(first.id, first.copyWith(isPrimary: true));
      }
    }
  }

  @override
  Future<void> setPrimaryContact(String id) async {
    final contact = _box.get(id);
    if (contact != null) {
      await _clearOtherPrimaries(id);
      await _box.put(id, contact.copyWith(isPrimary: true));
    }
  }

  Future<void> _clearOtherPrimaries(String excludeId) async {
    for (final key in _box.keys) {
      if (key != excludeId) {
        final contact = _box.get(key);
        if (contact != null && contact.isPrimary) {
          await _box.put(key, contact.copyWith(isPrimary: false));
        }
      }
    }
  }
}
