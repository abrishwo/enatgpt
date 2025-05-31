// import 'dart:convert'; // Unused
import 'dart:io';
// import 'package:chat_gpt_sdk/chat_gpt_sdk.dart'; // Removed
// import 'package:http/http.dart' as http; // Unused
import 'package:chat_gpt/constant/app_icon.dart';
import 'package:chat_gpt/screens/chat_pages/chat_screen.dart'; // Ensure this is imported
// import 'package:chat_gpt/screens/premium_pages/premium_screen.dart'; // Unused in this direct context
import 'package:chat_gpt/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../modals/all_modal.dart'; // Keep if chatGPTList uses it
// import '../../modals/chat_message.dart'; // Unused
import '../../utils/app_keys.dart';
import '../../widgets/app_textfield.dart';
// import '../../widgets/message_composer.dart'; // Unused
// import '../demo/chat_api.dart'; // Removed
// import '../demo/chat_page.dart'; // Removed
import '../history_pages/history_screen.dart';
// import '../premium_pages/premium_screen_controller.dart'; // Unused
import '../search_images_pages/search_images_screen.dart';
// import '../setting_pages/setting_page_controller.dart'; // Unused
import '../setting_pages/setting_screen.dart';
import 'home_screen_controller.dart';

// int messageLimit = 100; // This global variable seems unused here, maxMessageLimit is used from app_keys

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int messageLimit = maxMessageLimit; // From app_keys.dart
  InterstitialAd? _interstitialAd;
  // SettingPageController settingPageController = // This can be removed if not used
  //     Get.put(SettingPageController());
  HomeScreenController homeScreenController = Get.put(HomeScreenController());

  // var _awaitingResponse = false; // Unused
  // late final ChatApi chatApi; // Removed

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: Platform.isAndroid ? interstitialAndroidId : interstitialIosId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
            },
          );
        },
        onAdFailedToLoad: (err) {
          print('Failed to load an interstitial ad: ${err.message}');
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    getMessageLimit();
    _loadInterstitialAd();
  }

  FocusNode inputNode = FocusNode();

  getMessageLimit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    messageLimit = prefs.getInt('messageLimit') ?? maxMessageLimit;
    print('messageLimit -->$messageLimit');
    if (mounted) setState(() {});
  }

  // bool autoFocus = false; // Unused

  TextEditingController messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: appBarTitle(context),
        backgroundColor: Theme.of(context).colorScheme.background,
        actions: [
          showImageGeneration == true
              ? IconButton(
                  onPressed: () {
                    Get.to(() => const ImageGenerationScreen(), // Added () => for Get.to
                        transition: Transition.rightToLeft);
                  },
                  icon: AppIcon.aiImageIcon(context))
              : Container(),
          IconButton(
              onPressed: () {
                Get.to(() => const HistoryScreen(), // Added () => for Get.to
                    transition: Transition.rightToLeft);
              },
              icon: AppIcon.historyIcon(context)),
          IconButton(
              onPressed: () {
                Get.offAll(() => const SettingScreen(), transition: Transition.fade); // Added () => for Get.offAll
              },
              icon: AppIcon.settingIcon(context)),

        ],
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GetBuilder<HomeScreenController>(
            assignId: true,
            builder: (logic) {
              return Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      10.0.addHSpace(),
                      Obx(() => homeScreenController.isLoading.value == true
                          ? SizedBox(
                              height: MediaQuery.of(context).size.height / 2,
                              child: const Center(
                                  child: CircularProgressIndicator()))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: List.generate(
                                        homeScreenController
                                            .categoriesList.length,
                                        (index) => GestureDetector(
                                              onTap: () {
                                                homeScreenController
                                                    .onChangeIndex(
                                                        index,
                                                        homeScreenController
                                                                .categoriesList[
                                                            index]);
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 9,
                                                        horizontal: 15),
                                                decoration: BoxDecoration(
                                                    color: homeScreenController
                                                                .selectedIndex
                                                                .value ==
                                                            index
                                                        ? const Color(
                                                            0xff3FB085)
                                                        : Theme.of(context).colorScheme.primary,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8)),
                                                child: Text(
                                                    homeScreenController
                                                                .categoriesList[
                                                            index] ??
                                                        "",
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w700)),
                                              ).marginOnly(left: 10),
                                            )),
                                  ),
                                ).paddingOnly(left: 8, right: 8),
                                10.0.addHSpace(),
                                ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: chatGPTList.length, // Assuming chatGPTList is defined elsewhere or in scope
                                    itemBuilder: (context, index) {
                                      return chatGPTList[index].name ==
                                              homeScreenController.selectedText
                                          ? ListView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemCount: chatGPTList[index]
                                                  .categoriesData
                                                  .length,
                                              itemBuilder: (context, i) {
                                                return GestureDetector(
                                                  onTap: (){
                                                    FocusScope.of(context).requestFocus(inputNode);
                                                    messageController.text = chatGPTList[index].categoriesData[i].question;
                                                    if (mounted) setState(() {});
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(8)),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(chatGPTList[index].categoriesData[i].title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),),
                                                        7.0.addHSpace(),
                                                        Text(chatGPTList[index].categoriesData[i].description, style: const TextStyle(color: Color(0xff9193A2), fontSize: 12, fontWeight: FontWeight.w500),),
                                                      ],
                                                    ).marginSymmetric(horizontal: 10),
                                                  ).marginSymmetric(
                                                      horizontal: 18, vertical: 5),
                                                );
                                              })
                                          : Container();
                                    }),
                                10.0.addHSpace(),
                              ],
                            )),
                    ],
                  ),
                ),
              );
            },
          ),

          Column(
            children: [
              Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Theme.of(context).brightness == Brightness.light // context.isDarkMode is not standard, using Theme.of(context).brightness
                        ? const Color(0xffEDEDED)
                        : Colors.white,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            AppTextField(
                              // autoFocus: autoFocus, // autoFocus was unused
                              focusNod: inputNode,
                              controller: messageController,
                              maxLines: messageController.text.length < 10 // This dynamic maxLines based on length is a bit unusual
                                  ? messageController.text.length < 20
                                      ? 3
                                      : 1
                                  : 2,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                          onPressed: () async {
                             if (messageController.text.isNotEmpty) {
                              Get.offAll(
                                  () => ChatScreen(message: messageController.text), // Updated Navigation
                                  transition: Transition.rightToLeft);
                              messageController.clear();
                            } else {
                              showToast(text: 'pleaseEnterText'.tr);
                            }
                          },
                          icon: const Icon(Icons.send, color: Colors.green)),
                    ],
                  )).marginSymmetric(horizontal: 15, vertical: 10),
            ],
          ),
        ],
      ),
    );
  }

  storeMessage(int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('messageLimit', value);
  }
}
