import 'dart:io';
import 'package:chat_gpt/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../../constant/app_color.dart';
import '../../constant/app_icon.dart';
import '../../modals/chat_message.dart';
import '../../modals/message_model.dart';
import '../../utils/app_keys.dart';
import '../../utils/shared_prefs_utils.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/message_composer.dart';
import '../home_pages/home_screen.dart';
import '../premium_pages/premium_screen_controller.dart';
import '../setting_pages/setting_page_controller.dart';
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
  //PremiumScreenController premiumScreenController = Get.put(PremiumScreenController());
  ScreenshotController screenshotController = ScreenshotController();
  List<MessageModel> messageList = [];

  @override
  void initState() {
    //premiumScreenController.isPremium;
    getLocalData();
    _onSubmitted(widget.messag);
     addMessageToMessageList(widget.messag,true);
    // sendMessageToAPI(widget.message);
    // TODO: implement initState
    super.initState();
  }

  storeVoice(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('voice', value);
    isVoiceOn = prefs.getBool('voice') ?? voiceOff;
    setState(() {});
  }

  getLocalData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    messageLimit = prefs.getInt('messageLimit') ?? maxMessageLimit;
    isVoiceOn = prefs.getBool('voice') ?? voiceOff;
    print('MessageLimit -----> $messageLimit');
    setState(() {});
  }

  _speak(String value) async{
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1);
    await flutterTts.speak(value);
  }
  void addMessageToMessageList(String message, bool sentByMe) {

    String day = DateTime.now().day.toString();
    String month = DateTime.now().month.toString();
    String year = DateTime.now().year.toString();

    setState(() {
      messageList.insert(0, MessageModel(message: message, sentByMe: sentByMe,dateTime: "$day/$month/$year",answer: message));
    });
  }
  final scrollController = ScrollController();
  downScroll() {
  scrollController.animateTo(
  scrollController.position.maxScrollExtent,
  duration:  const Duration(milliseconds: 500),
  curve: Curves.easeInOut,
  );
}
  final FlutterTts flutterTts = FlutterTts();
  @override
  Widget build(BuildContext context) {
    return  WillPopScope(onWillPop: () async{
      Get.offAll(const HomeScreen(), transition: Transition.rightToLeft);
      return true;
    },
      child: Scaffold(
        backgroundColor: context.theme.backgroundColor,
        appBar: AppBar(
          centerTitle: true,
          title: appBarTitle(context),
          backgroundColor: context.theme.backgroundColor,
          elevation: 0,
          actions: [

         // GestureDetector(
         //            onTap: () {
         //              showModalBottomSheet(
         //                shape: RoundedRectangleBorder(
         //                  borderRadius: BorderRadius.circular(10.0),
         //                ),
         //                backgroundColor: Colors.white,
         //                context: context,
         //                builder: (BuildContext context) {
         //                  return Container(
         //                    height: 170,
         //                    color: Colors.white,
         //                    child: Column(
         //                      crossAxisAlignment: CrossAxisAlignment.center,
         //                      children: [
         //                        15.0.addHSpace(),
         //                        AppIcon.infoIcon(),
         //                        20.0.addHSpace(),
         //                        Text(
         //                          "Messages function as the credit system for Message. One request to Message deducts one message from your balance. You will be granted $maxMessageLimit wishes daily",style: TextStyle(color: Colors.black,fontWeight: FontWeight.w500,fontSize: 15),).marginSymmetric(horizontal: 12),
         //              ],
         //            ),
         //          );
         //        },
         //
         //        );
         //      },
         //      child: Container(),
         //    ),
            IconButton(
              onPressed: () async {
                isVoiceOn = !isVoiceOn;
                await storeVoice(isVoiceOn);
                getLocalData();
                setState(() {});
                await flutterTts.stop();
                isVoiceOn == true ? showToast(text: "voiceIsOn".tr) :  showToast(text: "voiceIsOff".tr);
                setState(() {});
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
                    /// Share Plugin
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
              icon: Icon(Icons.arrow_back_rounded,color: context.textTheme.headline1!.color,)),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  ..._messages.map(
                        (msg) => MessageBubble(
                      message: msg.content,
                      isUserMessage: msg.isUserMessage,
                    ),
                  ),
                ],
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
    setState(() {
      _messages.add(ChatMessage(message, true));
      _awaitingResponse = true;

    });
    try {
      final response = await widget.chatApi.completeChat(_messages);
      setState(() async {
        _messages.add(ChatMessage(response, false));
        _awaitingResponse = false;
        await SharedPrefsUtils.storeChat(chat: _messages.isEmpty ? widget.messag :   message , sentByMe: false,dateTime: "$day/$month/$year",answer: response);
        isVoiceOn == true ? _speak(response) : null;
        setState(() {});
        Future.delayed(Duration(seconds: 1),(){

        });
      });
    }
    catch (err) {

      // await SharedPrefsUtils.storeChat(chat: _messages.isEmpty ? widget.messag:  message , sentByMe: false,dateTime: "$day/$month/$year",answer: 'Failed to get response please try again');
      // addMessageToMessageList("Failed to get response please try again", false);

      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('An error occurred. Please try again.')),
      //
      // );
      setState(() {
        _awaitingResponse = false;
      });
    }
  }
}
