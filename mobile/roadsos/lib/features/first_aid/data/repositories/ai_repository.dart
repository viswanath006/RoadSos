import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AiFirstAidRepository {
  final http.Client _client;

  AiFirstAidRepository({http.Client? client}) : _client = client ?? http.Client();

  String get _baseUrl {
    // In Android emulator, 10.0.2.2 points to host's localhost
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000/api/v1';
      }
    } catch (_) {}
    return 'http://localhost:8000/api/v1';
  }

  Future<String> fetchFirstAidGuidance(String query) async {
    final uri = Uri.parse('$_baseUrl/ai/first-aid');
    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'query': query}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['response'] as String;
      } else {
        return _getLocalFallback(query);
      }
    } catch (e) {
      return _getLocalFallback(query);
    }
  }

  String _getLocalFallback(String query) {
    final queryLower = query.toLowerCase();
    
    if (queryLower.contains('bleed') || queryLower.contains('blood')) {
      return "**⚠️ EMERGENCY WARNING: CALL 108 OR 112 IMMEDIATELY FOR SEVERE OR LIFE-THREATENING BLEEDING.**\n\n"
          "Here are immediate first aid steps for bleeding:\n"
          "1. **Apply Direct Pressure**: Place a clean cloth, bandage, or your gloved hand directly over the wound. Press firmly.\n"
          "2. **Elevate**: If possible, raise the injured limb above the level of the heart to slow the blood flow.\n"
          "3. **Keep Pressure Applied**: Do not remove the cloth if it gets soaked; add another cloth on top and keep pressing.\n"
          "4. **Tourniquet (Last Resort)**: If bleeding is severe from a limb and direct pressure fails, apply a tourniquet high and tight above the wound.\n"
          "5. **Keep Patient Warm & Calm**: Protect them from shock by laying them down and covering them.";
    }
    
    if (queryLower.contains('cpr') || queryLower.contains('breath') || queryLower.contains('heart')) {
      return "**⚠️ EMERGENCY WARNING: CALL 108 OR 112 IMMEDIATELY BEFORE STARTING CPR.**\n\n"
          "Follow these steps for Hands-Only CPR on an adult:\n"
          "1. **Check Responsiveness**: Tap the person's shoulder and shout, 'Are you okay?'\n"
          "2. **Check Breathing**: Look at the chest for 5-10 seconds. If not breathing or only gasping, start CPR.\n"
          "3. **Position Your Hands**: Place the heel of one hand in the center of the chest (on the breastbone), and the other hand on top, interlocking fingers.\n"
          "4. **Push Hard and Fast**: Compress the chest at a rate of 100 to 120 beats per minute (to the beat of 'Staying Alive'). Push down at least 2 inches (5 cm).\n"
          "5. **Minimize Interruptions**: Continue compressions until medical professionals arrive or the person starts breathing/moving.";
    }
    
    if (queryLower.contains('burn') || queryLower.contains('fire')) {
      return "**⚠️ EMERGENCY WARNING: CALL 108 OR 112 IMMEDIATELY FOR MAJOR OR CHEMICAL BURNS.**\n\n"
          "First aid steps for minor/thermal burns:\n"
          "1. **Cool the Burn**: Run cool (not cold/ice) water over the burned area for 10 to 20 minutes.\n"
          "2. **Remove Tight Items**: Gently slide off rings, watches, or clothing before the area swells.\n"
          "3. **Do Not Pop Blisters**: Fluid-filled blisters protect the skin from infection. If they break, clean gently.\n"
          "4. **Apply Lotion/Aloe Vera**: Once cooled, apply aloe vera or a moisturizer to soothe.\n"
          "5. **Bandage Loosely**: Cover the burn with a clean, non-stick bandage to protect the skin.";
    }
    
    if (queryLower.contains('fracture') || queryLower.contains('bone') || queryLower.contains('broken')) {
      return "**⚠️ EMERGENCY WARNING: CALL 108 OR 112 IMMEDIATELY FOR COMPOUND FRACTURES OR NECK/SPINE INJURIES.**\n\n"
          "First aid steps for suspected bone fractures:\n"
          "1. **Stop Bleeding**: Apply pressure to any open wounds with a clean dressing.\n"
          "2. **Immobilize the Area**: Do not try to realign the bone. Apply a splint above and below the joint to prevent movement.\n"
          "3. **Apply Ice/Cold Pack**: Wrap ice in a towel and apply to the area for 10-20 minutes to reduce swelling and pain.\n"
          "4. **Elevate**: If possible, elevate the injured limb gently.\n"
          "5. **Treat for Shock**: Lay the person flat, elevate feet slightly, and keep them warm.";
    }
    
    return "**⚠️ EMERGENCY WARNING: IF THIS IS A SEVERE MEDICAL EMERGENCY, CALL 108 OR 112 IMMEDIATELY.**\n\n"
        "*(Note: App running in offline local mode)*\n\n"
        "**Immediate General First Aid Guidelines:**\n"
        "- **Check Scene Safety**: Ensure you are not putting yourself in danger.\n"
        "- **Assess the Victim**: Check for responsiveness, airway clearance, and breathing.\n"
        "- **Control Bleeding**: Apply firm, direct pressure on any actively bleeding wounds.\n"
        "- **Keep the Patient Warm**: Prevent shock by keeping the victim comfortable and calm.\n"
        "- **Stay with the Patient**: Reassure them until professional emergency services arrive.";
  }
}
