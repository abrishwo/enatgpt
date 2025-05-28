import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constant/app_assets.dart';
import '../../../utils/app_keys.dart';

class Screen3 extends StatelessWidget {
  const Screen3({Key? key}) : super(key: key);

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
          child: Image.asset(AppAssets.image3),
        ).marginAll(5),

        Container(
            height : height /10.8
        ),
        Text(Onboarding_Title3,style: TextStyle(color: context.textTheme.headline1!.color,fontSize: 24,fontWeight: FontWeight.w700),),
        Container(
            height : height /50
        ),

        Text(Onboarding_Description3,style: const TextStyle(color: Color(0xff9092A1),fontWeight: FontWeight.w500,fontSize: 16),textAlign: TextAlign.center),
      ],
    );
  }
}