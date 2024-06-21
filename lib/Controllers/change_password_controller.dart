import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roullet_app/utils.dart';
import '../../Api Services/requests.dart';

class ChangePasswordController extends GetxController {

  var oldPasswordVisible = false.obs;
  var newPasswordVisible = false.obs;
  var confirmPasswordVisible = false.obs;
  ApiRequests apiRequests = ApiRequests();

  final oldPassC = TextEditingController();
  final newPassC = TextEditingController();
  final confirmPassC = TextEditingController();
  var isLoading = false.obs;

  void toggleOldPasswordVisibility() {
    oldPasswordVisible.value = !oldPasswordVisible.value;
  }

  void toggleNewPasswordVisibility() {
    newPasswordVisible.value = !newPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    confirmPasswordVisible.value = !confirmPasswordVisible.value;
  }

  Future<void> updatePassword() async {
    if (oldPassC.text.isEmpty) {
      Utils.mySnackBar(title: "Error",msg: "Please Enter Old Password");
    } else if (oldPassC.text.length < 8) {
      Utils.mySnackBar(title: "Error",msg: "Please Enter 8 digit Password");
    } else if (newPassC.text.isEmpty) {
      Utils.mySnackBar(title: "Error",msg: "Please Enter new password");
    } else if (newPassC.text.length < 8) {
      Utils.mySnackBar(title: "Error",msg: "Please Enter 8 digit password");
    } else if (confirmPassC.text.isEmpty) {
      Utils.mySnackBar(title: "Error",msg: "Please Enter Confirm password");
    } else if (confirmPassC.text != newPassC.text) {
      Utils.mySnackBar(title: "Error",msg: "Password Not Match");
    } else {
      isLoading.value = true;
      try {
        await apiRequests.changePasswordApi(
            oldPassC.text,
            newPassC.text,
            confirmPassC.text
        ).then((value){
          if(!value){
            Get.delete<ChangePasswordController>();
          }
        });
        isLoading.value = false;
        // Utils.mySnackBar(title: 'Success',msg:  'Password updated successfully');
        // Get.back(); // Navigate back on success
      } catch (e) {
        isLoading.value = false;
       Utils.mySnackBar(title: 'Error',msg:  'Failed to update password');
      }
    }
  }

  @override
  void onClose() {
    debugPrint("change password controller closed");
    oldPassC.dispose();
    newPassC.dispose();
    confirmPassC.dispose();
    super.onClose();
  }

}
