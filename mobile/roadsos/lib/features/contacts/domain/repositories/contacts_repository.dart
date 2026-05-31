import '../models/emergency_contact.dart';

abstract class ContactsRepository {
  List<EmergencyContact> getContacts();
  Future<void> addContact(EmergencyContact contact);
  Future<void> updateContact(EmergencyContact contact);
  Future<void> deleteContact(String id);
  Future<void> setPrimaryContact(String id);
}
