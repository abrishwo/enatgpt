import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:flutter_highlight/themes/atom_one_dark.dart'; // For dark theme code blocks
import 'package:flutter_highlight/themes/atom_one_light.dart'; // For light theme code blocks
import '../constant/app_assets.dart';
import '../constant/app_color.dart';
import '../utils/extension.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    required this.isUserMessage,
    this.trailing, // Added for optional trailing widget like a copy button
    super.key,
  });

  final String message;
  final bool isUserMessage;
  final Widget? trailing; // Optional trailing widget

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final bool isDarkMode = themeData.brightness == Brightness.dark;

    // Define PreConfig for code blocks
    final PreConfig preConfig = PreConfig(
      theme: isDarkMode ? atomOneDarkTheme : atomOneLightTheme,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF282c34) : Colors.grey[200], // Atom One dark/light background
        borderRadius: BorderRadius.circular(8), // Rounded corners for code blocks
      ),
      padding: const EdgeInsets.all(16.0), // Padding inside code blocks
      textStyle: const TextStyle(fontSize: 14.0), // Consistent font size for code
    );

    // Define MarkdownConfig
    final MarkdownConfig markdownConfig = MarkdownConfig(
      configs: [
        preConfig,
        // You can add other configs here, e.g., for link styles, table styles, etc.
        // Example: LinkConfig for custom link appearance/behavior
        LinkConfig(
          style: TextStyle(
            color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
            decoration: TextDecoration.underline,
          ),
          onTap: (url) {
            // Handle link tap, e.g., open in browser
            // You might need to use a package like url_launcher
            print('Link tapped: $url');
          },
        ),
        // Example: PConfig for paragraph styling (though MarkdownWidget handles this by default)
        PConfig(
          textStyle: TextStyle(
            fontSize: 16,
            color: isUserMessage ? Colors.white : (isDarkMode ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUserMessage)
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xffB2E7CA),
              child: Center(child: Image.asset(AppAssets.botImage)),
            ).marginOnly(right: 8.0),
          Flexible( // Use Flexible to allow message bubble to take available space
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75), // Max width for bubble
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
              decoration: BoxDecoration(
                color: isUserMessage ? AppColor.greenColor : themeData.colorScheme.primary,
                borderRadius: isUserMessage
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(4), // Different corner for user
                      )
                    : const BorderRadius.only(
                        topLeft: Radius.circular(4), // Different corner for AI
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownWidget(
                    data: message,
                    shrinkWrap: true, // Important for ListView
                    config: markdownConfig,
                    // Ensure the default text style within MarkdownWidget matches the bubble's text color
                    // This is now partly handled by PConfig, but can be set here too for general text.
                    styleConfig: StyleConfig(
                       p: TextStyle(
                         fontSize: 16,
                         color: isUserMessage ? Colors.white : (isDarkMode ? Colors.white : Colors.black87),
                       )
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: trailing,
                    ),
                  ]
                ],
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
            ).marginOnly(left: 8.0),
        ],
      ),
    );
  }
}
