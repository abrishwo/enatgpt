import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// CHAT GPT ID
// String openAiToken = "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";
// String openAiToken = "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";
String openAiToken = "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";
/// GOOGLE ADS ID (ANDROID)
// String bannerAndroidID = "ca-app-pub-3940256099942544/6300978111";
// String appOpenAndroidId =  "ca-app-pub-3940256099942544/3419835294";
// String interstitialAndroidId = "ca-app-pub-3940256099942544/1033173712";

// /// GOOGLE ADS ID (IOS)
// String bannerIOSID = "ca-app-pub-3940256099942544/2934735716";
// String appOpenIosId =  "ca-app-pub-3940256099942544/3419835294";
// String interstitialIosId = "ca-app-pub-3940256099942544/4411468910";

String bannerAndroidID = "ca-app-pub-9980095986316034/6637551807";
String appOpenAndroidId =  "ca-app-pub-9980095986316034/3449077844";
String interstitialAndroidId = "ca-app-pub-9980095986316034/9211744252";

/// GOOGLE ADS ID (IOS)
String bannerIOSID = "ca-app-pub-3940256099942544/2934735716";
String appOpenIosId =  "ca-app-pub-3940256099942544/3419835294";
String interstitialIosId = "ca-app-pub-3940256099942544/4411468910";
/// GOOGLE ADS SHOW/DISABLE
bool adsOff = false;

/// PREMIUM SHOW/DISABLE
bool isPremium = false;

/// Max Token Limit is 4096
int token = 500;

///  DARK MODE SHOW (TRUE/FALSE)
bool isDarkMode = true;
bool isLightMode = true;

/// MESSAGE LIMIT
int maxMessageLimit = 100;

/// SHOW GENERATE IMAGE
bool showImageGeneration = true;

/// VOICE BUY OFF
bool voiceOff = false;

/// DARK MODE  TRUE
bool darkMode = true;

/// IMAGE GENERTATE LIMIT
int imageGenerateLimit = 3;

bool isLog= false;

/// IN APP PURCHASE ID(ANDROID)
const String monthPlanAndroid = 'android.test.purchased'; /// ENTER YOUR ONE MONTH PLAN ID
const String weekPlanAndroid = 'android.test.purchased'; /// ENTER YOUR ONE WEEK  PLAN ID
const String yearPlanAndroid = 'android.test.purchased'; /// ENTER YOUR ONE YEAR PLAN ID

/// IN APP PURCHASE ID(IOS)
const String monthPlanIOS = 'com.onemonth.enatgpt'; /// ENTER YOUR ONE MONTH PLAN ID
const String weekPlanIOS = 'com.oneweek.enatgpt'; /// ENTER YOUR ONE  WEEK PLAN ID
const String yearPlanIOS = 'com.oneyear.enatgpt'; /// ENTER YOUR ONE YEAR PLAN ID

/// TERMS PRIVACY LINK
const String termsLink = 'https://enatsoft.com/terms';
const String privacyLink = 'https://enatsoft.com/privacies';

/// SHARE APP LINK FOR ANDROID
const String shareAppLinkAndroid = "https://play.google.com/store/apps/details?id=com.enat.gpt";

/// SHARE APP LINK FOR  IOS
const String shareAppLinkIOSid = "SHARE APP LINK IOS";


/// IN APP PURCHASE PRICES :-
double perMonthPrice = 30; /// PER MONTH
double perWeekPrice = 10; /// PER WEEK
double perYearPrice = 149; /// PER YEAR


/// ONBOARDING SCREEN 1 TEXT
String Onboarding_Title1 = '''Welcome to EnatGPT''';
String Onboarding_Description1 = '''Experience the power of AI! Ask questions, get instant answers, and access detailed articles to enrich your knowledge.''';

/// ONBOARDING SCREEN 2 TEXT
String Onboarding_Title2 = '''Smart, Fast, and Reliable''';
String Onboarding_Description2 = '''Discover a smarter way to interact with technology. EnatGPT is your assistant for quick, AI-powered solutions.''';

/// ONBOARDING SCREEN 3 TEXT
String Onboarding_Title3 = '''Unlock New Possibilities''';
String Onboarding_Description3 = '''From learning to productivity, let EnatGPT guide you with advanced AI capabilities tailored for your needs.''';


/// CURRENCY NAME
const String inAppCurrency = "\$";

Widget appBarTitle(BuildContext context){
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.start,
    children:  [
      Text("Enat",style: TextStyle(color: context.textTheme.headline1!.color,fontSize: 26,fontWeight: FontWeight.w700),),
      const Text("GPT",style: TextStyle(color: Color(0xff62A193),fontSize: 26,fontWeight: FontWeight.w700),),
    ],
  );
}
