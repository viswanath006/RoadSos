# RoadSoS Offline Strategy

## Always Available (bundled in app)

| Data | Storage | Key |
|------|---------|-----|
| 112, 108, 101 | Hive `emergency_numbers` | Static seed on first launch |
| First aid guides | Hive `first_aid` | JSON asset `assets/data/first_aid.json` |
| SOS message template | Code constant | — |

## Cached After Online Use

| Data | TTL | Hive box |
|------|-----|----------|
| Emergency contacts | Until logout | `contacts` |
| Last nearby services | 24h | `cached_services` |
| User profile | Session | `user` |
| Last incident summary | 7d | `incidents` |

## Degraded SOS (no network)

1. GPS still works (device permission)
2. Show cached services if any; else static helpline cards
3. `url_launcher` SMS to all Hive contacts with maps link
4. Queue incident POST when connectivity returns (`connectivity_plus`)

## Sync on Reconnect

`OfflineSyncNotifier` retries failed SOS API calls and contact sync.
