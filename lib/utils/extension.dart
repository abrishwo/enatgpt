import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';


extension SpaceWidget on double {
  addHSpace() {
    return SizedBox(
      height: this,
    );
  }
  addWSpace() {
    return SizedBox(
      width: this,
    );
  }
}

/// add Line from hide keyboard
hideKeyboard(BuildContext context) {
  FocusScope.of(context).requestFocus(FocusNode());
}

showToast({required String text}){
  return Fluttertoast.showToast(
      msg: text,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.white,
      textColor: Colors.black,
      fontSize: 16.0
  );
}



