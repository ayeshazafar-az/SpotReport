import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/constants.dart';

class GeminiAnalysisResult {
  final String damageSummary;
  final String severity;

  GeminiAnalysisResult({required this.damageSummary, required this.severity});
}

class GeminiService {
  static Future<GeminiAnalysisResult> analyzeDamageImage({
    required Uint8List imageBytes,
    String? contextDescription,
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: AppConstants.geminiApiKey,
      );

      final prompt = TextPart('''
You are an official highway police incident inspector AI. Analyze this vehicle damage image.
Optional Context from Officer: ${contextDescription ?? 'None provided'}

Provide a concise output in JSON format with exactly these two fields:
{
  "damage_summary": "Short 1-2 sentence description of physical vehicle damage visible",
  "severity": "Minor" or "Moderate" or "Severe"
}
Return ONLY raw JSON, no markdown formatting or extra text.
''');

      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      if (response.text == null || response.text!.isEmpty) {
        return GeminiAnalysisResult(
          damageSummary: 'Visual vehicle damage logged at scene.',
          severity: 'Minor',
        );
      }

      final cleanJson = response.text!
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final parsed = jsonDecode(cleanJson) as Map<String, dynamic>;

      return GeminiAnalysisResult(
        damageSummary:
            parsed['damage_summary'] as String? ??
            'Visual vehicle damage logged at scene.',
        severity: parsed['severity'] as String? ?? 'Minor',
      );
    } catch (e) {
      // Graceful fallback if offline or API key isn't provided yet
      return GeminiAnalysisResult(
        damageSummary: 'Visual evidence captured and stored by officer.',
        severity: 'Minor',
      );
    }
  }
}
