import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/emergency_contact.dart';
import '../../domain/repositories/contacts_repository.dart';
import '../../data/repositories/contacts_repository_impl.dart';

final contactsRepositoryProvider = Provider<ContactsRepository>((ref) {
  return ContactsRepositoryImpl();
});

final contactsProvider =
    StateNotifierProvider<ContactsNotifier, List<EmergencyContact>>((ref) {
  final repository = ref.watch(contactsRepositoryProvider);
  return ContactsNotifier(repository);
});

class ContactsNotifier extends StateNotifier<List<EmergencyContact>> {
  ContactsNotifier(this._repository) : super([]) {
    loadContacts();
  }

  final ContactsRepository _repository;

  void loadContacts() {
    state = _repository.getContacts();
  }

  Future<void> addContact(EmergencyContact contact) async {
    await _repository.addContact(contact);
    loadContacts();
  }

  Future<void> updateContact(EmergencyContact contact) async {
    await _repository.updateContact(contact);
    loadContacts();
  }

  Future<void> deleteContact(String id) async {
    await _repository.deleteContact(id);
    loadContacts();
  }

  Future<void> setPrimaryContact(String id) async {
    await _repository.setPrimaryContact(id);
    loadContacts();
  }
}
