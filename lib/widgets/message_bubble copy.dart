import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:markdown_widget/markdown_widget.dart';
import '../constant/app_assets.dart';
import '../constant/app_color.dart';
import '../utils/extension.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.content,
    required this.isUserMessage,
    super.key,
  });

  final String content;
  final bool isUserMessage;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    bool inProgress = true;

    return Row(
      children: [
        isUserMessage?
        Container():
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xffB2E7CA),
              child: Center(child: Image.asset(AppAssets.botImage)),
            ).marginOnly(bottom: 40),
          ],
        ),
        Expanded(
          child: Container(
            margin: isUserMessage
          ?
          const EdgeInsets.only(left: 50,right: 10,top: 10,bottom: 10)
              :
          const EdgeInsets.only(right: 50,left: 10),
            decoration: BoxDecoration(
              color: isUserMessage ? AppColor.greenColor : context.theme.primaryColor,
              borderRadius:  isUserMessage
            ?
            const BorderRadius.only(topLeft: Radius.circular(20),topRight: Radius.circular(20),bottomLeft: Radius.circular(20))
              :
          const BorderRadius.only(topLeft: Radius.circular(20),topRight: Radius.circular(20),bottomRight: Radius.circular(20)),
            ),
            child: Align(
              alignment: isUserMessage
                  ?
              Alignment.topRight
                  :
              Alignment.topLeft,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MarkdownWidget(
                          data: content,
                          shrinkWrap: true,
                        ),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.end,
                        //   children: [
                        //     Text(
                        //       isUserMessage ? '' : 'AI',
                        //       style: const TextStyle(fontWeight: FontWeight.bold),
                        //     ),
                        //
                        //   ],
                        // ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            isUserMessage? Container():GestureDetector(
                              onTap : ()  async {
                                showToast(text: 'copy'.tr);
                                await Clipboard.setData(ClipboardData(text: content));},
                              child: const  SizedBox(
                                height: 30,
                                width: 30,
                                child: Center(child: Icon(Icons.copy,color: Colors.white,)),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  // if(isUserMessage)
                  //   Row(
                  //     mainAxisAlignment: MainAxisAlignment.start,
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       CircleAvatar(radius: 16,backgroundColor: const Color(0xffB2E7CA),   child: Center(child: Image.asset(AppAssets.botImage)),) ,
                  //       5.0.addWSpace(),
                  //       Expanded(
                  //         child: Container(
                  //           margin: const EdgeInsets.only(right: 50),
                  //           decoration:  BoxDecoration(
                  //             borderRadius: const BorderRadius.only(topLeft: Radius.circular(20),topRight: Radius.circular(20),bottomRight: Radius.circular(20)),
                  //             color:  context.theme.primaryColor,
                  //           ),
                  //           padding: const EdgeInsets.all(8),
                  //           child: Row(
                  //             mainAxisAlignment: MainAxisAlignment.start,
                  //             crossAxisAlignment: CrossAxisAlignment.center,
                  //             children: [
                  //               Lottie.asset(AppAssets.loadingFile,height: 20),
                  //             ],
                  //           ),
                  //         ),
                  //       ),
                  //       5.0.addWSpace(),
                  //       Container(),
                  //     ],
                  //   ),
                ],
              ),
            ),
          ),
        ),
        isUserMessage?CircleAvatar(radius: 16,backgroundColor: const Color(0xffD8F4E5),child: Center(child: Text("me".tr,style: TextStyle(color: AppColor.greenColor,fontWeight: FontWeight.w700,fontSize: 10))),):Container()
      ],
    );
  }
}
