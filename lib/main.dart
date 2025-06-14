// import 'package:chat_gpt/screens/demo/chat_api.dart'; // Removed
// import 'package:chat_gpt/screens/demo/chat_page.dart'; // Removed
import 'package:chat_gpt/screens/home_pages/home_screen.dart';
import 'package:chat_gpt/screens/lenguage_pages/lenguage_screen_controller.dart';
import 'package:chat_gpt/theme/app_theme.dart';
import 'package:chat_gpt/theme/theme_services.dart';
import 'package:chat_gpt/utils/app_keys.dart';
import 'package:flutter/material.dart';
import 'package:chat_gpt/utils/lenguage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'services/credit_service.dart'; // Import CreditService
import 'controllers/rewarded_ads_controller.dart'; // Import RewardedAdsController
import 'main_controller.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await GetStorage.init();
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  // await dotenv.load();
  // await loadEnvFile();
  Get.put(CreditService()); // Register CreditService
  Get.put(RewardedAdsController()); // Register RewardedAdsController
  runApp(const MyApp()); // Changed: Removed chatApi parameter
}

class MyApp extends StatelessWidget {

  const MyApp({super.key}); // Changed: Removed chatApi parameter

  // final ChatApi chatApi; // Removed
  @override
  Widget build(BuildContext context) {
    Get.put(LanguageScreenController());
    Get.put(MainPageController());
    // CreditService is already put in main(), so it's available throughout the app
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      translations: LocalString(),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isLightMode == true && isDarkMode == true ? ThemeServices().theme : isDarkMode == true ? ThemeMode.dark : isLightMode == true ? ThemeMode.light : ThemeMode.dark,
     // home: ChatPage(chatApi: chatApi), // Logic using ChatPage and chatApi was already commented out
      home: const HomeScreen(), // Ensured HomeScreen is const if possible
    );
  }
}
