import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chat_gpt/utils/app_keys.dart';

class ChatGptApi {
  final String _baseUrl = "https://api.openai.com/v1";

  /// ✅ Fetches ChatGPT Text Response
  Future<String?> getChatResponse(String message) async {
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
      print("🔵 Sending request to OpenAI...");
      var response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(body),
      );

      print("🟡 Response Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print("🟢 Raw API response: $data");

        String? chatResponse = data['choices'][0]['message']?['content']?.toString().trim();
        print("✅ Parsed ChatGPT Response: $chatResponse");
        return chatResponse ?? "❗ No content in response.";
      } else {
        print("🔴 API Error ${response.statusCode}: ${response.body}");
        return "❌ API Error: ${response.statusCode}";
      }
    } catch (e) {
      print("🔴 Exception occurred: $e");
      return "❌ Exception: $e";
    }
  }

  /// ✅ Fetches AI-generated Image from OpenAI
  Future<String> getImageFromChatGpt(String message, {required String? size}) async {
    try {
      print("🔵 Sending image generation request...");
      var response = await http.post(
        Uri.parse("$_baseUrl/images/generations"),
        headers: {
          "Authorization": "Bearer $openAiToken",
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"prompt": message, "size": size ?? "256x256", "n": 1}),
      );

      print("🟡 Image API response code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final imageUrl = jsonDecode(response.body)["data"][0]["url"];
        print("🖼️ Image URL: $imageUrl");
        return imageUrl;
      } else {
        print("🔴 Image API Error ${response.statusCode}: ${response.body}");
        return "";
      }
    } catch (e) {
      print("🔴 Exception during image generation: $e");
      return "";
    }
  }
}
