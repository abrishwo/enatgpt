import 'package:chat_gpt/screens/demo/chat_api.dart';
import 'package:chat_gpt/screens/demo/chat_page.dart';
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
import 'main_controller.dart';

void main() async {
  await GetStorage.init();
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  await loadEnvFile();
  runApp( MyApp(chatApi: ChatApi(),));
}

class MyApp extends StatelessWidget {

  const MyApp({required this.chatApi, super.key});

  final ChatApi chatApi;
  @override
  Widget build(BuildContext context) {
    Get.put(LanguageScreenController());
    Get.put(MainPageController());
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      translations: LocalString(),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isLightMode == true && isDarkMode == true ? ThemeServices().theme : isDarkMode == true ? ThemeMode.dark : isLightMode == true ? ThemeMode.light : ThemeMode.dark,
     // home: ChatPage(chatApi: chatApi),
      home: HomeScreen(),
    );
  }
}






