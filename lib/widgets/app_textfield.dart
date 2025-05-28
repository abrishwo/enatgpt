import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class AppTextField extends StatelessWidget {
  TextEditingController? controller;
  VoidCallback? onTap;
  Widget? suffixIcon;
  ScrollController? scrollController;
  ValueChanged<String>? onChanged;
  FocusNode? focusNod;
  int? maxLines = 1;
  final String? hintText;
  bool autoFocus;

  AppTextField({Key? key,this.controller,this.onTap,this.suffixIcon,this.autoFocus = false,this.onChanged,this.maxLines,this.scrollController,this.focusNod, this.hintText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      scrollController: scrollController,
      autofocus: autoFocus,
      onTap: onTap,
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      focusNode: focusNod,
      onChanged: onChanged,
      minLines: 1,
      style: const TextStyle(color: Colors.black),
      maxLines: maxLines,
      decoration: InputDecoration(
          // hintText: "askSomething".tr,
          hintText: hintText ?? "askSomething".tr,
          hintStyle: const  TextStyle(color: Colors.black),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),borderSide: const BorderSide(color: Colors.white)),
          focusedBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white)),
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white)),
        suffixIcon: suffixIcon
      ),
    );
  }
}
