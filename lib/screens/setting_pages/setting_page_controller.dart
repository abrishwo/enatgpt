import 'package:chat_gpt/theme/theme_services.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/app_keys.dart';


bool isVoiceOn = true;
bool isImageShow = false;



class SettingPageController  extends GetxController{

  RxBool isDarkMode = false.obs;

  @override
  void onInit() {
    getTheme();
    // TODO: implement onInit
    super.onInit();
  }


  onChangeVoiceChange(bool value){
    isVoiceOn =  value;
    storeVoice(isVoiceOn);
    HapticFeedback.mediumImpact();
    update();
  }




  onChangeImageGenerator(bool value){
    isImageShow =  value;
    storeImage(isImageShow);
    HapticFeedback.mediumImpact();
    update();
  }




  onChangeTheme(bool value){
    isDarkMode.value = value;
    storeTheme(isDarkMode.value);
    ThemeServices().switchTheme();
    HapticFeedback.mediumImpact();
    update();
  }


  storeTheme(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', value);
  }

  getTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool('isDarkMode') ?? darkMode;
    isVoiceOn = prefs.getBool('voice') ?? voiceOff;
    isImageShow = prefs.getBool('storeImage') ?? false;
    update();
  }


  storeVoice(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('voice', value);
    update();
  }


  storeImage(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('storeImage', value);
    update();
  }





}