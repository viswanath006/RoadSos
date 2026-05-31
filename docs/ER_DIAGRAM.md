# RoadSoS – Database ER Diagram

```mermaid
erDiagram
    USERS ||--o{ EMERGENCY_CONTACTS : has
    USERS ||--o{ INCIDENTS : reports
    USERS ||--o{ SOS_ALERTS : sends

    USERS {
        uuid id PK
        string name
        string phone UK
        string email UK
        string password_hash
        boolean is_primary_contact_set
        timestamptz created_at
    }

    EMERGENCY_CONTACTS {
        uuid id PK
        uuid user_id FK
        string contact_name
        string phone
        boolean is_primary
        int sort_order
    }

    INCIDENTS {
        uuid id PK
        uuid user_id FK
        float latitude
        float longitude
        geography geom
        string address_text
        string status
        timestamptz triggered_at
    }

    SOS_ALERTS {
        uuid id PK
        uuid incident_id FK
        uuid contact_id FK
        string channel
        string status
        timestamptz sent_at
    }

    SERVICES {
        uuid id PK
        string name
        string category
        float latitude
        float longitude
        geography geom
        string phone
        string address
        jsonb metadata
    }

    CACHED_USER_SERVICES {
        uuid id PK
        uuid user_id FK
        uuid service_id FK
        timestamptz accessed_at
    }

    USERS ||--o{ CACHED_USER_SERVICES : caches
    SERVICES ||--o{ CACHED_USER_SERVICES : referenced
```

## PostGIS Notes

- `services.geom` and `incidents.geom` use `GEOGRAPHY(POINT, 4326)`
- Spatial index: `GIST (geom)`
- Nearby query: `ST_DWithin(geom, ST_MakePoint(lng, lat)::geography, radius_m)`

## Category Enum (services.category)

`hospital`, `trauma_center`, `ambulance`, `police`, `towing`, `mechanic`, `puncture_shop`
