import 'package:dart_openai/dart_openai.dart';

import '../../modals/chat_message.dart';

class ChatApi {
  static const _model = 'gpt-3.5-turbo';

  ChatApi() {
    // OpenAI.apiKey = 'YOUR_OPENAI_API_KEY'; // TODO: Add your API key here for the demo to work
    //OpenAI.organization = 'openAiOrg';
  }

  Future<String> completeChat(List<ChatMessage> messages) async {
    final chatCompletion = await OpenAI.instance.chat.create(
        model: _model,
        messages: messages
            .map((e) =>
                OpenAIChatCompletionChoiceMessageModel(
                  role: OpenAIChatMessageRole.user, // Changed from system to user for typical chat flow
                  content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(e.content)],
                ))
            .toList());

    final message = chatCompletion.choices.first.message;
    if (message.content != null && message.content!.isNotEmpty) {
      final textContent = message.content!
          .where((item) => item.type == "text")
          .map((item) => item.text)
          .join();
      return textContent;
    }
    return ""; // Return empty string if no text content
  }
}
