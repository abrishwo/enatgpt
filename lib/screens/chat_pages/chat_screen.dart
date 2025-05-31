// ignore_for_file: unrelated_type_equality_checks, use_build_context_synchronously
import 'package:chat_gpt/screens/premium_pages/premium_screen.dart';
import 'package:chat_gpt/utils/app_keys.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
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
import '../../modals/chat_message.dart';
import '../../modals/message_model.dart';
import 'package:chat_gpt/services/ai_service.dart';
import '../../utils/shared_prefs_utils.dart';
import '../../widgets/app_textfield.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/message_composer.dart';
import '../home_pages/home_screen.dart';
import '../home_pages/home_screen_controller.dart';
import '../premium_pages/premium_screen_controller.dart';
import '../setting_pages/setting_page_controller.dart';
import 'chat_controller.dart';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';


enum TtsState {playing, stopped, paused, continued}


class ChatScreen extends StatefulWidget {
  String message;

  ChatScreen({Key? key,required this.message}) : super(key: key);


  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  ScreenshotController screenshotController = ScreenshotController();
  HomeScreenController homeScreenController = HomeScreenController();
  //PremiumScreenController premiumScreenController = Get.put(PremiumScreenController());
  int messageLimit = maxMessageLimit;

  final _messages = <ChatMessage>[
    ChatMessage('Hello, how can I help?', false),
  ];

  var _awaitingResponse = false;

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


  storeVoice(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('voice', value);
    isVoiceOn = prefs.getBool('voice') ?? voiceOff;
    setState(() {});
  }




  @override
  void initState() {

    getLocalData();
    addMessageToMessageList(widget.message,true);
    sendMessageToAPI(widget.message);
    // TODO: implement initState
    super.initState();
  }

  final FlutterTts flutterTts = FlutterTts();


  ChatController chatController = Get.put(ChatController());
  TextEditingController messageController = TextEditingController();
  List<MessageModel> messageList = [];
  bool inProgress = true;

  final openAI = OpenAI.instance.build(
        token: openAiToken,
        baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 12),
        connectTimeout: const Duration(seconds: 12),
        sendTimeout: const Duration(seconds: 12),
      ),
      //isLog: true,
  );

  _speak(String value) async{
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1);
    await flutterTts.speak(value);
  }


  @override
  void dispose() {
    messageController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  // ScrollController scrollController =  ScrollController();
  final scrollController = ScrollController();


  downScroll() {
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration:  const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  GlobalKey globalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {

    final BannerAd myBanner = BannerAd(
      adUnitId: Platform.isAndroid ? bannerAndroidID : bannerIOSID,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    );
    myBanner.load();
    final AdWidget adWidget = AdWidget(ad: myBanner);
    final Container adContainer = Container(
      alignment: Alignment.center,
      width: myBanner.size.width.toDouble(),
      height: myBanner.size.height.toDouble(),
      child: adWidget, // myBanner.size.height.toDouble(),
    );

    return WillPopScope(
      onWillPop: () async {
        Get.offAll(const HomeScreen(), transition: Transition.rightToLeft);
        return true;
      },
      child: Screenshot(
        controller: screenshotController,
        child: Scaffold(
          backgroundColor: context.theme.backgroundColor,
          appBar: AppBar(
            centerTitle: true,
            title: appBarTitle(context),
            backgroundColor: context.theme.backgroundColor,
            elevation: 0,
            actions: [
              adsOff == true  ? Container() : GestureDetector(
                onTap: (){
                  showModalBottomSheet(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      backgroundColor: Colors.white,
                    context: context, builder: (BuildContext context) {
                        return Container(
                          height: 170,
                          color: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              15.0.addHSpace(),
                              AppIcon.infoIcon(),
                              20.0.addHSpace(),
                              Text("Messages function as the credit system for Message. One request to Message deducts one message from your balance. You will be granted $maxMessageLimit wishes daily",style: TextStyle(color: Colors.black,fontWeight: FontWeight.w500,fontSize: 15),).marginSymmetric(horizontal: 12),
                            ],
                          ),
                        );
                  },

                  );
                },
                child: Container(
                  height: 30,
                  width: 50,
                  decoration: BoxDecoration(color: AppColor.greenColor,borderRadius: BorderRadius.circular(75)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("$messageLimit",style: TextStyle(color: Colors.white),),
                      AppIcon.starIcon()
                    ],
                  ),
                ).marginSymmetric(vertical: 10),
              ),

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

          body: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                      child: messageList.isEmpty
                          ? const Center(
                        child: Text(
                          "",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 28),
                        ),
                      )
                          : buildMessageListWidget()),
                ],
              ),
              buildSendWidget(),
              // premiumScreenController.isPremium == true || adsOff == true  ? Container() :  adContainer,
            ],
          ),
          // body: Column(
          //   children: [
          //     Expanded(
          //       child: ListView(
          //         children: [
          //           ..._messages.map(
          //                 (msg) => MessageBubble(
          //               content: msg.content,
          //               isUserMessage: msg.isUserMessage,
          //             ),
          //
          //           ),
          //         ],
          //       ),
          //     ),
          //     MessageComposer(
          //       onSubmitted: _onSubmitted,
          //       awaitingResponse: _awaitingResponse,
          //     ),
          //   ],
          // ),
        ),
      ),
    );
  }

  Widget buildSendWidget() {
    return  Container(
        height: 55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: context.isDarkMode == false ?  const  Color(0xffEDEDED) : Colors.white,
        ),
        child: Row(
          children: [
            Expanded(
                child: AppTextField(
                  controller: messageController,
                  maxLines: 1,
                  onTap: () {
                    downScroll();
                  },
                )
            ),
            IconButton(
                onPressed: () async {
                  await flutterTts.stop();
                  hideKeyboard(context);
                  String question = messageController.text.toString() ?? "Hello";
                  if (question.isEmpty) return;
                  addMessageToMessageList(question, true);
                  sendMessageToAPI(question);
                  setState(() {});
                  messageController.clear();
                  // downScroll();
                  // await getLocalData();
                  // await flutterTts.stop();
                  // messageLimit == -1 ? null :  messageLimit--;
                  // setState(() {});
                  // storeMessage(messageLimit);
                  //
                  //   hideKeyboard(context);
                  //
                  //
                  //   //String question = messageController.text.toString();
                  //   String question = messageController.text.toString();
                  //   if (question.isEmpty) return;
                  //   addMessageToMessageList(question, true);
                  //   sendMessageToAPI(question);
                  //   setState(() {});
                  //   messageController.clear();
                  //
                  //
                  //
                  //     hideKeyboard(context);
                  //    // String question = messageController.text.toString();
                  //     String question = messageController.text.toString();
                  //
                  //
                  //     if (question.isEmpty) return;
                  //     addMessageToMessageList(question, true);
                  //     sendMessageToAPI(question);
                  //     setState(() {});
                  //     messageController.clear();

                },
                icon: const Icon(Icons.send,color: Color(0xffABAABA),))
          ],
        )
    ).marginOnly(left: 15,right: 15,bottom: 50);
  }



  Widget buildMessageListWidget() {
    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.all(10), margin: messageList[index].sentByMe
                  ?
              const EdgeInsets.only(left: 50)
                  :
              const EdgeInsets.only(right: 50),
                child: Align(
                  alignment: messageList[index].sentByMe
                      ?
                  Alignment.topRight
                      :
                  Alignment.topLeft,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: messageList[index].sentByMe
                            ?
                        MainAxisAlignment.end
                            :
                        MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          messageList[index].sentByMe
                              ?
                        Container()
                        :
                       CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xffB2E7CA), child: Center(child: Image.asset(AppAssets.botImage)),
                       ),
                          5.0.addWSpace(),
                          Expanded(
                              child: Container(
                                 decoration: BoxDecoration(
                               borderRadius: messageList[index].sentByMe
                                  ?
                              const BorderRadius.only(topLeft: Radius.circular(20),topRight: Radius.circular(20),bottomLeft: Radius.circular(20))
                                   :
                              const BorderRadius.only(topLeft: Radius.circular(20),topRight: Radius.circular(20),bottomRight: Radius.circular(20)),
                              color: messageList[index].sentByMe ? AppColor.greenColor : context.theme.primaryColor,),
                                    padding: const EdgeInsets.all(10),
                                    child:  messageList[index].sentByMe
                                ?
                            Text(
                                messageList[index].message,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                )
                            )
                                :
                            Column(
                              children: [

                                // Text(messageList[index].answer, style: const TextStyle(fontSize: 16, color: Colors.white,)),
                                Text("Hello this is answer", style: const TextStyle(fontSize: 16, color: Colors.white,)),
                                5.0.addHSpace(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    GestureDetector(
                                      onTap : ()  async {
                                        showToast(text: 'copy'.tr);
                                        await Clipboard.setData(ClipboardData(text: messageList[index].answer));},
                                      child: const  SizedBox(
                                        height: 30,
                                        width: 30,
                                        child: Center(child: Icon(Icons.copy,color: Colors.white,)),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            )
                        ),
                      ),
                      5.0.addWSpace(),
                      messageList[index].sentByMe
                              ?
                      CircleAvatar(radius: 16,backgroundColor: const Color(0xffD8F4E5),child: Center(child: Text("me".tr,style: TextStyle(color: AppColor.greenColor,fontWeight: FontWeight.w700,fontSize: 10))),)
                              :
                      Container(),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
            reverse: true,
            itemCount: messageList.length,
          ),
          // Expanded(
          //   child: ListView(
          //     children: [
          //       ..._messages.map(
          //             (msg) => MessageBubble(
          //           content: msg.content,
          //           isUserMessage: msg.isUserMessage,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // MessageComposer(
          //   onSubmitted: _onSubmitted,
          //   awaitingResponse: _awaitingResponse,
          // ),

          if(inProgress)
            Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 16,backgroundColor: const Color(0xffB2E7CA),   child: Center(child: Image.asset(AppAssets.botImage)),) ,
              5.0.addWSpace(),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 50),
                  decoration:  BoxDecoration(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(20),topRight: Radius.circular(20),bottomRight: Radius.circular(20)),
                    color:  context.theme.primaryColor,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Lottie.asset(AppAssets.loadingFile,height: 20),
                    ],
                  ),
                ),
              ),
              5.0.addWSpace(),
              Container(),
            ],
          ),

          // 100.0.addHSpace(),

        ],
      ),
    ).marginOnly(bottom:  120);
  }

  bool isColor =  false;

//  import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';

dynamic chatComplete(String question) async {
  String data = "";
  try {
    final response = await AIService().generateContentWithGemini(question);
    print("~~~~~~~~~~~~~from AI: $response");
    data = response ?? ''; // Handle nullable
    setState(() {});
  } catch (e) {
    final request = ChatCompleteText(
      messages: [
        Messages(role: Role.user, content: question.trim()) // Use enum
      ],
      maxToken: token,
      model: Gpt4ChatModel(),
    );
    final response = await openAI.onChatCompletion(request: request);
    for (var element in response!.choices) {
      data = element.message?.content.toString() ?? "";
    }
  }
  return data;
}



  void sendMessageToAPI(String question) async {

    setState(() {
      inProgress = true;
    });

    String day = DateTime.now().day.toString();
    String month = DateTime.now().month.toString();
    String year = DateTime.now().year.toString();
    try {
      String answer = await chatComplete(question);
      await SharedPrefsUtils.storeChat(chat: messageController.text.isEmpty ? widget.message:   messageController.text , sentByMe: false,dateTime: "$day/$month/$year",answer: answer);
      addMessageToMessageList(answer, false);
      isVoiceOn == true ? _speak(answer) : null;
      setState(() {});
      Future.delayed(Duration(seconds: 1),(){
        downScroll();
      });
    } catch (e) {
      await SharedPrefsUtils.storeChat(chat: messageController.text.isEmpty ? widget.message:  messageController.text , sentByMe: false,dateTime: "$day/$month/$year",answer: 'Failed to get response please try again');
      addMessageToMessageList("Failed to get response please try again", false);
      isVoiceOn == true ? _speak("Failed to get response please try again") : null;
      setState(() {});
      Future.delayed(Duration(seconds: 1),(){
        downScroll();
      });
    }

    setState(() {
      inProgress = false;
    });
    // downScroll();

  }

  void addMessageToMessageList(String message, bool sentByMe) {

    String day = DateTime.now().day.toString();
    String month = DateTime.now().month.toString();
    String year = DateTime.now().year.toString();

    setState(() {
      messageList.insert(0, MessageModel(message: message, sentByMe: sentByMe,dateTime: "$day/$month/$year",answer: message));
    });
  }

  List<Map> chatMessages = [];




}

List<String> answerList = [];
