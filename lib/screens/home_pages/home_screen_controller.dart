import 'dart:convert';
import 'package:chat_gpt/screens/lenguage_pages/lenguage_screen_controller.dart';
import 'package:chat_gpt/screens/premium_pages/premium_screen.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constant/app_assets.dart';
import '../../modals/all_modal.dart';
import '../../utils/shared_prefs_utils.dart';



class HomeScreenController extends GetxController{



  RxBool isLoading = false.obs;




  @override
  void onInit() {
    socialMedialList.clear();
    readJson();
    SharedPrefsUtils. getChat();
    // TODO: implement onClose
    super.onInit();
  }

  RxInt selectedIndex = 0.obs;
  // String selectedText = Get.find<LanguageScreenController>().selectedIndex.value == 0 ? 'Astrology' : 'Astrología';
  String selectedText = jsonString(Get.find<LanguageScreenController>().selectedIndex.value);

  onChangeIndex(int index, text) {
    selectedIndex.value = index;
    selectedText = text;

    update();
  }



  List categoriesList = [];
  var items;
  List<SocialMediaModal> socialMedialList = [];
  List<AstrologyModal> astrologyList = [];

  Future<void> readJson() async {
    socialMedialList.clear();
    chatGPTList.clear();
    update();
    isLoading.value = true;
    update();

    int index = Get.find<LanguageScreenController>().selectedIndex.value;

    switch(index){
      case 0 : jsonFile(AppAssets.enUS);
      break;

      case 1 : jsonFile(AppAssets.esPY);
      break;

      case 2 : jsonFile(AppAssets.frCA);
      break;

      case 3 : jsonFile(AppAssets.deDE);
      break;

      case 4 : jsonFile(AppAssets.zhCN);
      break;

      case 5 : jsonFile(AppAssets.ruRu);
      break;

      case 6 : jsonFile(AppAssets.hiIN);
      break;

      case 7 : jsonFile(AppAssets.arSAU);
      break;

      case 8 : jsonFile(AppAssets.ptPRT);
      break;

      case 9 : jsonFile(AppAssets.idIDN);
      break;

      case 10 : jsonFile(AppAssets.nlNLD);
      break;

      case 11 : jsonFile(AppAssets.itITA);
      break;

      case 12 : jsonFile(AppAssets.plPOL);
      break;

      case 13 : jsonFile(AppAssets.trTUR);
      break;

      case 14 : jsonFile(AppAssets.jaJPN);
      break;

    }
    isLoading.value = false;
    update();
  }


  static String  jsonString(int index) {
    String msg = '';
    switch(index){
      case 0 : msg =  "Astrology";
      break;

      case 1 : msg =  'Astrología';
      break;

      case 2 : msg =  'Astrologie';
      break;

      case 3 : msg =  'Astrologie';
      break;

      case 4 : msg =  '占星术';
      break;

      case 5 : msg =  'Астрология';
      break;

      case 6 : msg =  'ज्योतिष';
      break;

      case 7 : msg =  'علم التنجيم';
      break;

      case 8 : msg =  'Astrologia';
      break;

      case 9 : msg =  'Perbintangan';
      break;

      case 10 : msg =  'Astrologie';
      break;

      case 11 : msg =  'Astrologia';
      break;

      case 12 : msg =  'Astrologia';
      break;

      case 13 : msg =  'Astroloji';
      break;

      case 14 : msg =  '占星術';
      break;

      default : 'Astrology';
    }
    return msg;
  }




  jsonFile(String jsonFile) async {
    final String response = await rootBundle.loadString(jsonFile);
    final data = await json.decode(response);
    Map items = data["ChatGPT"];

    for (var i in items.values) {
      // print("i -----> ${i}"); /// GET CATEGORIES  DATA
      for (Map j in i) {
        categoriesList.add(j['name']); /// CATEGORIES in name add
        // print("j -----> ${j.values}"); /// GET CATEGOREIS NAME AND CATGOREIS DATA KEY

        for (var k in j['category_data']) {
          chatGPTList.add(
              ChatGPTModal(
                  name: j['name'],
                  categoriesData: [
                    CategoriesData(title: k["title"], description: k['description'], question: k['question'])
                  ]
              )
          );
        }
      }
    }
  }


}
