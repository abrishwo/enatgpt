// ignore_for_file: unrelated_type_equality_checks, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';

import '../../constant/app_color.dart';
import '../../constant/app_icon.dart';
import '../../constant/app_assets.dart';
import '../../modals/chat_message.dart';
import '../../modals/message_model.dart';
import 'package:chat_gpt/services/ai_service.dart';
import '../../utils/app_keys.dart';
import '../../utils/extension.dart';
import '../../utils/shared_prefs_utils.dart';
import '../../widgets/app_textfield.dart';
import '../../widgets/message_bubble.dart';
import '../home_pages/home_screen.dart';
import '../home_pages/home_screen_controller.dart';
import '../setting_pages/setting_page_controller.dart';
import 'chat_controller.dart';

import 'package:chat_gpt/screens/premium_pages/premium_screen.dart';
// import 'package:chat_gpt/utils/app_keys.dart'; // Already imported via ai_service or app_keys
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/services.dart';

// import 'package:chat_gpt/utils/extension.dart'; // Already imported



import '../../widgets/message_composer.dart';


import '../premium_pages/premium_screen_controller.dart';



class ChatScreen extends StatefulWidget {
  final String message;

  const ChatScreen({Key? key, required this.message}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScreenshotController screenshotController = ScreenshotController();
  final HomeScreenController homeScreenController = HomeScreenController();
  final ChatController chatController = Get.put(ChatController());
  final TextEditingController messageController = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();
  final ScrollController scrollController = ScrollController();
  final GlobalKey globalKey = GlobalKey();

  List<ChatMessage> _messages = [ChatMessage('Hello, how can I help?', false)];
  List<MessageModel> messageList = [];

  bool _awaitingResponse = false;
  bool inProgress = true;
  int messageLimit = maxMessageLimit;
  bool isVoiceOn = voiceOff;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _initializeChat();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      messageLimit = prefs.getInt('messageLimit') ?? maxMessageLimit;
      isVoiceOn = prefs.getBool('voice') ?? voiceOff;
    });
  }

  Future<void> _storeMessage(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('messageLimit', value);
  }

  Future<void> _storeVoice(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice', value);
    setState(() {
      isVoiceOn = value;
    });
  }

  void _initializeChat() {
    _addMessage(widget.message, isUser: true);
    _sendToAPI(widget.message);
  }

int _addMessage(String content, {required bool isUser}) {
  String day = DateTime.now().day.toString();
  String month = DateTime.now().month.toString();
  String year = DateTime.now().year.toString();

  final model = MessageModel(
    message: isUser ? content : "",
    sentByMe: isUser,
    dateTime: "$day/$month/$year",
    answer: isUser ? "" : content
  );

  setState(() {
    messageList.add(model);
  });

  return messageList.length - 1;
}

  void _addMessage2(String content, {required bool isUser}) {

    String day = DateTime.now().day.toString();
    String month = DateTime.now().month.toString();
    String year = DateTime.now().year.toString();
    setState(() {
      messageList.add(MessageModel(message: content, sentByMe: isUser, dateTime: "$day/$month/$year", answer: "loading..."));
    });
  }

  Future<void> _speak(String value) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1);
    await flutterTts.speak(value);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    flutterTts.stop();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BannerAd myBanner = BannerAd(
      adUnitId: Platform.isAndroid ? bannerAndroidID : bannerIOSID,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    )..load();

    final adWidget = AdWidget(ad: myBanner);
    final adContainer = Container(
      alignment: Alignment.center,
      width: myBanner.size.width.toDouble(),
      height: myBanner.size.height.toDouble(),
      child: adWidget,
    );

    return WillPopScope(
      onWillPop: () async {
        Get.offAll(const HomeScreen(), transition: Transition.rightToLeft);
        return true;
      },
      child: Screenshot(
        controller: screenshotController,
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background, // Changed
          appBar: _buildAppBar(context),
          body: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Column(
                children: [
                  Expanded(
                    child: messageList.isEmpty
                        ? const Center(child: Text("No messages yet"))
                        : _buildMessageList(),
                  ),
                ],
              ),
              _buildSendMessageBox(context),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      centerTitle: true,
      title: appBarTitle(context),
      backgroundColor: Theme.of(context).colorScheme.background, // Changed
      elevation: 0,
      leading: IconButton(
        onPressed: () => Get.offAll(const HomeScreen(), transition: Transition.rightToLeft),
        icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).textTheme.displayLarge?.color), // Changed
      ),
      actions: [
        _buildMessageCounterButton(context),
        _buildVoiceToggleButton(),
        _buildScreenshotButton(),
      ],
    );
  }

  Widget _buildMessageCounterButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Chip(
        backgroundColor: AppColor.primaryColor, // This might need to be Theme.of(context).colorScheme.primaryContainer or similar
        label: Text(
          "$messageLimit left",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white), // Changed from caption
        ),
      ),
    );
  }

  Widget _buildVoiceToggleButton() {
    return IconButton(
      onPressed: () {
        setState(() => isVoiceOn = !isVoiceOn);
        _storeVoice(isVoiceOn);
      },
      icon: Icon(
        isVoiceOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
        color: isVoiceOn ? Colors.green : Colors.grey,
      ),
    );
  }

  Widget _buildScreenshotButton() {
    return IconButton(
      onPressed: _takeScreenshot,
      icon: const Icon(Icons.share),
    );
  }

  Future<void> _takeScreenshot() async {
    final image = await screenshotController.capture();
    if (image == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final imagePath = await File('${directory.path}/chat.png').create();
    await imagePath.writeAsBytes(image);

    await Share.shareFiles([imagePath.path]);
  }

  Widget _buildSendMessageBox(BuildContext context) {
    return Container(
      // color: context.theme.cardColor, // This was an error before, cardColor is not on ThemeData directly
      color: Theme.of(context).cardColor, // Correct way to access cardColor
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: messageController,
                hintText: "Type a message...",
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: _awaitingResponse ? null : _onSendPressed,
              icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary), // Changed
            ),
          ],
        ),
      ),
    );
  }

  void _onSendPressed() {
    final input = messageController.text.trim();
    if (input.isEmpty || _awaitingResponse) return;

    _addMessage(input, isUser: true);
    messageController.clear();
    _scrollToBottom();
    _sendToAPI(input);
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
      itemCount: messageList.length,
      itemBuilder: (context, index) {
        final msg = messageList[index];
        // Assuming MessageBubble is updated or uses standard Material widgets that adapt to Theme
        return MessageBubble(message: msg.sentByMe ? msg.message : msg.answer, isUserMessage: msg.sentByMe);

      },
    );
  }

Future<void> _sendToAPI(String input) async {
  if (messageLimit <= 0) {
    Get.snackbar("Limit Reached", "You’ve reached your daily limit.");
    return;
  }

  setState(() {
    _awaitingResponse = true;
    messageLimit--;
  });
  _storeMessage(messageLimit);

  final responseIndex = _addMessage("...", isUser: false);

  try {
    final chatGptApi = AIService();
    final response = await chatGptApi.getChatResponse(input); // Assuming getChatResponse is the desired OpenAI method here

    if (response != null) {
      print("opeai: $response");
      setState(() {
        if (responseIndex >= 0 && responseIndex < messageList.length) {
            messageList[responseIndex].answer = response;
        }
      });

      _scrollToBottom();
      if (isVoiceOn) await _speak(response);
    } else {
        if (responseIndex >= 0 && responseIndex < messageList.length) {
            messageList[responseIndex].answer = "Failed to get response.";
        }
    }
  } catch (e) {
    debugPrint("Error from OpenAI: $e");
    if (responseIndex >= 0 && responseIndex < messageList.length) {
        messageList[responseIndex].answer = "Error: Exception occurred.";
    }
    Get.snackbar("Error", "Failed to get a response.");
  } finally {
    setState(() => _awaitingResponse = false);
  }
}

  Future<void> _sendToAPI2(String input) async {
    if (messageLimit <= 0) {
      Get.snackbar("Limit Reached", "You’ve reached your daily limit.");
      return;
    }

    setState(() {
      _awaitingResponse = true;
      messageLimit--;
    });
    _storeMessage(messageLimit);
    final responseIndex = _addMessage("...", isUser: false);

    try {
      final chatGptApi = AIService();
      final response = await chatGptApi.getChatResponse(input); // Assuming getChatResponse is the desired OpenAI method here

      if (response != null) {
         setState(() {
            if (responseIndex >= 0 && responseIndex < messageList.length) {
                messageList[responseIndex].answer = response;
            }
        });
        print("opeai: $response");
        _scrollToBottom();

        if (isVoiceOn) await _speak(response);
      } else {
        if (responseIndex >= 0 && responseIndex < messageList.length) {
            messageList[responseIndex].answer = "Failed to get response.";
        }
      }
    } catch (e) {
      debugPrint("Error from OpenAI: $e");
      if (responseIndex >= 0 && responseIndex < messageList.length) {
            messageList[responseIndex].answer = "Error: Exception occurred.";
      }
      Get.snackbar("Error", "Failed to get a response.");
    } finally {
      setState(() => _awaitingResponse = false);
    }
  }
}
