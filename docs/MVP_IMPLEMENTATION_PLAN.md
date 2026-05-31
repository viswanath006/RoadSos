# RoadSoS MVP Implementation Plan

## Phase 1 – SOS + GPS + Emergency Services ✅

| Task | Owner | Deliverable |
|------|-------|-------------|
| PostGIS schema | Backend | `database/schema.sql` |
| Nearby query | Backend | `ServiceRepository.find_nearby` |
| SOS endpoint | Backend | `POST /api/v1/sos/trigger` |
| JWT auth | Backend | Register/login |
| SOS button UI | Flutter | `SosButton` + confirm dialog |
| GPS capture | Flutter | `LocationRepository` |
| Services list/map | Flutter | OSM tiles + filters |

**Demo script:** Register → Home → SOS → See hospitals/ambulance/police → Call/Navigate.

## Phase 2 – Offline + First Aid ✅

| Task | Deliverable |
|------|-------------|
| Hive init | `LocalStorage` |
| First aid JSON | `assets/data/first_aid.json` |
| Helplines UI | `FirstAidScreen` |
| Cached services | `cached_services` box |
| Offline SOS | SMS + maps link without API |

## Phase 3 – Emergency Contacts ✅

| Task | Deliverable |
|------|-------------|
| Contacts API | CRUD `/contacts/` |
| Local sync | `ContactsRepository` |
| SOS notify | `notifyContactsSms` |

## Phase 4 – Crash Detection 🔲

| Task | File |
|------|------|
| Accelerometer | `crash_detection_service.dart` |
| Safety dialog | Wire in `HomeScreen` |
| Profile toggle | `ProfileScreen` |

## Phase 5 – AI Assistant 🔲

| Task | File |
|------|------|
| Gemini client | `ai_first_aid_placeholder.dart` |
| Voice SOS | `speech_to_text` in home |

## 48-Hour Hackathon Schedule

**Day 1 AM:** Docker DB + seed + API smoke test  
**Day 1 PM:** Flutter login + SOS end-to-end  
**Day 2 AM:** Offline + first aid + contacts  
**Day 2 PM:** Polish UI, demo video, pitch deck  

## Testing Checklist

- [ ] SOS with backend running
- [ ] SOS with airplane mode (SMS fallback)
- [ ] Nearby services within 10 km of IITM
- [ ] Add/remove contact
- [ ] First aid opens without network
