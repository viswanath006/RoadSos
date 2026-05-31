import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../contacts/presentation/providers/contacts_provider.dart';
import '../../incidents/presentation/providers/incidents_provider.dart';

enum SosAlertStatus { idle, sending, success, error }

class SosAlertState {
  const SosAlertState({
    required this.status,
    this.errorMessage,
  });

  final SosAlertStatus status;
  final String? errorMessage;

  factory SosAlertState.idle() => const SosAlertState(status: SosAlertStatus.idle);
  factory SosAlertState.sending() => const SosAlertState(status: SosAlertStatus.sending);
  factory SosAlertState.success() => const SosAlertState(status: SosAlertStatus.success);
  factory SosAlertState.error(String msg) =>
      SosAlertState(status: SosAlertStatus.error, errorMessage: msg);
}

final sosAlertProvider =
    StateNotifierProvider.autoDispose<SosAlertNotifier, SosAlertState>((ref) {
  return SosAlertNotifier(ref);
});

class SosAlertNotifier extends StateNotifier<SosAlertState> {
  SosAlertNotifier(this._ref) : super(SosAlertState.idle());

  final Ref _ref;

  Future<void> sendSosAlert({
    required double latitude,
    required double longitude,
  }) async {
    state = SosAlertState.sending();

    final contacts = _ref.read(contactsProvider);
    if (contacts.isEmpty) {
      state = SosAlertState.error('No trusted contacts added. Please add contacts first.');
      return;
    }

    final mapsLink = 'https://maps.google.com/?q=$latitude,$longitude';
    final message = '''
EMERGENCY ALERT

Possible road accident detected.

Current Location:
$mapsLink

Please contact me immediately.

Sent via RoadSoS.''';

    bool alertSent = false;
    try {
      final phoneNumbers = contacts.map((c) => c.phoneNumber.trim()).toList();
      
      // Separator depends on platform: iOS uses semicolon or comma, Android uses comma
      final separator = Platform.isIOS ? ';' : ',';
      final recipients = phoneNumbers.join(separator);
      
      final smsUri = Uri.parse('sms:$recipients?body=${Uri.encodeComponent(message)}');

      if (await canLaunchUrl(smsUri)) {
        alertSent = await launchUrl(smsUri);
      } else {
        // Fallback to sharing via Share Sheet
        await Share.share(message, subject: 'EMERGENCY ALERT');
        alertSent = true; // Handed off to manual sharing
      }

      // Log incident
      await _ref.read(incidentsProvider.notifier).logIncident(
            latitude: latitude,
            longitude: longitude,
            alertSent: alertSent,
          );

      state = SosAlertState.success();
    } catch (e) {
      // Even if launcher fails, try Share Sheet as ultimate backup
      try {
        await Share.share(message, subject: 'EMERGENCY ALERT');
        alertSent = true;
        await _ref.read(incidentsProvider.notifier).logIncident(
              latitude: latitude,
              longitude: longitude,
              alertSent: true,
            );
        state = SosAlertState.success();
      } catch (innerError) {
        state = SosAlertState.error('Failed to send SOS: ${innerError.toString()}');
      }
    }
  }
}
