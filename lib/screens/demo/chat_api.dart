import 'package:dart_openai/dart_openai.dart';

import '../../modals/chat_message.dart';

class ChatApi {
  static const _model = 'gpt-3.5-turbo';

  ChatApi() {
    OpenAI.apiKey = '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';
    //OpenAI.organization = 'openAiOrg';
  }

  // Future<String> completeChat(List<ChatMessage> messages) async {
  //   final chatCompletion = await OpenAI.instance.chat.create(
  //     model: _model,
  //     messages: messages
  //         .map((n) => OpenAIChatCompletionChoiceMessageModel(
  //              //role: 'customer',
  //               role:  'assistant',
  //               content: n.content,
  //             ))
  //         .toList(),
  //   );
  //   return chatCompletion.choices.first.message.content;
  // }
  Future<String> completeChat(List<ChatMessage> messages) async {
    final chatCompletion = await OpenAI.instance.chat.create(
        model: _model,
        messages: messages
            .map((e) =>
                OpenAIChatCompletionChoiceMessageModel(role: OpenAIChatMessageRole.system,content: e.content))
            .toList());
    return chatCompletion.choices.first.message.content;
  }
}
