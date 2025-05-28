import 'dart:io';
import 'package:chat_gpt/screens/premium_pages/premium_screen_controller.dart';
import 'package:chat_gpt/utils/app_keys.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GoogleAdsController extends GetxController with WidgetsBindingObserver{


 // final premiumScreenController = Get.put(PremiumScreenController());
  AppOpenAd? appOpenAd;
  bool isPaused = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO: implement didChangeAppLifecycleState
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      isPaused = true;
    }
    if (state == AppLifecycleState.resumed && isPaused) {
      loadAppOpenAd();
      isPaused = false;
    }
  }
  loadAppOpenAd() {
    AppOpenAd.load(
        adUnitId: Platform.isAndroid ? appOpenAndroidId : appOpenIosId ,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
            onAdLoaded: (ad) {
            appOpenAd = ad;
            appOpenAd!.show();
            },
            onAdFailedToLoad: (error) {}),
        orientation: AppOpenAd.orientationPortrait);
  }





  @override
  void onInit() async {
     await loadAppOpenAd();
     WidgetsBinding.instance.addObserver(this);
    // TODO: implement onInit
    super.onInit();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
   WidgetsBinding.instance.removeObserver(this);
  }
}