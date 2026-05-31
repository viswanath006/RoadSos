# RoadSoS Phase 1 – Setup

## 1. Install Flutter

https://docs.flutter.dev/get-started/install/windows

Verify:

```powershell
flutter doctor
```

## 2. Generate platform folders (first time only)

The repo includes `lib/` source. Run once to create Android/iOS runners:

```powershell
cd mobile\roadsos
flutter create . --project-name roadsos --org com.roadsos
```

This adds `android/`, `ios/`, `web/` without replacing your `lib/` code.

## 3. Run the app

```powershell
flutter pub get
flutter run
```

## 4. Test SOS flow

1. Open app → Home screen  
2. Tap red **SOS** button  
3. Allow location permission  
4. See latitude, longitude, address, and OSM map centered on you  

## 5. Troubleshooting

| Issue | Fix |
|-------|-----|
| GPS disabled | Enable Location in device settings → Retry |
| Permission denied | Tap **Settings** on error screen |
| Emulator has no location | Android Emulator ⋮ → Location → set lat/lng |
| Map tiles blank | Check internet (OSM tiles need network) |

## Project path

All Phase 1 code lives under:

`mobile/roadsos/lib/`

See `docs/PHASE1_ARCHITECTURE.md` for architecture details.
