import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:markdown_widget/markdown_widget.dart';
import '../constant/app_assets.dart';
import '../constant/app_color.dart';
import '../utils/extension.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    required this.isUserMessage,
    super.key,
  });

  final String message;
  final bool isUserMessage;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Row(
      children: [
        if (!isUserMessage)
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
                ? const EdgeInsets.only(left: 50, right: 10, top: 10, bottom: 10)
                : const EdgeInsets.only(right: 50, left: 10),
            decoration: BoxDecoration(
              color: isUserMessage ? AppColor.greenColor : context.theme.primaryColor,
              borderRadius: isUserMessage
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    )
                  : const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
            ),
            child: Align(
              alignment: isUserMessage ? Alignment.topRight : Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MarkdownWidget(data: message, shrinkWrap: true),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!isUserMessage)
                          GestureDetector(
                            onTap: () async {
                              showToast(text: 'copy'.tr);
                              await Clipboard.setData(ClipboardData(text: message));
                            },
                            child: const SizedBox(
                              height: 30,
                              width: 30,
                              child: Center(
                                child: Icon(Icons.copy, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isUserMessage)
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xffD8F4E5),
            child: Center(
              child: Text(
                "me".tr,
                style: TextStyle(
                  color: AppColor.greenColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
