import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  // final String? _geminiApiKey = dotenv.env['GEMINI_API_KEY'];
  final String? _geminiApiKey = 'AIzaSyAoIavVnP-fCmmp1PvZ355Uh8GtcMop9HY';


  Future<String> generateContentWithGemini(String prompt) async {
    if (_geminiApiKey == null || _geminiApiKey!.isEmpty) {
      return "Error: Gemini API Key is not set or is empty.";
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _geminiApiKey!,
      );

      final content = [
        Content('user', [TextPart(prompt)])
      ];

      final response = await model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        final feedback = response.promptFeedback;
        if (feedback?.blockReason != null) {
          return "Error: Blocked by Gemini. Reason: ${feedback!.blockReason}. Message: ${feedback.blockReasonMessage}";
        }
        return "Error: Empty response from Gemini.";
      }

      return response.text!;
    } on GenerativeAIException catch (e) {
      return "Error: Gemini AI generation failed. ${e.toString()}";
    } catch (e) {
      return "Error: Unexpected error: $e";
    }
  }

 Future<String> generateImageWithGemini(String prompt) async {
  if (_geminiApiKey == null || _geminiApiKey!.isEmpty) {
    return "Error: Gemini API Key is not set or is empty.";
  }

  try {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash', // Use 'gemini-pro-vision' when image support is confirmed
      apiKey: _geminiApiKey!,
    );

    final content = [
      Content('user', [TextPart(prompt)])
    ];

    final response = await model.generateContent(content);

    if (response.text != null && response.text!.isNotEmpty) {
      return "🖼️ Gemini (simulated image description): ${response.text}";
    }

    if (response.promptFeedback?.blockReason != null) {
      return "Error: Blocked by Gemini. Reason: ${response.promptFeedback!.blockReason}";
    }

    return "Error: No image content returned from Gemini.";
  } catch (e) {
    return "Error: Failed to generate image content with Gemini. $e";
  }
}

}
