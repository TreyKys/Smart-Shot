import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'llm_service.g.dart';

@Riverpod(keepAlive: true)
LLMService llmService(LlmServiceRef ref) {
  return LLMService();
}

class LLMService {
  late final GenerativeModel _model;
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";

  LLMService() {
    if (_apiKey.isEmpty || _apiKey == "INSERT_API_KEY_HERE") {
      debugPrint("Warning: GEMINI_API_KEY is not set or is default in .env");
    }
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
  }

  Future<Map<String, dynamic>> processOCRText(String rawText) async {
    if (_apiKey.isEmpty || _apiKey == "INSERT_API_KEY_HERE") {
        debugPrint("Skipping LLM processing due to missing API key.");
        return {};
    }
    if (rawText.trim().isEmpty) return {};

    const prompt = """
    You are an intelligent assistant that processes OCR text from screenshots.
    Your task is to analyze the following raw OCR text and output a valid JSON object with the following fields:

    1. "cleanText": A cleaned-up version of the text. Fix typos, join broken lines into paragraphs, and make it readable.
    2. "tags": A list of 1-3 categorization tags.
       - Use standard tags if applicable: #Finance, #Receipts, #SocialMedia, #Memes, #Travel, #TradingCharts, #Web3, #ChemistryNotes, #AnatomyDiagrams, #CodeSnippets, #Memories.
       - If none fit, create a custom, highly accurate tag based on the content (e.g., #DeveloperCredentials, #Pharmacology).
    3. "urls": A list of URLs found in the text.
    4. "emails": A list of email addresses found.
    5. "phoneNumbers": A list of phone numbers found.
    6. "dates": A list of dates or deadlines found.
    7. "cryptoAddresses": A list of cryptocurrency addresses found.
    8. "suggested_actions": A JSON array of suggested actions based on the content.
       - Each action object must have:
         - "label": A short, descriptive button label (e.g., "Copy Contract Address", "Track Package", "Open Link").
         - "payload": The actual data for the action (e.g., the URL, the address, the phone number).
         - "intent_type": One of "url", "copy", "dial".

    Output strictly valid JSON.
    """;

    try {
      final content = [Content.text("$prompt\n\nRAW TEXT:\n$rawText")];
      final response = await _model.generateContent(content);

      final responseText = response.text;
      if (responseText == null) return {};

      // Sanitize response if it contains markdown code blocks (just in case the model ignores the mime type instruction, though usually it respects it)
      final jsonString = responseText.replaceAll(RegExp(r'^```json\s*', multiLine: true), '').replaceAll(RegExp(r'\s*```$', multiLine: true), '').trim();

      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        debugPrint("Error parsing LLM JSON response: $e\nResponse: $responseText");
        return {};
      }
    } catch (e) {
      debugPrint("Error calling Gemini API: $e");
      return {};
    }
  }
}
