
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roullet_app/Controllers/change_password_controller.dart';

import '../../Helper_Constants/colors.dart';
import '../../Widgets/button.dart';

class ChangePassword extends StatelessWidget {
  final ChangePasswordController controller = Get.put(ChangePasswordController());

   ChangePassword({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(50.0),
            bottomRight: Radius.circular(50),
          ),
        ),
        toolbarHeight: 60,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: colors.whiteTemp,
        ),
        title: const Text(
          "Change Password",
          style: TextStyle(fontSize: 17, color: colors.whiteTemp),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(10.0),
              bottomRight: Radius.circular(10),
            ),
            gradient: LinearGradient(
              colors: <Color>[colors.primary, colors.secondary],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Obx(() => TextFormField(
                keyboardType: TextInputType.text,
                controller: controller.oldPassC,
                obscureText: !controller.oldPasswordVisible.value,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: "Old Password",
                  hintStyle: const TextStyle(fontSize: 12),
                  prefixIcon: const Icon(
                    Icons.lock_outlined,
                    size: 20,
                  ),
                  contentPadding: const EdgeInsets.only(top: 5),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.oldPasswordVisible.value ? Icons.visibility : Icons.visibility_off,
                      color: Theme.of(context).primaryColorDark, size: 18,
                    ),
                    onPressed: controller.toggleOldPasswordVisibility,
                  ),
                ),
              )),
              const SizedBox(height: 20),
              Obx(() => TextFormField(
                keyboardType: TextInputType.text,
                controller: controller.newPassC,
                obscureText: !controller.newPasswordVisible.value,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: "New Password",
                  hintStyle: const TextStyle(fontSize: 12),
                  prefixIcon: const Icon(
                    Icons.lock_outlined,
                    size: 20,
                  ),
                  contentPadding: const EdgeInsets.only(top: 5),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.newPasswordVisible.value ? Icons.visibility : Icons.visibility_off,
                      color: Theme.of(context).primaryColorDark, size: 18,
                    ),
                    onPressed: controller.toggleNewPasswordVisibility,
                  ),
                ),
              )),
              const SizedBox(height: 20),
              Obx(() => TextFormField(
                keyboardType: TextInputType.text,
                controller: controller.confirmPassC,
                obscureText: !controller.confirmPasswordVisible.value,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: "Confirm Password",
                  hintStyle: const TextStyle(fontSize: 12),
                  prefixIcon: const Icon(
                    Icons.lock_outlined,
                    size: 20,
                  ),
                  contentPadding: const EdgeInsets.only(top: 5),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.confirmPasswordVisible.value ? Icons.visibility : Icons.visibility_off,
                      color: Theme.of(context).primaryColorDark, size: 18,
                    ),
                    onPressed: controller.toggleConfirmPasswordVisibility,
                  ),
                ),
              )),
              const SizedBox(height: 20),
              Obx(() => AppButton1(
                title: controller.isLoading.value ? "Please wait.." : "Update Password",
                onTap: controller.updatePassword,
              )),
            ],
          ),
        ),
      ),
    );
  }
}
