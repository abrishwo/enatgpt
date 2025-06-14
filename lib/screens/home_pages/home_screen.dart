// import 'dart:convert'; // Unused
import 'dart:io';
// import 'package:chat_gpt_sdk/chat_gpt_sdk.dart'; // Removed
// import 'package:http/http.dart' as http; // Unused
import 'package:chat_gpt/constant/app_icon.dart';
import 'package:chat_gpt/screens/chat_pages/chat_screen.dart'; // Ensure this is imported
import 'package:chat_gpt/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../modals/all_modal.dart'; // Keep if chatGPTList uses it
import '../../utils/app_keys.dart';
import '../../widgets/app_textfield.dart';
import '../history_pages/history_screen.dart';
import '../search_images_pages/search_images_screen.dart';
import '../setting_pages/setting_screen.dart';
import 'home_screen_controller.dart';

// NEW IMPORTS
import 'package:chat_gpt/services/credit_service.dart';
import 'package:chat_gpt/controllers/rewarded_ads_controller.dart';
import 'package:chat_gpt/screens/buy_credits_screen/buy_credits_screen.dart'; // Import BuyCreditsScreen


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int messageLimit = maxMessageLimit; // From app_keys.dart
  InterstitialAd? _interstitialAd;
  HomeScreenController homeScreenController = Get.put(HomeScreenController());

  // Access services/controllers
  final CreditService creditService = Get.find<CreditService>();
  final RewardedAdsController rewardedAdsController = Get.find<RewardedAdsController>();


  void _loadInterstitialAd() {
    if (isPremium || adsOff) return; // Don't load if premium or ads are off
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

  TextEditingController messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: appBarTitle(context),
        backgroundColor: Theme.of(context).colorScheme.background,
        actions: [
          Obx(() => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Center(
                  child: Text(
                    'Credits: ${creditService.currentUserCredit.value?.balance?.toStringAsFixed(1) ?? "0.0"}',
                    style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                  )
                ),
              )),
          if (showImageGeneration == true)
              IconButton(
                  onPressed: () {
                    Get.to(() => const ImageGenerationScreen(),
                        transition: Transition.rightToLeft);
                  },
                  icon: AppIcon.aiImageIcon(context))
          else Container(),
          IconButton(
              onPressed: () {
                Get.to(() => const HistoryScreen(),
                    transition: Transition.rightToLeft);
              },
              icon: AppIcon.historyIcon(context)),
          IconButton(
              onPressed: () {
                Get.offAll(() => const SettingScreen(), transition: Transition.fade);
              },
              icon: AppIcon.settingIcon(context)),
        ],
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Credit Buttons Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // "Watch Ad for Credits" Button
                Expanded( // Use Expanded to allow buttons to share space
                  child: Obx(() {
                    bool adCanBeShown = rewardedAdsController.isAdAvailable.value && !rewardedAdsController.isAdLoading.value;
                    bool isLoading = rewardedAdsController.isAdLoading.value;

                    if (isPremium || adsOff) {
                      return const SizedBox.shrink();
                    }

                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), // Adjusted padding
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold) // Adjusted font size
                      ),
                      onPressed: adCanBeShown
                          ? () => rewardedAdsController.showRewardedAd()
                          : null,
                      child: isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                          : const Text('Watch Ad (0.5 Cr)', style: TextStyle(color: Colors.white)), // Shorter text
                    );
                  }),
                ),
                const SizedBox(width: 10), // Spacing between buttons
                // "Buy Credits" Button
                Expanded( // Use Expanded
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent, // Example color
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), // Adjusted padding
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold) // Adjusted font size
                    ),
                    onPressed: () {
                      Get.to(() => const BuyCreditsScreen());
                    },
                    child: const Text('Buy Credits', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),

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
                                    itemCount: chatGPTList.length,
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
                    color: Theme.of(context).brightness == Brightness.light
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
                              focusNod: inputNode,
                              controller: messageController,
                              maxLines: messageController.text.length < 10
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
                                  () => ChatScreen(message: messageController.text),
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
