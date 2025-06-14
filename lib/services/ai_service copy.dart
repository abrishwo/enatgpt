import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'package:google_generative_ai/google_generative_ai.dart'; // Import Gemini

class AIService {
  // Retrieve Gemini API key from .env, allow it to be null
  // final String? _geminiApiKey = dotenv.env['GEMINI_API_KEY'];
  // final String? _geminiApiKey = dotenv.env['GEMINI_API_KEY'];
final String? _geminiApiKey = 'AIzaSyAoIavVnP-fCmmp1PvZ355Uh8GtcMop9HY';

  /// ✨ Generates content using Google Gemini Flash
  Future<String> generateContentWithGemini(String prompt) async {
    print("ℹ️ Gemini Prompt: $prompt");

    if (_geminiApiKey == null || _geminiApiKey!.isEmpty) {
      print("🔴 Gemini API Key is missing or empty.");
      return "Error: Gemini API Key is not set or is empty. Please ensure it is configured in your .env file.";
    }

    if (_geminiApiKey!.length > 5) {
      print("ℹ️ Using Gemini API Key (first 5 chars): ${_geminiApiKey!.substring(0, 5)}...");
    } else {
      print("ℹ️ Using Gemini API Key (short key): ${_geminiApiKey!}");
    }

    try {
      print("🔵 Sending request to Gemini (generateContentWithGemini)...");
      // Use the Gemini Flash model instead of Pro
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _geminiApiKey!);
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text != null) {
        print("🟢 Raw API response (Gemini): ${response.text}");
      } else {
        print("🟡 Gemini response text is null.");
      }

      if (response.text == null || response.text!.isEmpty) {
        print("🔴 Gemini response text is null or empty after check.");
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
    } on GenerativeAIException catch (e) {
      print("🔴 Gemini GenerativeAIException: $e (${e.runtimeType})");
      String message = e.toString();
      return "Error: AI content generation failed (Gemini). Details: $message";
    } catch (e, s) {
      print("🔴 Unexpected Exception occurred (Gemini): $e (${e.runtimeType})");
      print("🔴 StackTrace: $s");
      return "Error: Unexpected error during Gemini content generation: $e";
    }
  }

  /// 🖼️ Generates an image using Google Gemini (Placeholder)
  Future<String> generateImageWithGemini(String prompt) async {
    print("ℹ️ Gemini Image Prompt: $prompt");

    if (_geminiApiKey == null || _geminiApiKey!.isEmpty) {
      print("🔴 Gemini API Key is missing or empty for image generation.");
      return "Error: Gemini API Key is not set or is empty.";
    }
    if (_geminiApiKey!.length > 5) {
      print("ℹ️ Using Gemini API Key (first 5 chars) for image: ${_geminiApiKey!.substring(0, 5)}...");
    } else {
      print("ℹ️ Using Gemini API Key (short key) for image: ${_geminiApiKey!}");
    }

    print("🔵 Sending image generation request to Gemini (generateImageWithGemini)...");
    print("⚠️ Image generation with Gemini Pro/Vision is not directly supported by returning URLs in this way.");
    print("⚠️ This method is a placeholder and will return a mock message.");
    return Future.value("Placeholder: Gemini image generation feature is under development. Prompt: '$prompt'");
  }
}