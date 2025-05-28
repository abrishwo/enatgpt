import 'dart:convert';

import 'package:chat_gpt/utils/app_keys.dart';
import 'package:http/http.dart' as http;





class ChatGptApi {


Future<String> chatComplete(String question) async {
  const apiKey = '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';

  final url = Uri.parse('https://api.openai.com/v1/chat/completions');
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey',
  };
  final body = jsonEncode({
    "model": "gpt-4o-mini",
    "store": true,
    "messages": [
      {"role": "user", "content": question.trim()}
    ]
  });

  try {
    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
       print("~~~~~~~AI: $content");
      return content.toString().trim();
    } else {
      print("Failed: ${response.statusCode} - ${response.body}");
      return 'Error: ${response.statusCode}';
    }
  } catch (e) {
    print("Exception: $e");
    return 'Error: $e';
  }
}


  getImageFromChatGpt(String message,{required String? size}) async {

    try {
      http.Response response = await http.post(
          Uri.parse("https://api.openai.com/v1/images/generations"),
          headers: {
            "Authorization": "Bearer $openAiToken",
            'Content-Type': 'application/json',
          },
          body: jsonEncode({"prompt": message,"size" : size,"n": 1,}));
      return jsonDecode(response. body)["data"][0]["url"] as String;
    } catch (e) {
      print("Error  is  -----> $e");
      return "";
    }
  }


  Future<String> getChatResponse(String message) async {
    String endpoint = 'https://api.openai.com/v1/engines/gpt-3.5-turbo/completions';

    Map<String,String> headers = {
      'Authorization': 'Bearer $openAiToken',
      'Content-Type': 'application/json',
     // 'openAiOrg ':'YOUR_ORGANIZATION_ID',
    };

    Map<String, dynamic> body = {
      'prompt': message,
      'max_tokens': 200,
    };


    var response = await http.post(Uri.parse(endpoint), headers: headers, body: jsonEncode(body));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      String chatResponse = data['choices'][0]['text'];
      print("chatResponse -=-------> $chatResponse");
      return chatResponse;
    } else {
      print(response.statusCode);
      print(response.body);
      throw Exception('Failed to get chat response');
    }
  }
}