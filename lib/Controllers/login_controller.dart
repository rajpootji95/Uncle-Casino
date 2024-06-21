import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roullet_app/utils.dart';
import '../../Api Services/requests.dart';
import '../../audio_controller.dart';

class LoginController extends GetxController {
  final AudioController audioController;
  LoginController({required this.audioController});

  var passwordVisible = false.obs;
  var isLoading = false.obs;
  final formKey = GlobalKey<FormState>();
  final mobileController = TextEditingController();
  final passwordController = TextEditingController();
  ApiRequests apiRequests = ApiRequests();

  @override
  void onClose() {
    audioController.dispose();
    mobileController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    passwordVisible.value = !passwordVisible.value;
  }

  Future<void> login(BuildContext context) async {
    if (mobileController.text.isEmpty) {
      Utils.mySnackBar(title:"User Id Not Found",msg: 'Please Enter User Id',maxWidth: 200 );
    } else if (passwordController.text.isEmpty) {
      Utils.mySnackBar(title:"Password Not Found",msg: 'Please Enter Password',maxWidth: 200 );
    } else {
      isLoading.value = true;
      await apiRequests.userLogin(
        mobileController.text,
        passwordController.text,
        audioController,
      );
      isLoading.value = false;
    }
  }
}
