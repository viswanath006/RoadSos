# RoadSoS API Documentation

Base URL: `http://localhost:8000/api/v1`

Auth: `Authorization: Bearer <access_token>`

## Auth

### POST `/auth/register`

```json
{
  "name": "Ravi Kumar",
  "phone": "+919876543210",
  "email": "ravi@example.com",
  "password": "securepass123"
}
```

**Response 201**

```json
{
  "access_token": "...",
  "refresh_token": "...",
  "token_type": "bearer",
  "user": { "id": "uuid", "name": "...", "phone": "...", "email": "..." }
}
```

### POST `/auth/login`

```json
{ "phone": "+919876543210", "password": "securepass123" }
```

### POST `/auth/refresh`

```json
{ "refresh_token": "..." }
```

## Users

### GET `/users/me`

Returns current user profile.

## SOS

### POST `/sos/trigger`

Triggers emergency flow. **Requires auth.**

```json
{
  "latitude": 13.0067,
  "longitude": 80.2206,
  "address_text": "IIT Madras, Chennai"
}
```

**Response 200**

```json
{
  "incident_id": "uuid",
  "message": "Emergency Alert! Possible road accident...",
  "maps_link": "https://maps.google.com/?q=13.0067,80.2206",
  "nearby_services": [
    {
      "id": "uuid",
      "name": "Apollo Hospital",
      "category": "hospital",
      "distance_m": 1200,
      "phone": "+914412345678",
      "latitude": 13.01,
      "longitude": 80.22,
      "eta_minutes": null
    }
  ],
  "contacts_notified": 2
}
```

## Services

### GET `/services/nearby`

| Query | Type | Description |
|-------|------|-------------|
| latitude | float | Required |
| longitude | float | Required |
| category | string | Optional filter |
| radius_m | int | Default 10000 |
| limit | int | Default 20 |

### GET `/services/categories`

Returns list of valid categories.

## Emergency Contacts

### GET `/contacts/`

### POST `/contacts/`

```json
{
  "contact_name": "Mom",
  "phone": "+919999999999",
  "is_primary": true
}
```

### PUT `/contacts/{id}`

### DELETE `/contacts/{id}`

## Incidents

### GET `/incidents/`

List user's past SOS incidents.

### GET `/incidents/{id}`

## Health

### GET `/health`

```json
{ "status": "ok", "database": "connected" }
```

## Errors

| Code | Meaning |
|------|---------|
| 401 | Invalid/expired token |
| 404 | Resource not found |
| 422 | Validation error |

Interactive docs: `/docs` (Swagger), `/redoc`
