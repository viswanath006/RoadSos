"""Seed demo services when DB is empty. Run: python -m scripts.seed_data"""
import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from geoalchemy2.elements import WKTElement
from sqlalchemy import select, func

from app.core.database import AsyncSessionLocal
from app.models.service import Service, ServiceCategory

DEMO_SERVICES = [
    ("Apollo Hospitals Greams Road", ServiceCategory.hospital, 13.0638, 80.2512, "+914424482424", "Greams Road"),
    ("MIOT International", ServiceCategory.trauma_center, 13.0402, 80.1818, "+914442242288", "Manapakkam"),
    ("108 Ambulance Control", ServiceCategory.ambulance, 13.0067, 80.2206, "108", "State Emergency"),
    ("Adyar Police Station", ServiceCategory.police, 13.0062, 80.2574, "100", "Adyar"),
    ("Guindy Towing Service", ServiceCategory.towing, 13.0065, 80.2120, "+919876500001", "Guindy"),
    ("Anna Nagar Auto Care", ServiceCategory.mechanic, 13.0850, 80.2101, "+919876500002", "Anna Nagar"),
    ("T Nagar Puncture Shop", ServiceCategory.puncture_shop, 13.0418, 80.2341, "+919876500003", "T Nagar"),
]


async def main():
    async with AsyncSessionLocal() as session:
        count = await session.scalar(select(func.count()).select_from(Service))
        if count and count > 0:
            print(f"Services already seeded ({count} rows). Skipping.")
            return
        for name, cat, lat, lng, phone, address in DEMO_SERVICES:
            geom = WKTElement(f"POINT({lng} {lat})", srid=4326)
            session.add(
                Service(
                    name=name,
                    category=cat,
                    latitude=lat,
                    longitude=lng,
                    geom=geom,
                    phone=phone,
                    address=address,
                )
            )
        await session.commit()
        print(f"Seeded {len(DEMO_SERVICES)} services.")


if __name__ == "__main__":
    asyncio.run(main())
