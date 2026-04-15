import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'llm_service.g.dart';

@Riverpod(keepAlive: true)
LLMService llmService(LlmServiceRef ref) {
  return LLMService();
}

const String _kGeminiModel = 'gemini-2.5-flash-preview-05-20';
const int _kMaxCompressedBytes = 400 * 1024; // 400 KB

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

  /// Compress an image file to at most ~400 KB for Gemini inline data.
  Future<Uint8List> compressImage(File file) async {
    // First pass: quality 25, max width 768
    var result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: 25,
      minWidth: 1,
      minHeight: 1,
      keepExif: false,
    );
    result ??= await file.readAsBytes();

    // Second pass if still too large
    if (result.length > _kMaxCompressedBytes) {
      final second = await FlutterImageCompress.compressWithList(
        result,
        quality: 10,
        minWidth: 1,
        minHeight: 1,
      );
      if (second.isNotEmpty) result = second;
    }

    debugPrint('LLMService: compressed ${file.path} → ${result.length} bytes');
    return result;
  }

  /// Entry point usable both directly and via compute().
  Future<Map<String, dynamic>> processFile(File file, {String? apiKey}) async {
    final key = apiKey ?? _envApiKey;
    if (key.isEmpty || key == 'INSERT_API_KEY_HERE') {
      debugPrint('LLMService: skipping — no API key');
      return {};
    }

    try {
      final bytes = await compressImage(file);
      return _callGemini(bytes, key);
    } catch (e) {
      debugPrint('LLMService.processFile error: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> processOCRText(String rawText,
      {String? apiKey}) async {
    final key = apiKey ?? _envApiKey;
    if (key.isEmpty || key == 'INSERT_API_KEY_HERE') {
      debugPrint('LLMService: skipping — no API key');
      return {};
    }
    if (rawText.trim().isEmpty) return {};

    try {
      final model = _buildModel(key);
      final content = [Content.text('$_kPrompt\n\nRAW TEXT:\n$rawText')];
      final response = await model.generateContent(content);
      return _parseResponse(response.text);
    } catch (e) {
      debugPrint('LLMService.processOCRText error: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _callGemini(
      Uint8List imageBytes, String apiKey) async {
    final model = _buildModel(apiKey);

    final content = [
      Content.multi([
        TextPart(_kPromptVision),
        DataPart('image/jpeg', imageBytes),
      ])
    ];

    final response = await model.generateContent(content);
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

/// Params bundle for compute() isolate.
class LlmIsolateParams {
  final String filePath;
  final String apiKey;
  const LlmIsolateParams({required this.filePath, required this.apiKey});
}

Future<Map<String, dynamic>> runLlmIsolate(LlmIsolateParams params) async {
  final service = LLMService(apiKey: params.apiKey);
  return service.processFile(File(params.filePath), apiKey: params.apiKey);
}

// ── Prompts ────────────────────────────────────────────────────────────────────

const String _kPrompt = '''
You are an intelligent assistant that processes OCR text from screenshots.
Analyze the following raw OCR text and output a valid JSON object with these fields:

1. "cleanText": Cleaned-up version of the text — fix typos, join broken lines, make it readable.
2. "tags": List of 1-3 tags. Use: #Finance, #Receipts, #SocialMedia, #Memes, #Travel, #TradingCharts, #Web3, #Code, #Junk, #To-Do, #Memories. Create a precise custom tag if none fit (e.g. #DeveloperCredentials).
3. "urls": List of URLs found.
4. "emails": List of email addresses.
5. "phoneNumbers": List of phone numbers.
6. "dates": List of dates or deadlines.
7. "cryptoAddresses": List of crypto wallet addresses.
8. "suggested_actions": Array of action objects, each with:
   - "label": Short button label (e.g. "Copy Address", "Open Link", "Dial Number")
   - "payload": The data (URL, address, phone number)
   - "intent_type": One of "url", "copy", "dial"

Output strictly valid JSON only.
''';

const String _kPromptVision = '''
You are an intelligent assistant that analyses screenshots.
Examine this image and output a valid JSON object with these fields:

1. "cleanText": All text visible in the image, cleaned and readable.
2. "tags": List of 1-3 tags. Use: #Finance, #Receipts, #SocialMedia, #Memes, #Travel, #TradingCharts, #Web3, #Code, #Junk, #To-Do, #Memories. Create a precise custom tag if none fit.
3. "urls": List of URLs visible.
4. "emails": List of email addresses visible.
5. "phoneNumbers": List of phone numbers visible.
6. "dates": List of dates or deadlines visible.
7. "cryptoAddresses": List of crypto wallet addresses visible.
8. "suggested_actions": Array of action objects, each with:
   - "label": Short button label
   - "payload": The data
   - "intent_type": One of "url", "copy", "dial"

Output strictly valid JSON only.
''';
