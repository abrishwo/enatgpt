// ignore_for_file: unrelated_type_equality_checks, use_build_context_synchronously
import 'package:chat_gpt/utils/app_keys.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:chat_gpt/constant/app_assets.dart';
import 'package:chat_gpt/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constant/app_color.dart';
import '../../constant/app_icon.dart';
import '../../modals/message_model.dart';
import 'package:chat_gpt/services/ai_service.dart';
import '../../utils/shared_prefs_utils.dart';
import '../../widgets/app_textfield.dart';
import '../../widgets/message_bubble.dart'; // Import MessageBubble
import '../home_pages/home_screen.dart';
import '../home_pages/home_screen_controller.dart';
import 'chat_controller.dart';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';

class ChatScreen extends StatefulWidget {
  final String message;

  const ChatScreen({Key? key, required this.message}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScreenshotController screenshotController = ScreenshotController();
  final HomeScreenController homeScreenController = Get.put(HomeScreenController()); // Ensure controller is put if not already
  int messageLimit = maxMessageLimit;
  bool isVoiceOn = voiceOff;

  final FlutterTts flutterTts = FlutterTts();
  final ChatController chatController = Get.put(ChatController());
  final TextEditingController messageController = TextEditingController();
  final List<MessageModel> messageList = [];
  bool inProgress = true;
  final ScrollController scrollController = ScrollController();
  final GlobalKey globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    getLocalData();
    addMessageToMessageList(widget.message, true);
    sendMessageToAPI(widget.message);
  }

  @override
  void dispose() {
    messageController.dispose();
    flutterTts.stop();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> getLocalData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    messageLimit = prefs.getInt('messageLimit') ?? maxMessageLimit;
    isVoiceOn = prefs.getBool('voice') ?? voiceOff;
    print('MessageLimit -----> $messageLimit');
    if (mounted) setState(() {});
  }

  Future<void> storeMessage(int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('messageLimit', value);
  }

  Future<void> storeVoice(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('voice', value);
    isVoiceOn = prefs.getBool('voice') ?? voiceOff;
    if (mounted) setState(() {});
  }

  Future<void> _speak(String value) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1);
    await flutterTts.speak(value);
  }

  void _downScroll() {
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

  Widget _buildMessageListWidget() {
    return ListView.builder(
      controller: scrollController,
      itemBuilder: (context, index) {
        final messageModel = messageList[index];
        final String messageContent = messageModel.sentByMe ? messageModel.message : messageModel.answer;
        // Conditionally add copy button for AI messages
        Widget? trailingWidget;
        if (!messageModel.sentByMe) {
            trailingWidget = IconButton(
                icon: const Icon(Icons.copy, color: Colors.white, size: 18),
                onPressed: () async {
                    showToast(text: 'copy'.tr);
                    await Clipboard.setData(ClipboardData(text: messageModel.answer));
                },
            );
        }

        return MessageBubble(
          message: messageContent,
          isUserMessage: messageModel.sentByMe,
          trailing: trailingWidget,
        );
      },
      reverse: true, // To keep messages at the bottom and scroll up
      itemCount: messageList.length,
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xffB2E7CA),
            child: Center(child: Image.asset(AppAssets.botImage)),
          ),
          5.0.addWSpace(),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 50), // Keep consistent with bubble alignment
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                color: Theme.of(context).colorScheme.primary,
              ),
              padding: const EdgeInsets.all(10), // Adjusted padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Lottie.asset(AppAssets.loadingFile, height: 20),
                  5.0.addWSpace(),
                  const Text("Typing...", style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> sendMessageToAPI(String question) async {
    if (mounted) {
      setState(() {
        inProgress = true;
      });
    }
    _downScroll(); // Scroll down when new message/loading starts

    String day = DateTime.now().day.toString();
    String month = DateTime.now().month.toString();
    String year = DateTime.now().year.toString();
    String answer = "Failed to get response please try again";

    try {
      answer = await AIService().generateContentWithGemini(question);
    } catch (e) {
      print("sendMessageToAPI Error: $e");
      // The error from AIService might already be user-friendly.
      // If not, use a generic one.
      answer = e.toString().toLowerCase().contains("error:") ? e.toString() : "Error: AI service failed. $e";
    } finally {
      await SharedPrefsUtils.storeChat(
          chat: question, // Use the original question
          sentByMe: false, // This seems incorrect, should be `true` for the user's message, but API response is AI
          dateTime: "$day/$month/$year",
          answer: answer);
      addMessageToMessageList(answer, false);
      if (isVoiceOn == true && answer.isNotEmpty && !answer.toLowerCase().contains("error:")) {
        _speak(answer);
      } else if (isVoiceOn == true && (answer.isEmpty || answer.toLowerCase().contains("error:"))) {
        _speak("Failed to get response please try again");
      }
      if (mounted) {
        setState(() {
          inProgress = false;
        });
      }
      _downScroll(); // Scroll down after message is received
    }
  }

  void addMessageToMessageList(String text, bool sentByMe) {
    String day = DateTime.now().day.toString();
    String month = DateTime.now().month.toString();
    String year = DateTime.now().year.toString();

    if (mounted) {
      setState(() {
        messageList.insert(
            0, // Insert at the beginning for reverse ListView
            MessageModel(
                message: sentByMe ? text : "",
                answer: sentByMe ? "" : text,
                sentByMe: sentByMe,
                dateTime: "$day/$month/$year"));
      });
    }
     _downScroll(); // Scroll down when new message is added
  }


  @override
  Widget build(BuildContext context) {
    // Banner Ad setup (keep as is or adjust if needed)
    // final BannerAd myBanner = BannerAd(...); myBanner.load();

    return WillPopScope(
      onWillPop: () async {
        Get.offAll(() => const HomeScreen(), transition: Transition.rightToLeft);
        return true;
      },
      child: Screenshot(
        controller: screenshotController,
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: AppBar(
            centerTitle: true,
            title: appBarTitle(context),
            backgroundColor: Theme.of(context).colorScheme.background,
            elevation: 0,
            actions: [
              if (adsOff == false) // Check if ads are not off
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                      backgroundColor: Colors.white,
                      context: context,
                      builder: (BuildContext context) {
                        return Container(
                          height: 170,
                          color: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              15.0.addHSpace(),
                              AppIcon.infoIcon(),
                              20.0.addHSpace(),
                              Text(
                                "Messages function as the credit system for Message. One request to Message deducts one message from your balance. You will be granted $maxMessageLimit wishes daily",
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 15),
                              ).marginSymmetric(horizontal: 12),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    height: 30,
                    width: 50, // Consider making this wider if text doesn't fit
                    decoration: BoxDecoration(color: AppColor.greenColor, borderRadius: BorderRadius.circular(75)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text("$messageLimit", style: const TextStyle(color: Colors.white)),
                        AppIcon.starIcon()
                      ],
                    ),
                  ).marginSymmetric(vertical: 10),
                ),
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
                onPressed: () {
                  Get.offAll(() => const HomeScreen(), transition: Transition.rightToLeft);
                },
                icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).textTheme.bodyLarge?.color)),
          ),
          body: Column( // Changed Stack to Column for simpler layout of list and input
            children: [
              Expanded(
                child: messageList.isEmpty && !inProgress
                    ? const Center(
                        child: Text(
                          "No messages yet. Ask something!", // Placeholder for empty chat
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      )
                    : _buildMessageListWidget(),
              ),
              if (inProgress) _buildLoadingIndicator(), // Show loading indicator below the list
              _buildSendWidget(), // Keep send widget at the bottom
            ],
          ).marginOnly(bottom: Platform.isIOS ? 20 : 10), // Adjust bottom margin for better spacing
        ),
      ),
    );
  }

  Widget _buildSendWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0), // Added padding
      color: Theme.of(context).colorScheme.background, // Match scaffold background
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25), // More rounded text field
                color: Theme.of(context).brightness == Brightness.light ? const Color(0xffEDEDED) : Theme.of(context).colorScheme.surface, // Adjusted color
              ),
              child: AppTextField(
                controller: messageController,
                hintText: "Type a message...", // Added hint text
                maxLines: 5, // Allow more lines for input
                minLines: 1,
                onTap: _downScroll,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () async {
              await flutterTts.stop();
              hideKeyboard(context);
              String question = messageController.text.trim(); // Trim whitespace
              if (question.isEmpty) return;
              addMessageToMessageList(question, true);
              sendMessageToAPI(question);
              messageController.clear();
            },
            icon: Icon(Icons.send, color: AppColor.greenColor, size: 28), // Adjusted icon color and size
          )
        ],
      ),
    );
  }
}

// Removed global answerList as it was unused.
// Removed global chatMessages as it was unused.
