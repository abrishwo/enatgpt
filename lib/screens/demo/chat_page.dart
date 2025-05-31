import 'dart:io';
import 'package:chat_gpt/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
// import '../../constant/app_color.dart'; // Potentially unused if colors are from theme
import '../../constant/app_icon.dart';
import '../../modals/chat_message.dart';
import '../../modals/message_model.dart';
import '../../utils/app_keys.dart';
import '../../utils/shared_prefs_utils.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/message_composer.dart';
import '../home_pages/home_screen.dart';
// import '../premium_pages/premium_screen_controller.dart'; // Unused import
// import '../setting_pages/setting_page_controller.dart'; // Unused import
import 'chat_api.dart';

class ChatPage extends StatefulWidget {

   ChatPage({required this.chatApi, super.key, required this.messag,});
  final ChatApi chatApi;
  String messag;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messages = <ChatMessage>[];
  var _awaitingResponse = false;
  ScreenshotController screenshotController = ScreenshotController();
  List<MessageModel> messageList = []; // This seems unused in the context of _messages
  bool isVoiceOn = false; // Added field

  @override
  void initState() {
    getLocalData();
    // Initial message submission
    if (widget.messag.isNotEmpty) {
      _onSubmitted(widget.messag);
      // addMessageToMessageList(widget.messag,true); // This might be redundant if _onSubmitted handles UI update
    }
    super.initState();
  }

  storeVoice(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('voice', value);
    // isVoiceOn = prefs.getBool('voice') ?? voiceOff; // This line was causing error as voiceOff is not defined here
    isVoiceOn = prefs.getBool('voice') ?? false; // Default to false if not found
    if (mounted) setState(() {});
  }

  getLocalData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // messageLimit = prefs.getInt('messageLimit') ?? maxMessageLimit; // messageLimit not defined here
    isVoiceOn = prefs.getBool('voice') ?? false; // Default to false
    // print('MessageLimit -----> $messageLimit');
    if (mounted) setState(() {});
  }

  _speak(String value) async{
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1);
    await flutterTts.speak(value);
  }

  // This method seems disconnected from the _messages list used by MessageBubble
  void addMessageToMessageList(String message, bool sentByMe) {
    String day = DateTime.now().day.toString();
    String month = DateTime.now().month.toString();
    String year = DateTime.now().year.toString();

    if (mounted) {
      setState(() {
        // If this is intended for a different list, ensure that list is used in the UI
        messageList.insert(0, MessageModel(message: message, sentByMe: sentByMe,dateTime: "$day/$month/$year",answer: message));
      });
    }
  }
  final scrollController = ScrollController(); // Unused in this specific build method

  // downScroll method was here, but scrollController for _messages list view is implicit or missing

  final FlutterTts flutterTts = FlutterTts();

  @override
  Widget build(BuildContext context) {
    return  WillPopScope(onWillPop: () async{
      Get.offAll(const HomeScreen(), transition: Transition.rightToLeft);
      return true;
    },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background, // Changed
        appBar: AppBar(
          centerTitle: true,
          title: appBarTitle(context),
          backgroundColor: Theme.of(context).colorScheme.background, // Changed
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () async {
                isVoiceOn = !isVoiceOn;
                await storeVoice(isVoiceOn);
                await flutterTts.stop();
                showToast(text: (isVoiceOn ? "voiceIsOn" : "voiceIsOff").tr);
              },
              icon: isVoiceOn == false ? AppIcon.speakerOffIcon(context) : AppIcon.speakerIcon(context),
            ),
            IconButton(
              onPressed: () async {
                await screenshotController.capture(delay: const Duration(milliseconds: 10)).then((image) async {
                  if (image != null) {
                    final directory = await getApplicationDocumentsDirectory();
                    final imagePath = await File('${directory.path}/image.png').create();
                    await imagePath.writeAsBytes(image);
                    await Share.shareFiles([imagePath.path]);
                  }
                });
              },
              icon: AppIcon.shareIcon(context),
            ),
          ],
          leading: IconButton(
              onPressed: (){
                Get.offAll(const HomeScreen(), transition: Transition.rightToLeft);
              },
              icon: Icon(Icons.arrow_back_rounded,color: Theme.of(context).textTheme.displayLarge?.color,)), // Changed
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder( // Added ListView.builder
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return MessageBubble(
                    message: msg.content,
                    isUserMessage: msg.isUserMessage,
                  );
                },
              ),
            ),
            MessageComposer(
              onSubmitted: _onSubmitted,
              awaitingResponse: _awaitingResponse,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSubmitted(String message) async {
    String day = DateTime.now().day.toString();
    String month = DateTime.now().month.toString();
    String year = DateTime.now().year.toString();

    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(message, true));
        _awaitingResponse = true;
      });
    }

    try {
      final response = await widget.chatApi.completeChat(_messages); // Pass current _messages
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(response, false));
          _awaitingResponse = false;
        });
        // Storing chat needs to be adapted if _messages is the source of truth
        await SharedPrefsUtils.storeChat(
            chat: message, // The user's message
            sentByMe: false, // This should be true for user message, false for AI response
            dateTime: "$day/$month/$year",
            answer: response);
        if (isVoiceOn) _speak(response);
      }
    }
    catch (err) {
      if (mounted) {
        setState(() {
          _awaitingResponse = false;
          // Optionally add an error message to chat
          _messages.add(ChatMessage("Error: Could not get response.", false));
        });
      }
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('An error occurred. Please try again.')),
      // );
    }
  }
}
