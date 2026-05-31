import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/home/presentation/main_navigation_screen.dart';
import 'features/contacts/domain/models/emergency_contact.dart';
import 'features/contacts/data/models/emergency_contact_adapter.dart';
import 'features/incidents/domain/models/incident.dart';
import 'features/incidents/data/models/incident_adapter.dart';
import 'features/services/domain/emergency_service.dart';
import 'features/offline/data/datasource/emergency_service_adapter.dart';
import 'features/first_aid/domain/models/first_aid_guide.dart';
import 'features/first_aid/data/models/first_aid_guide_adapter.dart';
import 'features/first_aid/data/datasource/first_aid_local_datasource.dart';
import 'features/crash_detection/domain/models/crash_settings.dart';
import 'features/crash_detection/domain/models/crash_event.dart';
import 'features/crash_detection/data/models/crash_settings_adapter.dart';
import 'features/crash_detection/data/models/crash_event_adapter.dart';
import 'features/profile/domain/models/user_profile.dart';
import 'features/profile/data/models/user_profile_adapter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(EmergencyContactAdapter());
  Hive.registerAdapter(IncidentAdapter());
  Hive.registerAdapter(EmergencyServiceAdapter());
  Hive.registerAdapter(FirstAidGuideAdapter());
  Hive.registerAdapter(CrashSettingsAdapter());
  Hive.registerAdapter(CrashEventAdapter());
  Hive.registerAdapter(UserProfileAdapter());

  // Open boxes
  await Hive.openBox<EmergencyContact>('contacts_box');
  await Hive.openBox<Incident>('incidents_box');
  await Hive.openBox<EmergencyService>('cached_services_box');
  await Hive.openBox<FirstAidGuide>('first_aid_box');
  await Hive.openBox<String>('favorites_box');
  await Hive.openBox('offline_settings_box');
  await Hive.openBox<CrashSettings>('crash_settings_box');
  await Hive.openBox<CrashEvent>('crash_events_box');
  await Hive.openBox<UserProfile>('user_profile_box');
  await Hive.openBox<int>('service_clicks_box');

  // Seed default offline first-aid guides
  final firstAidDataSource = FirstAidLocalDataSourceImpl();
  await firstAidDataSource.seedFirstAidData();

  runApp(const ProviderScope(child: RoadSosApp()));
}

class RoadSosApp extends StatelessWidget {
  const RoadSosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoadSoS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const MainNavigationScreen(),
    );
  }
}
