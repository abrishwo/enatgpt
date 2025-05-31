import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Keep if GetX features like .marginAll are used, otherwise can be removed if not needed for this widget

import '../../../constant/app_assets.dart';
// import '../../../constant/app_icon.dart'; // Unused import
import '../../../utils/app_keys.dart';

class Screen1 extends StatelessWidget {
  const Screen1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
            height : height /10
        ),

        SizedBox(
          height: height /2.3,
          child: Image.asset(AppAssets.image1),
        ).marginAll(5), // GetX specific margin

        Container(
            height : height /10.8
        ),


        Text(Onboarding_Title1,style: TextStyle(color: Theme.of(context).textTheme.displayLarge?.color,fontSize: 24,fontWeight: FontWeight.w700),), // Changed
        Container(
            height : height /50
        ),

        Text(Onboarding_Description1,style: const TextStyle(color: Color(0xff9092A1),fontWeight: FontWeight.w500,fontSize: 16),textAlign: TextAlign.center),
      ],
    );
  }
}
