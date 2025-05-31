import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// import '../screens/home_pages/home_screen.dart'; // Unused import
// import '../screens/setting_pages/setting_page_controller.dart'; // Unused import
import '../utils/app_keys.dart'; // For maxMessageLimit and voiceOff

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
  final scrollController = ScrollController(); // This seems unused in this widget's build
  final FlutterTts flutterTts = FlutterTts(); // This seems unused in this widget's build

  // Added fields and initialized them
  int messageLimit = maxMessageLimit;
  bool isVoiceOn = voiceOff;

  @override
  void initState() { // Added initState to load initial values
    super.initState();
    getLocalData();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      // color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.05), // This was the original
      color: Theme.of(context).colorScheme.surface.withOpacity(0.05), // Using surface as secondaryContainer is not always defined robustly
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: !widget.awaitingResponse
                  ? TextField(
                      onTap: () {
                       // downScroll(); // scrollController is not attached to a Scrollable here
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
                      // await getLocalData(); // Called in initState, and messageLimit is decremented locally
                      if (messageLimit == -1) { // Check if limit is exhausted (assuming -1 means exhausted)
                        // Optionally show a message or prevent sending
                        print("Message limit exhausted.");
                        // Consider showing a toast or dialog: showToast(text: "Message limit reached");
                        return;
                      }

                      if (messageLimit > 0) { // Only decrement if it's positive
                        messageLimit--;
                      }

                      await storeMessage(messageLimit); // Store the new limit

                      widget.onSubmitted(_messageController.text);
                      _messageController.clear();
                      // setState(() {}); // onSubmitted should trigger state update in parent if needed
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
    print('MessageComposer - MessageLimit -----> $messageLimit, VoiceOn: $isVoiceOn');
    if (mounted) setState(() {});
  }

  storeMessage(int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('messageLimit', value);
  }

  // downScroll seems unused as scrollController is not attached to a scrollable widget here
  // downScroll() {
  //   if (scrollController.hasClients) { // Add client check
  //     scrollController.animateTo(
  //       scrollController.position.maxScrollExtent,
  //       duration: const Duration(milliseconds: 500),
  //       curve: Curves.easeInOut,
  //     );
  //   }
  // }
}
