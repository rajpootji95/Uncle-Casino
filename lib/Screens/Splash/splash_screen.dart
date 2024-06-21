import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:page_transition/page_transition.dart';
import 'package:roullet_app/Controllers/storage_controller.dart';
import 'package:roullet_app/Helper_Constants/colors.dart';
import 'package:roullet_app/Helper_Constants/other_constants.dart';
import 'package:roullet_app/Screens/Auth/login_screen.dart';
import 'package:roullet_app/Screens/Splash/select_game_type.dart';
import 'package:roullet_app/audio_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Helper_Constants/Images_path.dart';

class SplashScreen extends StatelessWidget {
   SplashScreen({Key? key, required this.audioController})
      : super(key: key);
  final AudioController audioController;
  final StorageController storageController = Get.put(StorageController());

  @override
  Widget build(BuildContext context) {
    double h = Constants.screen.height;
    double w = Constants.screen.width;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
    return Scaffold(
      body: Container(
        height: h,
        width: w,
        decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [
              colors.secondary,
              colors.primary,
              colors.secondary,
            ]),
            image: DecorationImage(
                image: AssetImage(ImagesPath.backGroundImage),
                fit: BoxFit.fill)),
        child: SizedBox(
          height: 200,
          width: 200,
          child: AnimatedSplashScreen.withScreenFunction(
            splash: ImagesPath.mainLogoImage,
            duration: 2000,
            screenFunction: () async {
              return checkLogIn(context);
            },
            splashTransition: SplashTransition.scaleTransition,
            curve: Curves.easeInCubic,
            pageTransitionType: PageTransitionType.fade,
            animationDuration: const Duration(milliseconds: 1500),
            splashIconSize: 250,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
    );
  }

  Future<Widget> checkLogIn(context) async {
    audioController.startMusic();
    SharedPreferences preferences = await SharedPreferences.getInstance();
    bool? isLoggedIn = preferences.getBool("isLoggedIn");
    // bool isLoggedIn = storageController.getLogin();
    debugPrint("already login $isLoggedIn");
    return navigate(isLoggedIn??false, context);
  }

  Widget navigate(isLoggedIn, context) {
    if (isLoggedIn) {
      return SelectGame(
        audioController: audioController,
      );
    } else {
      return LoginScreen(
        audioController: audioController,
      );
    }
  }
}
