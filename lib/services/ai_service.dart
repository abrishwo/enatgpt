import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chat_gpt/utils/app_keys.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'package:google_generative_ai/google_generative_ai.dart'; // Import Gemini

class AIService {
  final String _baseUrl = "https://api.openai.com/v1";
  // Retrieve Gemini API key from .env, allow it to be null
  final String? _geminiApiKey = dotenv.env['GEMINI_API_KEY'];

  /// ✅ Fetches ChatGPT Text Response from gpt-4o (copied from open_ai_api2.dart)
  Future<String?> getChatResponse(String message) async {
    // Assuming openAiToken is also loaded from dotenv and has similar null/empty checks if necessary
    if (openAiToken.isEmpty) { // Basic check, assuming openAiToken is non-nullable due to '!'
        print("🔴 OpenAI API Key is not set.");
        return "Error: OpenAI API Key is not set.";
    }
    String endpoint = '$_baseUrl/chat/completions';

    Map<String, String> headers = {
      'Authorization': 'Bearer $openAiToken',
      'Content-Type': 'application/json',
    };

    Map<String, dynamic> body = {
      'model': 'gpt-4o',
      'messages': [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": message}
      ],
      'max_tokens': 200,
      'temperature': 0.7,
      'top_p': 1.0,
    };

    try {
      print("🔵 Sending request to OpenAI (getChatResponse)...");
      var response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(body),
      );

      print("🟡 Response Code (getChatResponse): ${response.statusCode}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print("🟢 Raw API response (getChatResponse): $data");

        String? chatResponse = data['choices'][0]['message']?['content']?.toString().trim();
        print("✅ Parsed ChatGPT Response (getChatResponse): $chatResponse");
        return chatResponse ?? "❗ No content in response.";
      } else {
        print("🔴 API Error (getChatResponse) ${response.statusCode}: ${response.body}");
        return "❌ API Error: ${response.statusCode}";
      }
    } catch (e) {
      print("🔴 Exception occurred (getChatResponse): $e");
      return "❌ Exception: $e";
    }
  }

  /// ✅ Fetches AI-generated Image from OpenAI (copied from open_ai_api2.dart)
  Future<String> getImageFromChatGpt(String message, {required String? size}) async {
    if (openAiToken.isEmpty) {
        print("🔴 OpenAI API Key is not set for getImageFromChatGpt.");
        return "Error: OpenAI API Key is not set.";
    }
    try {
      print("🔵 Sending image generation request (OpenAI)...");
      var response = await http.post(
        Uri.parse("$_baseUrl/images/generations"),
        headers: {
          "Authorization": "Bearer $openAiToken",
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"prompt": message, "size": size ?? "256x256", "n": 1}),
      );

      print("🟡 Image API response code (OpenAI): ${response.statusCode}");

      if (response.statusCode == 200) {
        final imageUrl = jsonDecode(response.body)["data"][0]["url"];
        print("🖼️ Image URL (OpenAI): $imageUrl");
        return imageUrl;
      } else {
        print("🔴 Image API Error (OpenAI) ${response.statusCode}: ${response.body}");
        return "Error: Image generation failed (OpenAI)";
      }
    } catch (e) {
      print("🔴 Exception during image generation (OpenAI): $e");
      return "Error: Exception during image generation (OpenAI)";
    }
  }

  /// ✅ Fetches ChatGPT Text Response using gpt-4o-mini (copied from open_ai_api.dart)
  Future<String> chatComplete(String question) async {
    if (openAiToken.isEmpty) {
        print("🔴 OpenAI API Key is not set for chatComplete.");
        return "Error: OpenAI API Key is not set.";
    }
    final url = Uri.parse('$_baseUrl/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $openAiToken',
    };
    final body = jsonEncode({
      "model": "gpt-4o-mini",
      "store": true,
      "messages": [
        {"role": "user", "content": question.trim()}
      ]
    });

    try {
      print("🔵 Sending request to OpenAI (chatComplete)...");
      final response = await http.post(url, headers: headers, body: body);
      print("🟡 Response Code (chatComplete): ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("🟢 Raw API response (chatComplete): $data");
        final content = data['choices'][0]['message']['content'];
        print("✅ Parsed ChatGPT Response (chatComplete): $content");
        return content.toString().trim();
      } else {
        print("🔴 API Error (chatComplete) ${response.statusCode}: ${response.body}");
        return 'Error: OpenAI API Error ${response.statusCode}';
      }
    } catch (e) {
      print("🔴 Exception occurred (chatComplete): $e");
      return 'Error: Exception $e';
    }
  }

  /// ✨ Generates content using Google Gemini Pro
  Future<String> generateContentWithGemini(String prompt) async {
    if (_geminiApiKey == null || _geminiApiKey!.isEmpty) {
      print("🔴 Gemini API Key is missing or empty.");
      return "Error: Gemini API Key is not set or is empty.";
    }
    try {
      print("🔵 Sending request to Gemini (generateContentWithGemini)...");
      final model = GenerativeModel(model: 'gemini-pro', apiKey: _geminiApiKey!);
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      print("🟢 Raw API response (Gemini): ${response.text}");
      return response.text ?? "❗ No content in Gemini response.";
    } catch (e) {
      print("🔴 Exception occurred (Gemini): $e");
      return 'Error: Exception during Gemini content generation: $e';
    }
  }

  /// 🖼️ Generates an image using Google Gemini (Placeholder)
  Future<String> generateImageWithGemini(String prompt) async {
    if (_geminiApiKey == null || _geminiApiKey!.isEmpty) {
      print("🔴 Gemini API Key is missing or empty for image generation.");
      return "Error: Gemini API Key is not set or is empty.";
    }
    // NOTE: As of late 2023/early 2024, Gemini Pro doesn't directly generate images
    // in the same way DALL-E does (returning URLs).
    // Gemini Vision models are for understanding images.
    // This is a placeholder. You might need to use a different Google service
    // or wait for future Gemini image generation capabilities.
    print("🔵 Sending image generation request to Gemini (generateImageWithGemini)...");
    print("⚠️ Image generation with Gemini Pro/Vision is not directly supported by returning URLs in this way.");
    print("⚠️ This method is a placeholder and will return a mock message.");
    return Future.value("Placeholder: Gemini image generation feature is under development. Prompt: '$prompt'");
  }
}
