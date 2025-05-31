// import 'dart:convert'; // No longer needed
// import 'package:http/http.dart' as http; // No longer needed
// import 'package:chat_gpt/utils/app_keys.dart'; // No longer needed for openAiToken
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'package:google_generative_ai/google_generative_ai.dart'; // Import Gemini

class AIService {
  // final String _baseUrl = "https://api.openai.com/v1"; // Removed
  // Retrieve Gemini API key from .env, allow it to be null
  final String? _geminiApiKey = dotenv.env['GEMINI_API_KEY'];

  /// ✨ Generates content using Google Gemini Pro
  Future<String> generateContentWithGemini(String prompt) async {
    // Log the prompt
    print("ℹ️ Gemini Prompt: $prompt");

    if (_geminiApiKey == null || _geminiApiKey!.isEmpty) {
      print("🔴 Gemini API Key is missing or empty.");
      return "Error: Gemini API Key is not set or is empty. Please ensure it is configured in your .env file.";
    }

    // Log partial API Key for verification
    if (_geminiApiKey!.length > 5) {
        print("ℹ️ Using Gemini API Key (first 5 chars): ${_geminiApiKey!.substring(0, 5)}...");
    } else {
        print("ℹ️ Using Gemini API Key (short key): ${_geminiApiKey!}"); // Should ideally not happen if key is valid
    }

    try {
      print("🔵 Sending request to Gemini (generateContentWithGemini)...");
      final model = GenerativeModel(model: 'gemini-pro', apiKey: _geminiApiKey!);
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      // Log the raw response text if available
      if (response.text != null) {
        print("🟢 Raw API response (Gemini): ${response.text}");
      } else {
        print("🟡 Gemini response text is null.");
      }

      if (response.text == null || response.text!.isEmpty) {
        print("🔴 Gemini response text is null or empty after check.");
        // Check for prompt feedback which might indicate blocking
        if (response.promptFeedback != null) {
          print("ℹ️ Gemini Prompt Feedback: ${response.promptFeedback}");
          if (response.promptFeedback!.blockReason != null) {
            return "Error: Content generation blocked by Gemini. Reason: ${response.promptFeedback!.blockReason}. Message: ${response.promptFeedback!.blockReasonMessage}";
          }
        }
        return "Error: Empty response from Gemini. No content generated.";
      }
      return response.text!;
    } on InvalidApiKey catch (e) {
      print("🔴 Gemini API Key is invalid: $e");
      return "Error: Invalid Gemini API Key. Please check your configuration. Details: $e";
    } on ServerException catch (e) {
      print("🔴 Gemini ServerException: $e");
      return "Error: Gemini server error. Please try again later. Details: $e";
    } on GenerativeAIException catch (e) { // Catch other specific AI exceptions
      print("🔴 Gemini GenerativeAIException: $e (${e.runtimeType})");
      String message = e.toString();
      return "Error: AI content generation failed (Gemini). Details: $message";
    } catch (e, s) { // Catch any other general exceptions and stack trace
      print("🔴 Unexpected Exception occurred (Gemini): $e (${e.runtimeType})");
      print("🔴 StackTrace: $s");
      return "Error: Unexpected error during Gemini content generation: $e";
    }
  }

  /// 🖼️ Generates an image using Google Gemini (Placeholder)
  Future<String> generateImageWithGemini(String prompt) async {
    // Log the prompt
    print("ℹ️ Gemini Image Prompt: $prompt");

    if (_geminiApiKey == null || _geminiApiKey!.isEmpty) {
      print("🔴 Gemini API Key is missing or empty for image generation.");
      return "Error: Gemini API Key is not set or is empty.";
    }
     // Log partial API Key for verification
    if (_geminiApiKey!.length > 5) {
        print("ℹ️ Using Gemini API Key (first 5 chars) for image: ${_geminiApiKey!.substring(0, 5)}...");
    } else {
        print("ℹ️ Using Gemini API Key (short key) for image: ${_geminiApiKey!}");
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
