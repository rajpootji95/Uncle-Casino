import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roullet_app/Controllers/login_controller.dart';
import 'package:roullet_app/Helper_Constants/colors.dart';
import 'package:roullet_app/Helper_Constants/other_constants.dart';
import '../../Helper_Constants/Images_path.dart';
import '../../audio_controller.dart';

class LoginScreen extends StatelessWidget {

  final AudioController audioController;

  const LoginScreen({Key? key, required this.audioController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LoginController controller = Get.put(LoginController(audioController: audioController));

    double h = Constants.screen.height;
    double w = Constants.screen.width;

    return WillPopScope(
      onWillPop: () async {
        return await showExitPopup(context);
      },
      child: Scaffold(
        body: Container(
          height: h,
          width: w,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.secondary,
                colors.primary,
                colors.secondary,
              ],
            ),
            image: DecorationImage(
              image: AssetImage(ImagesPath.backGroundImage),
              fit: BoxFit.fill,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 20),
              Container(
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 100,
                      color: colors.black54,
                      offset: Offset(-1, 20),
                    ),
                  ],
                ),
                child: Image.asset(
                  ImagesPath.animationGif,
                  scale: 2,
                ),
              ),
              Form(
                key: controller.formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.30,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: colors.whiteTemp,
                        boxShadow: const [
                          BoxShadow(
                            color: colors.borderColorLight,
                            spreadRadius: 1,
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: controller.mobileController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          hintText: "Enter User Id",
                          hintStyle: TextStyle(fontSize: 12),
                          prefixIcon: Icon(
                            Icons.person_outline,
                            size: 20,
                          ),
                          counterText: "",
                          contentPadding: EdgeInsets.only(top: 2),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Obx(() => Container(
                      width: MediaQuery.of(context).size.width * 0.30,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: colors.whiteTemp,
                        boxShadow: const [
                          BoxShadow(
                            color: colors.borderColorLight,
                            spreadRadius: 1,
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: TextFormField(
                        keyboardType: TextInputType.text,
                        controller: controller.passwordController,
                        obscureText: !controller.passwordVisible.value,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter Password",
                          hintStyle: const TextStyle(fontSize: 12),
                          prefixIcon: const Icon(
                            Icons.lock_outlined,
                            size: 20,
                          ),
                          contentPadding: const EdgeInsets.only(bottom: 10),
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.passwordVisible.value
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Theme.of(context).primaryColorDark,
                              size: 18,
                            ),
                            onPressed: controller.togglePasswordVisibility,
                          ),
                        ),
                      ),
                    )),
                    const SizedBox(height: 10),
                    Obx(() => InkWell(
                      onTap: () => controller.login(context),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.30,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: colors.primary,
                            gradient: LinearGradient(
                              colors: [
                                colors.primary,
                                colors.secondary.withOpacity(0.9),
                                colors.primary,
                              ],
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: colors.borderColorLight,
                                spreadRadius: 1,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: controller.isLoading.value
                              ? const CupertinoActivityIndicator(
                            color: colors.whiteTemp,
                          )
                              : const Center(
                              child: Text(
                                'Submit',
                                style: TextStyle(
                                  color: colors.whiteTemp,
                                  fontSize: 16,
                                ),
                              )),
                        ),
                      ),
                    )),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> showExitPopup(context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SizedBox(
            height: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Do you want to exit?"),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          exit(0);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.whiteTemp,
                        ),
                        child: const Text(
                          "Yes",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                        ),
                        child: const Text(
                          "No",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
