import 'package:flutter/material.dart';

// import '../utils/app_keys.dart'; // Unused, can be removed

class AppTheme {
  static final dark = ThemeData.dark().copyWith(
    // backgroundColor:  Colors.black, // Deprecated, use colorScheme.background
    // primaryColor:  const Color(0xff1E1E1E), // Deprecated, use colorScheme.primary
    colorScheme: ColorScheme.dark(
      background: Colors.black,
      primary: const Color(0xff1E1E1E), // Or another primary color if desired
      surface: const Color(0xff1E1E1E), // Common for card/container backgrounds
      onPrimary: Colors.white, // Text/icon color on primary
      onSurface: Colors.white, // Text/icon color on surface
      // Add other colors as needed: secondary, error, onBackground, etc.
    ),
    textTheme:  const TextTheme(
      // headline1: TextStyle(color: Colors.white) // Deprecated
      displayLarge: TextStyle(color: Colors.white), // M3 equivalent for large headlines
      // Define other text styles as needed: headlineMedium, titleLarge, bodyLarge, etc.
    )
  );

  static final light = ThemeData.light().copyWith(
    // backgroundColor:  Colors.white, // Deprecated
    // primaryColor: const Color(0xff1E1E1E), // Deprecated
    colorScheme: ColorScheme.light(
      background: Colors.white,
      primary: const Color(0xff1E1E1E), // Or another primary color if desired
      surface: const Color(0xffF0F0F0), // Light surface, or use Color(0xff1E1E1E) if you want dark cards on light theme
      onPrimary: Colors.white,
      onSurface: Colors.black, // Text/icon color on light surface
      // Add other colors as needed
    ),
    textTheme:const TextTheme(
      // headline1: TextStyle(color: Colors.black) // Deprecated
      displayLarge: TextStyle(color: Colors.black), // M3 equivalent
      // Define other text styles
    )
  );
}
