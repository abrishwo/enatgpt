import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/home_pages/home_screen.dart';
import '../screens/setting_pages/setting_page_controller.dart';
import '../utils/app_keys.dart';

class MessageComposer extends StatefulWidget {
  MessageComposer({
    required this.onSubmitted,
    required this.awaitingResponse,
    super.key,
  });

  final void Function(String) onSubmitted;
  final bool awaitingResponse;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final TextEditingController _messageController = TextEditingController();
  final scrollController = ScrollController();
  final FlutterTts flutterTts = FlutterTts();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.05),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: !widget.awaitingResponse
                  ? TextField(
                      onTap: () {
                       // downScroll();
                      },
                      controller: _messageController,
                      onSubmitted: widget.onSubmitted,
                      decoration: const InputDecoration(
                        hintText: 'Write your message here...',
                        border: InputBorder.none,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(),
                        ),
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Fetching response...'),
                        ),
                      ],
                    ),
            ),
            IconButton(
              onPressed: !widget.awaitingResponse
                  ? () async {

                      await getLocalData();
                      // await flutterTts.stop();
                      messageLimit == -1 ? null : messageLimit--;
                      setState(() {});
                      storeMessage(messageLimit);
                      widget.onSubmitted(_messageController.text);

                      setState(() {});
                      _messageController.clear();

                    }

                  : null,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  getLocalData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    messageLimit = prefs.getInt('messageLimit') ?? maxMessageLimit;
    isVoiceOn = prefs.getBool('voice') ?? voiceOff;
    print('MessageLimit -----> $messageLimit');
    setState(() {});
  }

  storeMessage(int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('messageLimit', value);
  }

  downScroll() {
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
}
