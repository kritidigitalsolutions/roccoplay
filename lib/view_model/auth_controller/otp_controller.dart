import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OtpController extends GetxController {
  final List<TextEditingController> controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());

  var isResendButtonDisabled = false.obs;
  var countdown = 30.obs;
  Timer? _timer;

  @override
  void onClose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.onClose();
  }

  void setOtp(String otp) {
    final digits = otp.replaceAll(RegExp(r'\D'), '');
    for (int i = 0; i < 6; i++) {
      if (i < digits.length) {
        controllers[i].text = digits[i];
      } else {
        controllers[i].clear();
      }
    }
  }

  void clearOtp() {
    for (var controller in controllers) {
      controller.clear();
    }
  }

  void startTimer() {
    isResendButtonDisabled.value = true;
    countdown.value = 30;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value > 0) {
        countdown.value--;
      } else {
        _timer?.cancel();
        isResendButtonDisabled.value = false;
      }
    });
  }
}
