import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:get/get.dart'; // Added import
import 'package:chat_gpt/services/credit_service.dart'; // Added import
import 'package:firebase_analytics/firebase_analytics.dart'; // Import Firebase Analytics

class AIService {
  // final String? _geminiApiKey = dotenv.env['GEMINI_API_KEY'];
  final String? _geminiApiKey = 'AIzaSyAoIavVnP-fCmmp1PvZ355Uh8GtcMop9HY'; // TODO: Replace with actual key from .env
  final CreditService _creditService = Get.find<CreditService>(); // Added CreditService instance

  // Define credit costs
  static const double textGenerationCost = 1.0;
  static const double imageGenerationCost = 2.0; // Example cost, adjust as needed

  Future<String> generateContentWithGemini(String prompt) async {
    // Check credit balance before API key check
    final currentBalance = _creditService.currentUserCredit.value?.balance ?? 0.0;
    if (currentBalance < textGenerationCost) {
      return "Error: Insufficient credits for text generation. Required: $textGenerationCost, Available: $currentBalance";
    }

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
          return "Error: Blocked by Gemini. Reason: ${feedback.blockReason}. Message: ${feedback.blockReasonMessage}";
        }
        return "Error: Empty response from Gemini.";
      }

      // Deduct credits after successful API response
      bool deductionSuccess = await _creditService.deductCredits(textGenerationCost);
      if (!deductionSuccess) {
        // Log a critical error. The content is generated, but credit deduction failed.
        // This indicates a potential issue with credit logic or Firestore update.
        print("CRITICAL ERROR: Failed to deduct $textGenerationCost credits after successful text generation for user ${_creditService.currentUserCredit.value?.userId}. Balance was $currentBalance before this operation.");
        // Depending on policy, you might still return the content or an error.
        // For now, returning content but logging the error.
      } else {
        print("AIService: Successfully deducted $textGenerationCost credits for text generation. User: ${_creditService.currentUserCredit.value?.userId}");
        FirebaseAnalytics.instance.logEvent(
          name: 'text_generation_credits_deducted',
          parameters: {
            'credits_deducted': textGenerationCost,
            'user_id': _creditService.currentUserCredit.value?.userId ?? 'unknown_user',
          },
        );
        print("AIService: Logged text_generation_credits_deducted event.");
      }

      return response.text!;
    } on GenerativeAIException catch (e) {
      return "Error: Gemini AI generation failed. ${e.toString()}";
    } catch (e) {
      return "Error: Unexpected error: $e";
    }
  }

  Future<String> generateImageWithGemini(String prompt) async {
    // Check credit balance before API key check
    final currentBalance = _creditService.currentUserCredit.value?.balance ?? 0.0;
    if (currentBalance < imageGenerationCost) {
      return "Error: Insufficient credits for image generation. Required: $imageGenerationCost, Available: $currentBalance";
    }

    if (_geminiApiKey == null || _geminiApiKey!.isEmpty) {
      return "Error: Gemini API Key is not set or is empty.";
    }

    try {
      // Simulate image generation cost and process as if it's a text response for now
      // Replace with actual image generation model when available/integrated
      final model = GenerativeModel(
        model: 'gemini-1.5-flash', // This model is for text, use appropriate image model
        apiKey: _geminiApiKey!,
      );

      // Construct a prompt suitable for image generation description if needed
      final imagePrompt = "Generate a descriptive text for an image based on the following idea: $prompt";
      final content = [
        Content('user', [TextPart(imagePrompt)]) // Or just use `prompt` if the model handles it
      ];

      final response = await model.generateContent(content); // This will be a text response

      // Assuming a successful response means we got a text description for the image
      if (response.text != null && response.text!.isNotEmpty) {
        // Deduct credits after successful API response (simulated image generation)
        bool deductionSuccess = await _creditService.deductCredits(imageGenerationCost);
        if (!deductionSuccess) {
          print("CRITICAL ERROR: Failed to deduct $imageGenerationCost credits after successful image generation (simulated) for user ${_creditService.currentUserCredit.value?.userId}. Balance was $currentBalance before this operation.");
        } else {
          print("AIService: Successfully deducted $imageGenerationCost credits for image generation (simulated). User: ${_creditService.currentUserCredit.value?.userId}");
          FirebaseAnalytics.instance.logEvent(
            name: 'image_generation_credits_deducted',
            parameters: {
              'credits_deducted': imageGenerationCost,
              'user_id': _creditService.currentUserCredit.value?.userId ?? 'unknown_user',
            },
          );
          print("AIService: Logged image_generation_credits_deducted event.");
        }
        // Return the simulated image description
        return "🖼️ Gemini (simulated image description): ${response.text}";
      }

      if (response.promptFeedback?.blockReason != null) {
        return "Error: Blocked by Gemini. Reason: ${response.promptFeedback!.blockReason}";
      }

      return "Error: No image content returned from Gemini (simulated).";
    } catch (e) {
      return "Error: Failed to generate image content with Gemini (simulated). $e";
    }
  }
}
