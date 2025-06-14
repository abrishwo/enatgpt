import 'dart:io';
import 'package:chat_gpt/services/credit_service.dart'; // Adjust path if needed
import 'package:chat_gpt/utils/app_keys.dart';      // Adjust path if needed
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_analytics/firebase_analytics.dart'; // Import Firebase Analytics

class RewardedAdsController extends GetxController {
  final CreditService _creditService = Get.find<CreditService>();

  RewardedAd? _rewardedAd;
  final RxBool isAdLoading = false.obs;
  final RxBool isAdAvailable = false.obs; // True if ad is loaded and ready
  int _retryAttempts = 0;
  final int _maxRetryAttempts = 2;

  String get _adUnitId {
    if (Platform.isAndroid) {
      return rewardedAdUnitIdAndroid;
    } else if (Platform.isIOS) {
      return rewardedAdUnitIdIOS;
    } else {
      throw UnsupportedError("Unsupported platform for ads");
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Only load ads if not premium and ads are not globally disabled
    if (!isPremium && !adsOff) {
        loadRewardedAd();
    }
  }

  void loadRewardedAd() {
    if (isAdLoading.value || _rewardedAd != null) {
      print('RewardedAdsController: Ad is already loading or already loaded.');
      return;
    }

    // Check for premium status or if ads are globally disabled again before loading
    if (isPremium || adsOff) {
        print('RewardedAdsController: User is premium or ads are off. Not loading rewarded ad.');
        return;
    }

    isAdLoading.value = true;
    isAdAvailable.value = false;
    print('RewardedAdsController: Loading RewardedAd with AdUnitId: $_adUnitId');

    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          isAdLoading.value = false;
          isAdAvailable.value = true;
          _retryAttempts = 0;
          print('RewardedAdsController: RewardedAd loaded.');

          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (RewardedAd ad) => print('RewardedAdsController: $ad onAdShowedFullScreenContent.'),
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              print('RewardedAdsController: $ad onAdDismissedFullScreenContent.');
              ad.dispose();
              _rewardedAd = null;
              isAdAvailable.value = false;
              // Optionally, load the next ad after a delay
              // Future.delayed(Duration(seconds: 1), () => loadRewardedAd());
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              print('RewardedAdsController: $ad onAdFailedToShowFullScreenContent: $error');
              ad.dispose();
              _rewardedAd = null;
              isAdAvailable.value = false;
            },
            onAdImpression: (RewardedAd ad) => print('RewardedAdsController: $ad impression occurred.'),
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('RewardedAdsController: RewardedAd failed to load: $error');
          isAdLoading.value = false;
          _rewardedAd = null;
          isAdAvailable.value = false;
          _retryAttempts++;
          if (_retryAttempts <= _maxRetryAttempts) {
            print('RewardedAdsController: Retrying rewarded ad load (attempt $_retryAttempts)...');
            Future.delayed(Duration(seconds: 5 * _retryAttempts), () {
                if (!isPremium && !adsOff) loadRewardedAd(); // Check again before retrying
            });
          } else {
            print('RewardedAdsController: Max retry attempts for rewarded ad reached.');
          }
        },
      ),
    );
  }

  void showRewardedAd() {
    if (isPremium || adsOff) {
        print('RewardedAdsController: User is premium or ads are off. Cannot show rewarded ad.');
        Get.snackbar("Ads Disabled", "Rewarded ads are currently disabled or you are a premium user.");
        return;
    }

    if (_rewardedAd == null || !isAdAvailable.value) {
      print('RewardedAdsController: Rewarded ad is not available to show.');
      if(!isAdLoading.value && _retryAttempts <= _maxRetryAttempts) {
         if (!isPremium && !adsOff) loadRewardedAd(); // Try to load if not already loading
      }
      Get.snackbar("Ad Not Ready", "Rewarded ad is not available right now. Please try again later.");
      return;
    }

    _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      print('RewardedAdsController: User earned reward: ${reward.amount} ${reward.type}');
      _creditService.addCredits(0.5).then((success) {
        if (success) {
          Get.snackbar("Credits Earned!", "You've received 0.5 credits.");
          print("RewardedAdsController: 0.5 credits added successfully.");
          // Log event to Firebase Analytics
          FirebaseAnalytics.instance.logEvent(
            name: 'rewarded_ad_completed',
            parameters: {
              'ad_unit_id': _adUnitId, // The ad unit ID used
              'credits_awarded': 0.5,
              'user_id': _creditService.currentUserCredit.value?.userId ?? 'unknown_user',
            },
          );
          print("RewardedAdsController: Logged rewarded_ad_completed event.");
        } else {
          Get.snackbar("Error", "Failed to add credits. Please try again.");
          print("RewardedAdsController: Failed to add credits after rewarded ad.");
        }
      });
    });
    // Ad object is disposed in onAdDismissedFullScreenContent or onAdFailedToShowFullScreenContent
  }

  @override
  void onClose() {
    print('RewardedAdsController: Disposing rewarded ad.');
    _rewardedAd?.dispose();
    super.onClose();
  }
}
