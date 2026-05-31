# RoadSoS – Development Roadmap

## Phase 1 – SOS + GPS + Emergency Services (Week 1) ✅

- [x] PostgreSQL schema + PostGIS
- [x] FastAPI: auth, SOS trigger, nearby services
- [x] Flutter: splash, login, home SOS, services map/list
- [x] GPS auto-capture on SOS
- [x] Distance sorting + call/navigate actions

## Phase 2 – Offline + First Aid (Week 1–2) ✅

- [x] Hive: emergency numbers, first aid JSON
- [x] Cache last nearby services + contacts
- [x] Offline-first aid card UI
- [x] Degraded SOS (SMS/maps link without API)

## Phase 3 – Emergency Contacts (Week 2) ✅

- [x] CRUD contacts API + Hive sync
- [x] Primary contact flag
- [x] Bulk notify on SOS (SMS intent + backend log)

## Phase 4 – Crash Detection (Week 3) 🔲

- [ ] `sensors_plus` accelerometer stream
- [ ] Impact heuristic (delta > threshold)
- [ ] 15s countdown “Are you safe?”
- [ ] Auto SOS if no dismiss

## Phase 5 – AI + Voice (Week 3–4) 🔲

- [ ] Gemini API first-aid Q&A (`lib/features/ai/`)
- [ ] `speech_to_text` for “Help” / “Emergency”
- [ ] FCM push for contact alerts (server-side)

## Judging Criteria Mapping

| Criterion | Implementation |
|-----------|----------------|
| Reliability | Incident DB, SOS retry, offline fallback |
| Data accuracy | PostGIS + seeded IITM-area services |
| Service coverage | 7 categories, extensible seed script |
| Offline | Hive layers documented in `OFFLINE.md` |
| Innovation | Crash/voice scaffolds in Flutter |
| Global | OSM categories, lat/lng anywhere |

## Post-Hackathon

- Real ambulance/hospital API partnerships
- Government 112 integration where available
- End-to-end encryption for location shares
- Admin portal for service verification
