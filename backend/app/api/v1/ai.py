import os
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
import httpx

router = APIRouter()

class FirstAidRequest(BaseModel):
    query: str

class FirstAidResponse(BaseModel):
    response: str
    is_mock: bool

# Simple local first-aid response mapping for offline/mock fallback
MOCK_RESPONSES = {
    "bleeding": (
        "**⚠️ EMERGENCY WARNING: CALL 108 OR 112 IMMEDIATELY FOR SEVERE OR LIFE-THREATENING BLEEDING.**\n\n"
        "Here are immediate first aid steps for bleeding:\n"
        "1. **Apply Direct Pressure**: Place a clean cloth, bandage, or your gloved hand directly over the wound. Press firmly.\n"
        "2. **Elevate**: If possible, raise the injured limb above the level of the heart to slow the blood flow.\n"
        "3. **Keep Pressure Applied**: Do not remove the cloth if it gets soaked; add another cloth on top and keep pressing.\n"
        "4. **Tourniquet (Last Resort)**: If bleeding is severe from a limb and direct pressure fails, apply a tourniquet high and tight above the wound.\n"
        "5. **Keep Patient Warm & Calm**: Protect them from shock by laying them down and covering them."
    ),
    "cpr": (
        "**⚠️ EMERGENCY WARNING: CALL 108 OR 112 IMMEDIATELY BEFORE STARTING CPR.**\n\n"
        "Follow these steps for Hands-Only CPR on an adult:\n"
        "1. **Check Responsiveness**: Tap the person's shoulder and shout, 'Are you okay?'\n"
        "2. **Check Breathing**: Look at the chest for 5-10 seconds. If not breathing or only gasping, start CPR.\n"
        "3. **Position Your Hands**: Place the heel of one hand in the center of the chest (on the breastbone), and the other hand on top, interlocking fingers.\n"
        "4. **Push Hard and Fast**: Compress the chest at a rate of 100 to 120 beats per minute (to the beat of 'Staying Alive'). Push down at least 2 inches (5 cm).\n"
        "5. **Minimize Interruptions**: Continue compressions until medical professionals arrive or the person starts breathing/moving."
    ),
    "burns": (
        "**⚠️ EMERGENCY WARNING: CALL 108 OR 112 IMMEDIATELY FOR MAJOR OR CHEMICAL BURNS.**\n\n"
        "First aid steps for minor/thermal burns:\n"
        "1. **Cool the Burn**: Run cool (not cold/ice) water over the burned area for 10 to 20 minutes.\n"
        "2. **Remove Tight Items**: Gently slide off rings, watches, or clothing before the area swells.\n"
        "3. **Do Not Pop Blisters**: Fluid-filled blisters protect the skin from infection. If they break, clean gently.\n"
        "4. **Apply Lotion/Aloe Vera**: Once cooled, apply aloe vera or a moisturizer to soothe.\n"
        "5. **Bandage Loosely**: Cover the burn with a clean, non-stick bandage to protect the skin."
    ),
    "fracture": (
        "**⚠️ EMERGENCY WARNING: CALL 108 OR 112 IMMEDIATELY FOR COMPOUND FRACTURES OR NECK/SPINE INJURIES.**\n\n"
        "First aid steps for suspected bone fractures:\n"
        "1. **Stop Bleeding**: Apply pressure to any open wounds with a clean dressing.\n"
        "2. **Immobilize the Area**: Do not try to realign the bone. Apply a splint above and below the joint to prevent movement.\n"
        "3. **Apply Ice/Cold Pack**: Wrap ice in a towel and apply to the area for 10-20 minutes to reduce swelling and pain.\n"
        "4. **Elevate**: If possible, elevate the injured limb gently.\n"
        "5. **Treat for Shock**: Lay the person flat, elevate feet slightly, and keep them warm."
    )
}

SYSTEM_INSTRUCTION = (
    "You are a helpful, concise AI First Aid Assistant for the RoadSoS app.\n"
    "Your job is to provide immediate, actionable, and clear step-by-step first aid guidance based on the user's emergency query.\n"
    "Rules:\n"
    "1. Focus on immediate, practical actions the user can perform right now.\n"
    "2. Keep it highly readable and structured using bullet points or numbered lists. Use Markdown bolding for key terms.\n"
    "3. Keep it brief—in an emergency, nobody has time to read a wall of text.\n"
    "4. CRITICAL WARNING: Always prepend a warning message in bold format reminding them to contact official emergency services (108/112 in India) first if they have not already done so.\n"
    "5. If the query is completely unrelated to first aid, medical issues, or emergencies, politely decline to answer and guide them to ask only first aid or emergency safety questions."
)

@router.post("/first-aid", response_model=FirstAidResponse)
async def get_first_aid_guidance(payload: FirstAidRequest):
    query_lower = payload.query.lower()
    api_key = os.environ.get("GEMINI_API_KEY")

    # If API key is missing or blank, use local mock intelligence
    if not api_key:
        # Match keywords for mock response
        matched_response = None
        for key, resp in MOCK_RESPONSES.items():
            if key in query_lower:
                matched_response = resp
                break
        
        if not matched_response:
            matched_response = (
                "**⚠️ EMERGENCY WARNING: IF THIS IS A SEVERE MEDICAL EMERGENCY, CALL 108 OR 112 IMMEDIATELY.**\n\n"
                f"You asked about: *\"{payload.query}\"*.\n\n"
                "*(Note: Gemini API key is not configured on the server, showing mock response)*\n\n"
                "**Immediate General First Aid Guidelines:**\n"
                "- **Check Scene Safety**: Ensure you are not putting yourself in danger.\n"
                "- **Assess the Victim**: Check for responsiveness, airway clearance, and breathing.\n"
                "- **Control Bleeding**: Apply firm, direct pressure on any actively bleeding wounds.\n"
                "- **Keep the Patient Warm**: Prevent shock by keeping the victim comfortable and calm.\n"
                "- **Stay with the Patient**: Reassure them until professional emergency services arrive."
            )
        return FirstAidResponse(response=matched_response, is_mock=True)

    # Call Gemini REST API using httpx
    try:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}"
        
        request_body = {
            "contents": [
                {
                    "parts": [
                        {"text": payload.query}
                    ]
                }
            ],
            "systemInstruction": {
                "parts": [
                    {"text": SYSTEM_INSTRUCTION}
                ]
            }
        }

        async with httpx.AsyncClient(timeout=10.0) as client:
            res = await client.post(url, json=request_body)
            if res.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_502_BAD_GATEWAY,
                    detail=f"Gemini API returned status code {res.status_code}: {res.text}"
                )
            
            data = res.json()
            # Extract content from response
            try:
                text_response = data["candidates"][0]["content"]["parts"][0]["text"]
                return FirstAidResponse(response=text_response, is_mock=False)
            except (KeyError, IndexError):
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Malformed response received from Gemini API."
                )
                
    except httpx.RequestError as exc:
        # Fallback to mock on connection errors to keep hackathon demo stable
        # Match keywords for mock response
        matched_response = None
        for key, resp in MOCK_RESPONSES.items():
            if key in query_lower:
                matched_response = resp
                break
        if not matched_response:
            matched_response = (
                "**⚠️ EMERGENCY WARNING: CALL 108 OR 112 FOR ALL SEVERE EMERGENCIES.**\n\n"
                "Unable to connect to the AI model. Please check your internet connection.\n\n"
                "**General Safety Rules:**\n"
                "- Stay calm and reassure the injured person.\n"
                "- Apply direct pressure on bleeding areas.\n"
                "- Do not move the patient unless there is immediate danger (e.g. fire)."
            )
        return FirstAidResponse(response=matched_response, is_mock=True)
