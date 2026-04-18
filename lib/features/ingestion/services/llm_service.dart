import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'llm_service.g.dart';

@Riverpod(keepAlive: true)
LLMService llmService(LlmServiceRef ref) {
  return LLMService();
}

const String _kGeminiModel = 'gemini-2.5-flash';

class LLMService {
  final String _envApiKey;

  LLMService({String? apiKey})
      : _envApiKey = apiKey ?? (dotenv.env['GEMINI_API_KEY'] ?? '') {
    if (_envApiKey.isEmpty || _envApiKey == 'INSERT_API_KEY_HERE') {
      debugPrint('Warning: GEMINI_API_KEY is not set or is default in .env');
    }
  }

  GenerativeModel _buildModel(String apiKey) {
    return GenerativeModel(
      model: _kGeminiModel,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
  }

  static String _mimeFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
      case 'heif':
        return 'image/heif';
      default:
        return 'image/jpeg';
    }
  }

  /// Analyse a screenshot. Sends raw image bytes + OCR text (if available) to Gemini.
  Future<Map<String, dynamic>> processFile(
    File file, {
    String? apiKey,
    String? ocrText,
  }) async {
    final key = apiKey ?? _envApiKey;
    if (key.isEmpty || key == 'INSERT_API_KEY_HERE') {
      debugPrint('LLMService: skipping — no API key.');
      return {};
    }

    try {
      final bytes = await file.readAsBytes();
      debugPrint('LLMService: sending ${bytes.length} bytes for ${file.path}');
      final mime = _mimeFromPath(file.path);
      final result = await _callGemini(bytes, key, mime, ocrText: ocrText);
      debugPrint('LLMService: got ${result.keys.length} fields for ${file.path}');
      return result;
    } catch (e, st) {
      debugPrint('LLMService.processFile error: $e\n$st');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _callGemini(
    Uint8List imageBytes,
    String apiKey,
    String mimeType, {
    String? ocrText,
  }) async {
    final model = _buildModel(apiKey);

    final promptText =
        (ocrText != null && ocrText.trim().isNotEmpty)
            ? '$_kPromptVision\n\nOCR TEXT EXTRACTED FROM IMAGE:\n${ocrText.trim()}'
            : _kPromptVision;

    final content = [
      Content.multi([
        TextPart(promptText),
        DataPart(mimeType, imageBytes),
      ])
    ];

    debugPrint('LLMService: calling $_kGeminiModel (${imageBytes.length} bytes, mime=$mimeType)…');
    final response = await model.generateContent(content);
    debugPrint('LLMService: raw response length = ${response.text?.length ?? 0}');
    return _parseResponse(response.text);
  }

  Map<String, dynamic> _parseResponse(String? responseText) {
    if (responseText == null) return {};
    var json = responseText.trim();
    if (json.startsWith('```json')) {
      json = json.replaceFirst(RegExp(r'^```json\s*'), '');
    } else if (json.startsWith('```')) {
      json = json.replaceFirst(RegExp(r'^```\s*'), '');
    }
    if (json.endsWith('```')) {
      json = json.replaceFirst(RegExp(r'\s*```$'), '');
    }
    json = json.trim();

    try {
      final decoded = jsonDecode(json);
      if (decoded is Map<String, dynamic>) return decoded;
      debugPrint('LLMService: JSON is not a Map: $decoded');
      return {};
    } catch (e) {
      debugPrint('LLMService: JSON parse error: $e\nRaw: $responseText');
      return {};
    }
  }
}

// ── Isolate entry point ────────────────────────────────────────────────────────

class LlmIsolateParams {
  final String filePath;
  final String apiKey;
  final String? ocrText;
  const LlmIsolateParams({
    required this.filePath,
    required this.apiKey,
    this.ocrText,
  });
}

Future<Map<String, dynamic>> runLlmIsolate(LlmIsolateParams params) async {
  final service = LLMService(apiKey: params.apiKey);
  return service.processFile(
    File(params.filePath),
    apiKey: params.apiKey,
    ocrText: params.ocrText,
  );
}

// ── Prompts ────────────────────────────────────────────────────────────────────

const String _kPromptVision = '''
You are an intelligent assistant that analyses screenshots.
Examine this image carefully, along with any OCR text provided, and output a valid JSON object.

Fields:
1. "cleanText": All readable text visible in the image, cleaned up and properly formatted.
2. "tags": List of 1–5 descriptive tags that best describe the screenshot content.
   - Every tag MUST start with '#'
   - Be specific and accurate to the actual content
   - Use these as guidance (or invent precise variants when content demands it):
     #Finance, #Receipts, #Invoice, #SocialMedia, #Memes, #Travel, #TradingCharts,
     #Web3, #Crypto, #NFT, #DeFi, #Code, #Junk, #To-Do, #Memories, #Education,
     #Health, #Fitness, #Medical, #News, #Shopping, #Entertainment, #Food, #Gaming,
     #Legal, #Productivity, #Portfolio, #PersonalFinance, #Receipt, #Screenshot
   - Use #Junk ONLY if the image is blank, dark, blurry, or has no recognisable content
   - Do NOT use #BlankImage, #Empty, #NoContent, #Unknown — use #Junk instead
   - Do NOT return empty string tags
3. "urls": List of URLs visible in the image.
4. "emails": List of email addresses visible.
5. "phoneNumbers": List of phone numbers visible.
6. "dates": List of dates or deadlines visible.
7. "cryptoAddresses": List of crypto wallet addresses visible.
8. "suggested_actions": Array of action objects, each with:
   - "label": Short button label (e.g. "Open Link", "Copy Address", "Dial Number")
   - "payload": The data (URL, address, phone number)
   - "intent_type": One of "url", "copy", "dial"
9. "suggested_app": The single best companion app for the user's needs inferred from this content.
   Choose ONE of: "pulse" (health/wellness/vitals/fitness/sleep/nutrition/habits/biometrics),
   "context" (dictionary/vocabulary/word definitions/language learning/reading/translations),
   "magnum_opus" (long-form writing/creative content/AI chat/brainstorming/essays/documents).
   Return null if no clear match.

Output strictly valid JSON only. No markdown, no explanation.
''';
