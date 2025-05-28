import 'package:chat_gpt/screens/chat_pages/chat_controller.dart';
import 'package:chat_gpt/screens/history_chat_view_screen/history_chat_controller.dart';
import 'package:chat_gpt/screens/home_pages/home_screen.dart';
import 'package:chat_gpt/screens/home_pages/home_screen_controller.dart';
import 'package:chat_gpt/screens/lenguage_pages/lenguage_screen_controller.dart';
import 'package:chat_gpt/screens/onboarding_pages/on_boarding_page_view/on_boarding_controller.dart';
import 'package:chat_gpt/screens/search_images_pages/search_screen_controller.dart';
import 'package:chat_gpt/screens/setting_pages/setting_page_controller.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../google_ads_controller.dart';
import '../../modals/premium_modal.dart';
import '../../utils/app_keys.dart';
import '../splash_screen_pages/splash_screen.dart';

String premiumDate = "";
// bool isPremium = true;

class PremiumScreenController extends GetxController{
  RxInt selectedI = 2.obs;


  onChangeIndex(int index){
    selectedI.value = index;
    update();
  }

  storeDate(String dateTime) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('Premium_Date', dateTime);
    print("DateTime --------> $dateTime");
    update();
  }

  bool isPremium  =  false;

  getDate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    premiumDate = prefs.getString('Premium_Date') ?? "";
    premiumDate == "" ? Get.put(GoogleAdsController()) : null;
    DateTime fin = DateTime.parse(premiumDate);
    DateTime date =  DateTime.now();
    DateTime time = DateTime(date.year, date.month, date.day);
    if(premiumDate != ""){
      if(time.compareTo(fin) < 0){
        isPremium = true;
        update();
      }else{
        isPremium = false;
        update();
      }
    }else{
      print("non premium");
    }
    print("Is Premium ----> $isPremium");
    isPremium == true ? null :  Get.put(GoogleAdsController());
  }

  @override
  void onInit() {
    getDate();
    // TODO: implement onInit
    super.onInit();
  }







}