# RoadSoS – Phase 1 MVP (Flutter)

One-tap SOS with GPS, reverse geocoding, and OpenStreetMap.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.16+
- Android emulator or physical device with location enabled

## Run

```bash
cd mobile/roadsos
flutter pub get
flutter run
```

If Android/iOS folders are incomplete:

```bash
flutter create . --project-name roadsos
flutter pub get
flutter run
```

## Permissions

- **Android**: Location permission is declared in `AndroidManifest.xml`. Grant when prompted on SOS.
- **iOS**: Add to `ios/Runner/Info.plist` after `flutter create`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>RoadSoS needs your location during emergencies.</string>
```

## Phase 1 scope

| Included | Not included (later phases) |
|----------|----------------------------|
| Home + SOS + Map | Auth, contacts, offline |
| GPS + address | Backend API, crash detection |
| Quick action placeholders | AI, voice SOS |

## Screen flow

`Home` → tap **SOS** → `SOS Screen` (coordinates + map)  
`Home` → quick cards → placeholder service screens
