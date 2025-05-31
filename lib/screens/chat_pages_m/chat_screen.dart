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

import '../../constant/app_color.dart'; // Keep if AppColor.primaryColor is used
// import '../../constant/app_icon.dart'; // AppIcon seems unused now
// import '../../constant/app_assets.dart'; // AppAssets seems unused now
import '../../modals/chat_message.dart'; // Unused
import '../../modals/message_model.dart';
import 'package:chat_gpt/services/ai_service.dart';
import '../../utils/app_keys.dart';
// import '../../utils/extension.dart'; // Unused
// import '../../utils/shared_prefs_utils.dart'; // Unused
import '../../widgets/app_textfield.dart';
import '../../widgets/message_bubble.dart';
import '../home_pages/home_screen.dart';
// import '../home_pages/home_screen_controller.dart'; // Unused
// import '../setting_pages/setting_page_controller.dart'; // Unused
// import 'chat_controller.dart'; // Unused

// import 'package:chat_gpt/screens/premium_pages/premium_screen.dart';// Unused
// import 'package:chat_gpt_sdk/chat_gpt_sdk.dart'; // Removed
// import 'package:flutter/services.dart'; // Unused

// import '../../widgets/message_composer.dart'; // Unused
// import '../premium_pages/premium_screen_controller.dart';// Unused


class ChatScreen extends StatefulWidget {
  final String message;

  const ChatScreen({Key? key, required this.message}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScreenshotController screenshotController = ScreenshotController();
  // final HomeScreenController homeScreenController = HomeScreenController(); // Unused
  // final ChatController chatController = Get.put(ChatController()); // Unused
  final TextEditingController messageController = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();
  final ScrollController scrollController = ScrollController();
  // final GlobalKey globalKey = GlobalKey(); // Unused

  // List<ChatMessage> _messages = [ChatMessage('Hello, how can I help?', false)]; // Unused
  List<MessageModel> messageList = [];

  bool _awaitingResponse = false;
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
    if(mounted) {
      setState(() {
        messageLimit = prefs.getInt('messageLimit') ?? maxMessageLimit;
        isVoiceOn = prefs.getBool('voice') ?? voiceOff;
      });
    }
  }

  Future<void> _storeMessage(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('messageLimit', value);
  }

  Future<void> _storeVoice(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice', value);
    if(mounted) {
      setState(() {
        isVoiceOn = value;
      });
    }
  }

  void _initializeChat() {
    _addMessage(widget.message, isUser: true);
    _sendToAPI(widget.message);
  }

  int _addMessage(String content, {required bool isUser, String? answerContent}) {
    String day = DateTime.now().day.toString();
    String month = DateTime.now().month.toString();
    String year = DateTime.now().year.toString();

    final model = MessageModel(
      message: isUser ? content : (answerContent ?? ""),
      sentByMe: isUser,
      dateTime: "$day/$month/$year",
      answer: isUser ? "" : (answerContent ?? content)
    );

    if(mounted) {
      setState(() {
        messageList.insert(0, model);
      });
    }
    _scrollToBottom();
    return messageList.isNotEmpty ? 0 : -1;
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
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

    return WillPopScope(
      onWillPop: () async {
        Get.offAll(() => const HomeScreen(), transition: Transition.rightToLeft);
        return true;
      },
      child: Screenshot(
        controller: screenshotController,
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
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
                  if (_awaitingResponse)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                           SizedBox(height: 20, width: 20, child: CircularProgressIndicator()),
                           SizedBox(width: 10),
                           Text("Loading...")
                        ],
                      ),
                    ),
                  _buildSendMessageBox(context),
                ],
              ),
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
      backgroundColor: Theme.of(context).colorScheme.background,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Get.offAll(() => const HomeScreen(), transition: Transition.rightToLeft),
        icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).textTheme.displayLarge?.color),
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
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        label: Text(
          "$messageLimit left",
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
      ),
    );
  }

  Widget _buildVoiceToggleButton() {
    return IconButton(
      onPressed: () async {
        await _storeVoice(!isVoiceOn);
        if (!isVoiceOn) await flutterTts.stop();
         showToast(text: isVoiceOn ? "voiceIsOn".tr : "voiceIsOff".tr);
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
      color: Theme.of(context).cardColor,
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
              icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
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
    _sendToAPI(input);
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
      itemCount: messageList.length,
      itemBuilder: (context, index) {
        final msg = messageList[index];
        return MessageBubble(message: msg.sentByMe ? msg.message : msg.answer, isUserMessage: msg.sentByMe);
      },
    );
  }

Future<void> _sendToAPI(String input) async {
  if (messageLimit <= 0 && messageLimit != -1) {
    Get.snackbar("Limit Reached", "You’ve reached your daily limit.");
    return;
  }

  if(mounted) setState(() => _awaitingResponse = true);
  if (messageLimit != -1) {
    messageLimit--;
    await _storeMessage(messageLimit);
  }

  String aiResponseText = "Failed to get response. Please try again.";

  try {
    final aiService = AIService();
    aiResponseText = await aiService.generateContentWithGemini(input); // Changed to Gemini

    _addMessage(input, isUser: false, answerContent: aiResponseText);

    if (isVoiceOn) await _speak(aiResponseText);

  } catch (e) {
    debugPrint("Error from AI Service: $e");
    _addMessage(input, isUser: false, answerContent: aiResponseText); // Add error message to UI
    Get.snackbar("Error", "Failed to get a response from AI.");
  } finally {
    if(mounted) setState(() => _awaitingResponse = false);
    _scrollToBottom();
  }
}

// _sendToAPI2 method removed
}
