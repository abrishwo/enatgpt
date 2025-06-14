import 'dart:math';
import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';

class SearchImageScreenController extends GetxController {
  TextEditingController imageSearch = TextEditingController();
  RxBool isLoading = false.obs;
  RxList imageList = <String>[].obs;
  int limit = Random().nextInt(50);
  RxList imageSizeList = [
    "256x256",
    "512x512",
    "1024x1024",
  ].obs;
  RxString size = "256x256".obs;

  onImageSizeChange(index) {
    size.value = index!;
    update();
  }

  // Placeholder for Gemini image generation
  generateImage() async {
    if (imageSearch.text != "") {
      isLoading.value = true;
      imageList.clear();
      update();
      // Gemini does not support direct image generation yet
      // Add a placeholder or mock result
      await Future.delayed(Duration(seconds: 2));
      imageList.add("Gemini image generation is not yet supported.");
      isLoading.value = false;
      update();
    }
  }
}