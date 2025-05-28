import 'dart:async';
import 'dart:io';

import 'package:chat_gpt/screens/home_pages/home_screen.dart';
import 'package:chat_gpt/screens/premium_pages/premium_screen_controller.dart';
import 'package:chat_gpt/screens/splash_screen_pages/splash_screen.dart';
import 'package:chat_gpt/utils/extension.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../constant/app_color.dart';
import '../../constant/app_icon.dart';
import '../../modals/premium_modal.dart';
import '../../utils/app_keys.dart';
import '../../utils/etc.dart';
import '../../utils/iap_services.dart';
import '../setting_pages/terms_screen.dart';


class PremiumScreen extends StatefulWidget {
  const PremiumScreen({Key? key}) : super(key: key);

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {

  bool isRestore = false;


  final premiumController = Get.put(PremiumScreenController());
  List<ProductDetails> _products = [];
  List<PremiumModal> premiumList = [
    PremiumModal(month: '1', price: '$inAppCurrency $perWeekPrice/', monthType: '1 Week', perMonth: '$inAppCurrency $perWeekPrice', priceWeek: 'perWeek'.tr, offer: 'offer2'.tr),
    PremiumModal(month: '1', price: '$inAppCurrency $perMonthPrice/', monthType: '1 Month', perMonth: '$inAppCurrency $perMonthPrice', priceWeek: 'perWeek'.tr, offer: 'offer1'.tr),
    PremiumModal(month: '1', price: '$inAppCurrency $perYearPrice/', monthType: '1 Year', perMonth: '$inAppCurrency $perYearPrice', priceWeek: 'perWeek'.tr, offer: 'offer3'.tr),
  ];


  bool isLoading = false;

  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> productsList = [
    ProductDetails(id: '1', title: 'title1', description: 'description1', price: '$perMonthPrice', rawPrice: perMonthPrice, currencyCode: inAppCurrency,currencySymbol: inAppCurrency),
    ProductDetails(id: '2', title: 'title2', description: 'description2', price: '$perWeekPrice', rawPrice: perWeekPrice, currencyCode: inAppCurrency,currencySymbol: inAppCurrency),
    ProductDetails(id: '3', title: 'title3', description: 'description3', price: '$perYearPrice', rawPrice: perYearPrice, currencyCode: inAppCurrency,currencySymbol: inAppCurrency),
  ];


  @override
  void initState() {

    initStore();
    _subscription = InAppPurchase.instance.purchaseStream.listen((List<PurchaseDetails> purchaseDetailsList) {
      IapService().listenToPurchaseUpdated(purchaseDetailsList: purchaseDetailsList);
      },
        onDone: () {
           _subscription.cancel();
      },
        onError: (Object error) {});

    print('productsList -----> ${productsList.length}');

    super.initState();
  }
//
//
//
//
//
//
//
//   /// OLD CODE
  Future<void> initStore() async {

    // InAppPurchaseService().initialize();
      setState(() {
        isLoading = true;
      });
    final bool isAvailable = await InAppPurchase.instance.isAvailable();
    if (isAvailable) {
      await loadProducts();
      setState(() {
        isLoading = false;
      });
    }
  }
  Future<void> loadProducts() async {

    Set<String> ids = Platform.isAndroid
      ?
    {weekPlanAndroid ,monthPlanAndroid , yearPlanAndroid }
        :
    { monthPlanIOS ,  weekPlanIOS , yearPlanIOS };
    final ProductDetailsResponse response = await InAppPurchase.instance.queryProductDetails(ids);
    if (response.notFoundIDs.isNotEmpty) {
      // Handle the error

    }
    if (mounted) {
      setState(() {
        _products = response.productDetails;
      });
    }
  }
  initialStore() async {
    productsList = await IapService().initStoreInfo(id: Platform.isAndroid ? androidList : iosList, isAvailable: true);
    setState(() {});
  }


  Future<void> _buyProduct(ProductDetails product) async {
    DateTime date =  DateTime.now();
    DateTime yearLater = DateTime(date.year + 1, date.month, date.day);
    DateTime monthLater = DateTime(date.year, date.month + 1, date.day);
    DateTime weekLater = DateTime(date.year, date.month, date.day + 7);


    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    bool purchaseDetails =  await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
      print("purchaseDetails ------> $purchaseDetails");
    /// PurchaseDetails? purchaseDetails;
    if (purchaseDetails) {
      if(premiumController.selectedI.value == 0){

        // Get.offAll(const HomeScreen());


        Future.delayed(const Duration(seconds: 60),() {
          premiumController.storeDate(monthLater.toString());
          setState(() {
            isRestore = false;
          });
          Get.offAll(const HomeScreen());
          showToast(text: "Purchase Done");

        });



      }
      if(premiumController.selectedI.value == 1){

        // Get.offAll(const HomeScreen());
        Future.delayed(const Duration(seconds: 60),() {
          premiumController.storeDate(weekLater.toString());
          setState(() {
            isRestore = false;
          });
          Get.offAll(const HomeScreen());
          showToast(text: "Purchase Done");
        });
      }
      if(premiumController.selectedI.value == 2){

        // Get.offAll(const HomeScreen());
        Future.delayed(const Duration(seconds: 60),() {
          premiumController.storeDate(yearLater.toString());
          setState(() {
            isRestore = false;
          });
          Get.offAll(const HomeScreen());
          showToast(text: "Purchase Done");
        });
      }
    }
     else {
       showToast(text: "Failed Fetch");
      }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    DateTime date =  DateTime.now();
    DateTime yearLater = DateTime(date.year + 1, date.month, date.day);
    DateTime monthLater = DateTime(date.year, date.month + 1, date.day);
    DateTime weekLater = DateTime(date.year, date.month, date.day + 7);

    for (PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.restored) {
        if(purchaseDetails.productID == monthPlanIOS){
          premiumController.storeDate(monthLater.toString());
        }
        if(purchaseDetails.productID == weekPlanIOS){
          premiumController.storeDate(weekLater.toString());
        }
        if(purchaseDetails.productID == yearPlanIOS){
          premiumController.storeDate(yearLater.toString());
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.offAll(const HomeScreen());
        return true;
      },
      child: Scaffold(
        backgroundColor: context.theme.backgroundColor,
        appBar: AppBar(
            elevation: 0,
            backgroundColor: context.theme.backgroundColor,
            leading: IconButton(
              onPressed: () {
              Get.offAll(const HomeScreen());
            }, icon:  Icon(
                Icons.close,
              color: context.textTheme.headline1!.color
            ),),
            centerTitle: true,
            title: appBarTitle(context).marginOnly(left: 40),
            actions: [
              CupertinoButton(
                onPressed: () {
                   setState(() {
                     isRestore = true;
                   });
                  Future.delayed(const Duration(seconds: 3),()  async {
                    try{
                      InAppPurchase iap = InAppPurchase.instance.restorePurchases() as InAppPurchase;
                      _subscription = iap.purchaseStream.listen((List<PurchaseDetails> purchaseDetailsList) {
                        _listenToPurchaseUpdated(purchaseDetailsList);
                      }, onDone: () {
                        _subscription.cancel();
                        isRestore = false;
                        showToast(text: "You get a old Purchase item");
                        setState(() {});
                        }, onError: (error) {
                        isRestore = false;
                        showToast(text: "You have not purchase anything before");
                        setState(() {});
                        },

                      );
                      await InAppPurchase.instance.restorePurchases();
                      setState(() {});
                    }catch(e){
                      isRestore = false;
                      showToast(text: "You have not purchase anything before");
                      setState(() {});
                    }
                  });
                },
                child: Text("restore".tr),)
            ]
        ),

        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  10.0.addHSpace(),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        color:  context.theme.primaryColor,
                        borderRadius: BorderRadius.circular(7)
                    ),
                    child: Column(
                      children: [
                        10.0.addHSpace(),
                        Text("premiumAdvanced".tr, style: const TextStyle(color: Colors.white),),
                        5.0.addHSpace(),
                        const Divider(color: Color(0xff2F2F2F),),
                        5.0.addHSpace(),
                        advancedListTile(context, title: "premiumSub1".tr),

                        10.0.addHSpace(),
                        advancedListTile(context, title: 'premiumSub2'.tr),


                        10.0.addHSpace(),
                        advancedListTile(context, title: 'premiumSub3'.tr),

                        10.0.addHSpace(),
                        advancedListTile(context, title: 'premiumSub5'.tr),

                        10.0.addHSpace(),
                      ],
                    ).marginSymmetric(horizontal: 20),
                  ).marginSymmetric(horizontal: 20),
                  30.0.addHSpace(),








                  isLoading == true ? const Center(child: CupertinoActivityIndicator(),) : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _products.length,
                      itemBuilder: (context,  index) {
                        return Obx(() {
                          return  GestureDetector(
                            onTap: () {
                              premiumController.onChangeIndex(index);

                              setState(() {});
                            },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(color: context.theme.primaryColor, borderRadius: BorderRadius.circular(15), border: Border.all(color: premiumController.selectedI.value == index ? const Color(0xff73AA57) : const Color(0xff616A61), width: 2)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_products[index].title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 17),),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [

                                      index == 0 ? Container(
                                        height: 20,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(color: AppColor.greenColor,borderRadius: BorderRadius.circular(3)),
                                        child: const Center(child: Text("Popular",style: TextStyle(color: Colors.black,fontWeight: FontWeight.w600),)),
                                      ) : Container(),

                                      index == 2 ? Container(
                                        height: 20,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(color: AppColor.greenColor,borderRadius: BorderRadius.circular(3)),
                                        child: const Center(child: Text("Best Value",style: TextStyle(color: Colors.black,fontWeight: FontWeight.w600),)),
                                      ) : Container(),

                                      10.0.addWSpace(),

                                      Text(_products[index].price, style: const  TextStyle(color: Color(0xffAFAFB1), fontWeight: FontWeight.w500, fontSize: 17),),

                                    ],
                                  ),
                                ],
                              ).marginSymmetric(horizontal: 10),
                            ).marginOnly(left: 20, right: 20, top: 10),
                          );
                        });
                      }),







                  20.0.addHSpace(),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      onPressed: () async {
                        setState(() {
                          isRestore = true;
                        });
                        if(premiumController.selectedI.value == 1 ){
                          _buyProduct(Platform.isAndroid ? _products[0] : _products[0]);
                        }
                        if(premiumController.selectedI.value == 0 ){
                          _buyProduct(Platform.isAndroid ?  _products[1] : _products[1]);
                        }
                        if(premiumController.selectedI.value == 2 ){
                         _buyProduct(Platform.isAndroid ? _products[2] : _products[2]);
                        }
                        setState(() {});
                      },
                      color: const Color(0xff51A982),
                      borderRadius: BorderRadius.circular(5),
                        // child: Text("startTrail".tr),
                        child: Text(premiumController.selectedI.value == 2  ? "Start 1 Year Plan" : premiumController.selectedI.value == 0 ?  "Start 1 Month Plan" : "Start 1 Week Plan" ),
                    ),
                  ).marginOnly(left: 20,right: 20),
                  5.0.addHSpace(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      Text("autoRenewable".tr,style: TextStyle(color: context.textTheme.headline1!.color,fontSize: 12),),

                      5.0.addWSpace(),

                      GestureDetector(
                        onTap: () {
                          Get.to(const TermsScreen(), transition: Transition.rightToLeft);
                        },
                        child: SizedBox(
                          width: 50,
                          height: 30,
                          child: Center(child: Text("termsIn".tr,style: const TextStyle(fontSize: 12,color: Colors.blue),)),
                        ),
                      ),


                      5.0.addWSpace(),
                      GestureDetector(
                        onTap: () {
                          Get.to(const PrivacyScreen(), transition: Transition.rightToLeft);
                        },
                        child: SizedBox(
                          // color: Colors.red,
                          width: 50,
                          height: 30,
                          child: Center(child: Text("privacyIn".tr,style: const TextStyle(fontSize: 12,color: Colors.blue),)),
                        ),
                      ),


                    ],
                  ).marginSymmetric(horizontal: 20),

                  10.0.addHSpace()

                ],
              ),
            ),


            Visibility(
              visible: isRestore,
              child:
                Center(
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(15)),
                    child: AppLottie.restoreLottie(),
                  ),
                ),
            )

          ],
        ),
      ),
    );
  }

  Widget advancedListTile(BuildContext context, {required String title}) {
    return Row(
      children:[
        AppIcon.checkBoxIcon(),
        10.0.addWSpace(),
        Expanded(
          child: Text(title, style: const TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),),
        )
      ],
    );
  }


}
