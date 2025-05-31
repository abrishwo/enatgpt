import 'dart:convert';
import 'dart:io';

import 'package:chat_gpt/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

// import '../../constant/app_color.dart'; // Likely unused if colors are from theme
import '../../constant/app_icon.dart';
import '../../modals/message_model.dart';
// import '../../theme/theme_services.dart'; // Likely unused
import '../../utils/app_keys.dart';
import '../../utils/shared_prefs_utils.dart';
import '../history_chat_view_screen/history_chat_view_screen.dart';
import '../home_pages/home_screen.dart';
// import '../premium_pages/premium_screen_controller.dart'; // Unused

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {

  Future<void> refresh() async {
    await  SharedPrefsUtils.getChat();
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    refresh();
  }

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final BannerAd myBanner = BannerAd(
      adUnitId: Platform.isAndroid ? bannerAndroidID : bannerIOSID,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    );
    myBanner.load();
    final AdWidget adWidget = AdWidget(ad: myBanner);
    final Container adContainer = Container(
      alignment: Alignment.center,
      width: myBanner.size.width.toDouble(),
      height: myBanner.size.height.toDouble(),
      child: adWidget,
    );

    return WillPopScope(
      onWillPop: () async {
        Get.offAll(const HomeScreen(),transition: Transition.leftToRight);
        return true;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background, // Changed
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(onPressed: (){
            Get.offAll(const HomeScreen(),transition: Transition.leftToRight);
          }, icon: Icon(Icons.arrow_back_outlined,color: Theme.of(context).textTheme.displayLarge?.color,),), // Changed
            actions: [
              IconButton(
                onPressed: (){
                  if(historyList.isNotEmpty) {
                    showAppDialog(context);
                  }else{
                    showToast(text: 'historyEmpty'.tr);
                  }
                     },
                icon: AppIcon.deleteIcon(context),
              )
            ],
            backgroundColor: Theme.of(context).colorScheme.background, // Changed
            centerTitle: true,
            title:  Text("history".tr, style: TextStyle(color: Theme.of(context).textTheme.displayLarge?.color,fontWeight: FontWeight.w500))), // Changed
        body: Stack(
          alignment: Alignment.topCenter,
          children: [
            historyList.isEmpty
                ?
            loading == true
                ?
            const Center(child: CircularProgressIndicator(),) :
             Center(child: Text("noData".tr,style: TextStyle(color: Theme.of(context).textTheme.displayLarge?.color))) // Changed
                :
            SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ListView.builder(
                      itemCount: historyList.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context,index){
                        return GestureDetector(
                          onTap: (){
                            Get.offAll(
                                HistoryChatViewScreen(answer: historyList[index].answer, question:  historyList[index].message, historyPage: true),transition: Transition.rightToLeft
                            );
                          },
                          child: Container(
                            height: 80,
                            width: double.infinity,
                            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary,borderRadius: BorderRadius.circular(14)), // Changed
                            child: Column(
                              children: [
                                10.0.addHSpace(),
                                Row(
                                    children: [
                                      Container(height: 30, width: 30, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(7)), child: Center(child: AppIcon.chatIcon())), // Changed
                                      7.0.addWSpace(),
                                      Expanded(child: Text(historyList[index].answer,style: TextStyle(fontSize: 15,color: Theme.of(context).textTheme.titleMedium?.color),maxLines: 2,)), // Changed headline6 to titleMedium
                                      IconButton(
                                          onPressed: (){
                                            SharedPrefsUtils.removeChat(historyList[index].id);
                                            refresh();
                                          }, icon: AppIcon.deleteIcon(context,color: Colors.white))
                                    ]
                                ).marginOnly(left: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(historyList[index].dateTime,style: const TextStyle(color: Color(0xff606271)),),
                                  ],
                                ).marginSymmetric(horizontal: 10),
                              ],
                            ),
                          ).marginOnly(left: 10,right: 10,top: 10),
                        );
                      }),
                  70.0.addHSpace(),
                ],
              ),
            ),
            Column(
              children: [
                const Spacer(),
                adContainer,
              ],
            )
          ],
        )
      ),
    );
  }

  showAppDialog(BuildContext context){
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('doYouDelete'.tr,style: TextStyle(color: Theme.of(context).textTheme.displayLarge?.color),), // Changed
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text('areYouConfirm'.tr,style: TextStyle(color: Theme.of(context).textTheme.displayLarge?.color)), // Changed
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('confirm'.tr),
              onPressed: () {
                historyList.forEach((element) {
                  SharedPrefsUtils.removeChat(element.id);
                });
                refresh();
                if (mounted) setState(() {});
                Get.back();
              },
            ),
            TextButton(
              child: Text('cancel'.tr),
              onPressed: () {
                Get.back();
              },
            ),
          ],
        );
      },
    );
  }
}
