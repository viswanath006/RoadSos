# RoadSoS – IITM National Road Safety Hackathon

**Golden Hour emergency response** – one-tap SOS, nearest services, offline essentials.

## Quick Start

### Prerequisites

- Docker Desktop (PostgreSQL + PostGIS)
- Python 3.11+
- Flutter 3.16+ (for mobile)
- Optional: Firebase project (Auth + FCM)

### 1. Database & Backend

```bash
cd backend
cp .env.example .env
docker compose up -d
pip install -r requirements.txt
python -m scripts.seed_data
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API docs: http://localhost:8000/docs

### 2. Flutter App

```bash
cd mobile/roadsos
flutter pub get
# Set API base URL in lib/core/config/app_config.dart
flutter run
```

## Project Structure

```
ROADSOS/
├── docs/           # Architecture, API, ER, roadmap, wireframes
├── database/       # PostgreSQL + PostGIS schema & seeds
├── backend/        # FastAPI (Clean Architecture)
└── mobile/roadsos/ # Flutter (Riverpod + Hive)
```

## MVP Phases

| Phase | Scope | Status |
|-------|--------|--------|
| 1 | SOS + GPS + Emergency Services | ✅ Implemented |
| 2 | Offline Mode + First Aid | ✅ Implemented |
| 3 | Emergency Contacts | ✅ Implemented |
| 4 | Crash Detection | 🔲 Scaffolded |
| 5 | AI First Aid (Gemini) | 🔲 Scaffolded |

## Hackathon Alignment

- **Reliability**: Incident logging, retry on SOS notify
- **Data accuracy**: PostGIS distance, OSM/seeded services
- **Offline**: Hive cache for numbers, first aid, contacts, cached services
- **Innovation**: Crash detection & voice SOS hooks (Phase 4)

## License

Hackathon MVP – IITM Road Safety Hackathon 2026.
