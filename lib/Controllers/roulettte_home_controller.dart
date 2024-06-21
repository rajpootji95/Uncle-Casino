

import 'dart:io';

import 'package:get/get.dart';
import 'package:roullet_app/Helper_Constants/other_constants.dart';
import 'package:roullet_app/utils.dart';

class HomeController extends GetxController{

  RxInt selectedCoin = 0.obs;
  RxList<int> selectedCoins = <int>[].obs;
  RxInt betAmount  = 0.obs;
  RxBool canceled = false.obs,canceledSpecificBet = false.obs;
  RxBool betPlaced = false.obs;
  RxList<int> selectedNumbers = <int>[].obs,totalSelectedNumbers = <int>[].obs;
  RxDouble coinWidth = (0.0).obs, coinHeight = (0.0).obs, extraFromLeft = (6.0).obs,fromTop = (Constants.screen.height*0.12).obs,
   fromLeft= (Constants.screen.width*0.66).obs;

  RxString userName = ''.obs, userUniqueId = ''.obs;
  RxDouble currentUserBalance = (0.0).obs, userBalance = (0.0).obs;

  changeCoinHeight(){
    coinHeight.value = 20;
    coinWidth.value = 20;
    fromTop.value = Constants.screen.height*0.09;
    fromLeft.value = Constants.screen.width*0.64;
  }

  changeCoinPosition(){
    coinWidth.value = 0;
    coinHeight.value =0;
    extraFromLeft.value = 40;
    fromTop.value = Constants.screen.height*0.04;
    fromLeft.value =Constants.screen.width *0.15;
  }

  resetCoinPosition(){
    coinWidth.value =0;
    coinHeight.value =0;
    extraFromLeft.value = 6;
    fromTop.value = Constants.screen.height*0.12;
    fromLeft.value =Constants.screen.width*0.66;
  }

  onCoinTap(int value,bool betTimeOver, Future<void> playSound ) {
    //seconds.value > 10 || seconds.value < 59
    canceled.value = false;
    canceledSpecificBet.value = false;
    if (!betTimeOver) {
      if(selectedCoin.value == value){
        selectedCoin.value = 0;
        return;
      }
      if (currentUserBalance - value >= 0) {
        selectedCoin.value = value;
        // widget.audioController.playSound(SoundSource.coinRemoveSoundPath,'coin_select');
        playSound;
      }
      else {
        Utils.mySnackBar(msg: "Your wallet balance is not Sufficient");
      }
    } else {
      Utils.mySnackBar(msg: "Bet Time Over...",maxWidth: 250);
    }
  }

  RxBool activeConnection = false.obs;

  Future checkUserConnection() async {
    String T = "";
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        activeConnection.value = true;
      }else{
        // setLogOut();
        T = "Turn On the data and repress again";
      }
    } on SocketException catch (_) {
      //setLogOut();
      activeConnection.value = false;
      T = "Turn On the data and repress again";
    }
    if(T.isNotEmpty){
      Utils.mySnackBar(msg: T);
    }
  }

  RxBool showSettings = false.obs;
}