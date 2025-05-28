// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:chat_gpt/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constant/app_assets.dart';
import '../../constant/app_color.dart';
import '../../constant/app_icon.dart';
import '../../modals/message_model.dart';
import '../../utils/app_keys.dart';
import '../../utils/shared_prefs_utils.dart';
import '../../widgets/app_textfield.dart';
import '../history_pages/history_screen.dart';
import '../home_pages/home_screen.dart';
import '../home_pages/home_screen_controller.dart';
import '../setting_pages/setting_page_controller.dart';
import 'history_chat_controller.dart';

class HistoryChatViewScreen extends StatefulWidget {
  final bool historyPage;
  final String? question;
  final String? answer;

  const HistoryChatViewScreen({
    Key? key,
    this.answer,
    this.question,
    required this.historyPage,
  }) : super(key: key);

  @override
  State<HistoryChatViewScreen> createState() => _HistoryChatViewScreenState();
}

class _HistoryChatViewScreenState extends State<HistoryChatViewScreen> {
  final historyController = Get.put(HistoryChatController());
  final homeScreenController = Get.put(HomeScreenController());
  final FlutterTts flutterTts = FlutterTts();
  final scrollController = ScrollController();
  final TextEditingController messageController = TextEditingController();
  List<MessageModel> messageList = [];
  bool isVoiceOn = false;
  int messageLimit = maxMessageLimit;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      messageLimit = prefs.getInt('messageLimit') ?? maxMessageLimit;
      isVoiceOn = prefs.getBool('voice') ?? false;
    });
  }

  Future<void> _toggleVoice() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isVoiceOn = !isVoiceOn;
      prefs.setBool('voice', isVoiceOn);
    });
    if (!isVoiceOn) await flutterTts.stop();
    showToast(text: isVoiceOn ? "voiceIsOn".tr : "voiceIsOff".tr);
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1);
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    flutterTts.stop();
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
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

  Widget _buildChatBubble(String message, bool isMe) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isMe)
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xffB2E7CA),
            child: Image.asset(AppAssets.botImage),
          ),
        const SizedBox(width: 5),
        Flexible(
          child: Container(
            margin: EdgeInsets.only(
              left: isMe ? 50 : 10,
              right: isMe ? 10 : 50,
              bottom: 10,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? AppColor.greenColor : context.theme.primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        if (isMe)
          const SizedBox(width: 5),
        if (isMe)
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xffD8F4E5),
            child: Text("Me", style: TextStyle(fontSize: 10)),
          ),
      ],
    );
  }

  Widget _buildMainChat() {
    return Column(
      children: [
        if (widget.question?.isNotEmpty ?? false)
          _buildChatBubble(widget.question!, true),
        if (widget.answer?.isNotEmpty ?? false)
          _buildChatBubble(widget.answer!, false),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: messageList.length,
          itemBuilder: (context, index) {
            final msg = messageList[index];
            return _buildChatBubble(msg.message, msg.sentByMe);
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final BannerAd bannerAd = BannerAd(
      adUnitId: Platform.isAndroid ? bannerAndroidID : bannerIOSID,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    )..load();

    return WillPopScope(
      onWillPop: () async {
        Get.offAll(widget.historyPage ? const HistoryScreen() : const HomeScreen());
        return true;
      },
      child: Scaffold(
        backgroundColor: context.theme.backgroundColor,
        appBar: AppBar(
          backgroundColor: context.theme.backgroundColor,
          elevation: 0,
          centerTitle: true,
          title: appBarTitle(context).marginOnly(left: 50),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: context.textTheme.headline1?.color),
            onPressed: () => Get.offAll(widget.historyPage ? const HistoryScreen() : const HomeScreen()),
          ),
          actions: [
            IconButton(
              icon: isVoiceOn ? AppIcon.speakerIcon(context) : AppIcon.speakerOffIcon(context),
              onPressed: _toggleVoice,
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _buildMainChat(),
              ),
            ),
            Container(
              alignment: Alignment.center,
              width: bannerAd.size.width.toDouble(),
              height: bannerAd.size.height.toDouble(),
              child: AdWidget(ad: bannerAd),
            ),
          ],
        ),
      ),
    );
  }
}
