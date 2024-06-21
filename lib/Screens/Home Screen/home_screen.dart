import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:blurrycontainer/blurrycontainer.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:roullet_app/Api%20Services/api_end_points.dart';
import 'package:roullet_app/Helper_Constants/Images_path.dart';
import 'package:roullet_app/Helper_Constants/colors.dart';
import 'package:roullet_app/Helper_Constants/other_constants.dart';
import 'package:roullet_app/Helper_Constants/sounds_source_path.dart';
import 'package:roullet_app/Scale%20Size/scale_size.dart';
import 'package:roullet_app/Screens/Home%20Screen/Home%20Widgets/bottom_boxes.dart';
import 'package:roullet_app/Screens/Home%20Screen/Home%20Widgets/right_bet-boxes.dart';
import 'package:roullet_app/Screens/Home%20Screen/Home%20Widgets/roulette_table.dart';
import 'package:roullet_app/Screens/Home%20Screen/Home%20Widgets/top_box_row.dart';
import 'package:roullet_app/Screens/Model/get_profile_model.dart';
import 'package:roullet_app/Screens/Settings/contact_us.dart';
import 'package:roullet_app/Screens/Settings/my_wining_list.dart';
import 'package:roullet_app/Widgets/coins_widget.dart';
import 'package:roullet_app/audio_controller.dart';
import 'package:roullet_app/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Api Services/requests.dart';
import '../Auth/login_screen.dart';
import '../Settings/about_us.dart';
import '../Settings/privacy_policy.dart';
import '../Settings/term_condition.dart';
import '../Update Password/change_password.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.audioController});
  final AudioController audioController;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int? selectedCoin;
  List<int> selectedCoins = [];
  int betAmount = 0;
  bool? canceled = false;
  bool? canceledSpecificBet = false;
  bool betPlaced = false;
  bool waiting = false;
  List<int> selectedNumbers = [];
  List<int> totalSelectedNumbers = [];
  double coinWidth = 0;
  double coinHeight = 0;
  double extraFromLeft = 6;
  double fromTop = Constants.screen.height * 0.12;
  double fromLeft = Constants.screen.width * 0.66;

  changeCoinHeight() {
    coinHeight = 20;
    coinWidth = 20;
    fromTop = Constants.screen.height * 0.09;
    fromLeft = Constants.screen.width * 0.64;
    setState(() {});
  }

  changeCoinPosition() {
    coinWidth = 0;
    coinHeight = 0;
    extraFromLeft = 40;
    fromTop = Constants.screen.height * 0.04;
    fromLeft = Constants.screen.width * 0.15;
    setState(() {});
  }

  resetCoinPosition() {
    coinWidth = 0;
    coinHeight = 0;
    extraFromLeft = 6;
    fromTop = Constants.screen.height * 0.12;
    fromLeft = Constants.screen.width * 0.66;
    setState(() {});
  }

  /// on select a coin
  onCoinTap(int value) {
    canceled = false;
    canceledSpecificBet = false;
    if (seconds.value > 10 || seconds.value < 59) {
      if (selectedCoin == value) {
        selectedCoin = null;
        setState(() {});
        return;
      }
      if (currentUserBalance - value >= 0) {
        selectedCoin = value;
        widget.audioController
            .playSound(SoundSource.coinRemoveSoundPath, 'coin_select');
        setState(() {});
      } else {
        Utils.mySnackBar(title: "Your wallet balance is not Sufficient");
      }
    } else {
      Utils.mySnackBar(title: "Bet Time Over...", maxWidth: 250);
    }
  }

  bool activeConnection = false;
  void _checkInternetConnection() async {
    String T = "";
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      T = "Turn On the data and repress again";
      setState(() {
        activeConnection = false;
      });
    }
    else {
      setState(() {
        activeConnection = true;
      });
    }
    if(T.isNotEmpty){
      Utils.mySnackBar(msg: T);
    }
    Connectivity().onConnectivityChanged.listen(
            (ConnectivityResult result) {
              /*
              bool active = result.any((element) =>
          element == ConnectivityResult.mobile ||
          element == ConnectivityResult.wifi ||
          element == ConnectivityResult.ethernet);*/
      String T = "";
      if (result == ConnectivityResult.none) {
        T = "Turn On the data and repress again";
        setState(() {
          activeConnection = false;
        });
      } else {
        setState(() {
          activeConnection = true;
        });
      }
      if(T.isNotEmpty){
        Utils.mySnackBar(msg: T);
      }
    } as void Function(List<ConnectivityResult> event)?);
  }


  Future checkUserConnection() async {
    String T = "";
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        activeConnection = true;
      } else {
        T = "Turn On the data and repress again";
        // setLogOut();
      }
    } on SocketException catch (_) {
      //setLogOut();
      activeConnection = false;
      T = "Turn On the data and repress again";
    }
    if (T.isNotEmpty) {
      Utils.mySnackBar(msg: T);
    }
  }

  ///start timer
  // ValueNotifier<int> minutes = ValueNotifier(0);
  ValueNotifier<int> seconds = ValueNotifier(0);
  Timer? timer;
  void startCountdown() {
    betPlaced = false;
    canceled = false;
    canceledSpecificBet = false;
    seconds.value = 60 - DateTime.now().second;
    const oneSec = Duration(seconds: 1); // Starting from 59 seconds
    timer = Timer.periodic(oneSec, (timer) {
      seconds.value = 60 - DateTime.now().second;
      widget.audioController
          .playSound(SoundSource.countDownSoundPath, 'count_down');
      if (seconds.value == 60) {
        startRotation() ;
      }
      if (seconds.value == 10) {
        widget.audioController.speak("Betting Time Over");
        canceled = false;
        canceledSpecificBet = false;
        setState(() {});
      }
      if (seconds.value == 4) {
        callWinningNumberApi();
      }
    });
  }

  Future<void> callWinningNumberApi() async {
    // checkUserConnection();
    getFinalNumberApi();
  }

  @override
  void dispose() {
    if (timer != null) {
      timer!.cancel();
    }
    _controller.dispose();
    super.dispose();
  }

  bool showSettings = false;
  ValueNotifier<double> rotationAngle = ValueNotifier(0);
  ValueNotifier<double> turns = ValueNotifier(0);
  static const rotationDuration = Duration(seconds: 12);
  Timer? rotationTimer;
  List<int> rouletteValues = [
    0,
    26,
    3,
    35,
    12,
    28,
    7,
    29,
    18,
    22,
    9,
    31,
    14,
    20,
    1,
    33,
    16,
    24,
    5,
    10,
    23,
    8,
    30,
    11,
    36,
    13,
    27,
    6,
    34,
    17,
    25,
    2,
    21,
    4,
    19,
    15,
    32
  ];
  List<String> lastTenWinningNumbers = [];
  bool showWheel = false;
  double rouletteHeight = 0;
  double rouletteWidth = 0;
  double rouletteFromTop = 0;
  double roulettePadding = 0;
  double rouletteCentreHeight = 0;

  void startRotation() async {
    canceled = false;
    canceledSpecificBet = false;
    changeRoulettePosition();
    setState(() {});
    bool isFinalNumberNull = finalNumber == null;
    int r = finalNumber ?? 0;
    int a = rouletteValues.indexOf(r) - 2;
    if (r == 0 || r == 26) {
      a = r == 0 ? 35 : 36;
    }
    rotationAngle.value = 0;
    rotationTimer = Timer(rotationDuration, () {});
    double i = 360 / 37;
    int round = 0;
    widget.audioController
        .playSound(SoundSource.spinWheelSoundPath, 'spin_wheel');
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (isFinalNumberNull && finalNumber != null) {
        debugPrint("re-assign final number....");
        r = finalNumber!;
        a = rouletteValues.indexOf(r) - 2;
        if (r == 0 || r == 26) {
          a = r == 0 ? 35 : 36;
        }
        isFinalNumberNull = false;
      }

      rotationAngle.value += i;
      turns.value -= 1.0 / 37;
      if (rotationAngle.value >= 360 && i == 360 / 37) {
        rotationAngle.value = 0;
      }
      if (round >= 60 &&
          round <= 120 &&
          rotationAngle.value >= (a == 14 ? 13 : a) * 360 / 37 &&
          rotationAngle.value < (a + 1) * 360 / 37) {
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
          i -= 180 / 37;
          if (a == 5) {
            if (i == 180 / 37) {
              rotationAngle.value = (a + 2) * 360 / 37;
              timer.cancel();
            }
          }
          if (i == 0) {
            rotationAngle.value = (a + 2) * 360 / 37;
            timer.cancel();
          }
        });
      }
      if (i == 0) {
        timer.cancel();
        debugPrint("angle = $rotationAngle");
        debugPrint("round = $round");
        if (r == 26) {
          rotationAngle.value = 360 / 37;
        }
        winningNumber = calculateRouletteNumber(rotationAngle.value);
        setState(() {
          betPlaced = true;
        });
        getProfile().then((value) {
          userBalance = double.parse(value?.data.first.wallet ?? "");
          currentUserBalance = userBalance;
        });
        ApiRequests().getPrimaryWalletAmountApi().then((value) {
          primaryAmount = value;
        });
        Future.delayed(300.milliseconds, () {
          showWinOrLossDialog(context);
        });
        // ApiRequests().getLastTenWinnerNumbersApi(context).then((value){
        //   if(value!= null){
        //       lastTenWinningNumbers = [];
        //       for (var winner in value) {
        //         lastTenWinningNumbers.add(winner["numbers"]??"");
        //       }
        //     debugPrint("last ten winners ==> $lastTenWinningNumbers");
        //   }
        // });
      }
      round++;
    });
  }

  ///calculate Roulette number
  int? calculateRouletteNumber(rouletteAngle) {
    double section = 360 / 37;
    double halfSection = section / 2;
    double getDegree = rouletteAngle + halfSection;
    int? rouletteValue;
    for (int i = 0; i <= 37; i++) {
      if (getDegree >= i * section && getDegree <= (i + 1) * section) {
        if (i != 37) {
          rouletteValue = rouletteValues[i];
        } else {
          rouletteValue = 0;
        }
      }
    }
    debugPrint("winning number = $rouletteValue");
    return rouletteValue;
  }

  /// calculate winning amount
  calculateWinningAmount() {}

  /// win loss dialog
  showWinOrLossDialog(context) {
    bool win = false;
    if (totalSelectedNumbers.contains(winningNumber)) {
      widget.audioController.speak("Congratulations!!");
      double amount =
          double.parse(primaryAmount ?? "0") + (currentWinningAmount ?? 0.0);
      primaryAmount = amount.toString();
      win = true;
    }else{
      widget.audioController.speak("you lost....");
    }
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (_) {
          ApiRequests().getPrimaryWalletAmountApi();
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pop(context);
            resetRoulettePosition();
            setState(() {
              finalNumber = null;
              selectedCoins = [];
              totalSelectedNumbers = [];
              betPlaced = false;
              currentWinningAmount = 0;
              canceled = true;
              betAmount = 0;
            });
          });
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    /*\n ₹${winningAmount ?? "0"}*/
                    win
                        ? "You Win🎉\n ₹${currentWinningAmount ?? "0"}"
                        : "You Lost😞",
                    style: const TextStyle(
                      color: colors.primary,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    "Winning Number: $winningNumber",
                    style: const TextStyle(
                      color: colors.secondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  late AnimationController _controller;
  late Animation<double> _animation;
  // late Animation<double> _blinkAnimation;
  changeRoulettePosition() {
    rouletteHeight = h;
    rouletteWidth = w;
    rouletteFromTop = 0;
    roulettePadding = h * 0.1;
    rouletteCentreHeight = h * 0.63;
  }

  resetRoulettePosition() {
    rouletteHeight = w * 0.19;
    rouletteWidth = w * 0.19;
    rouletteFromTop = h * 0.27;
    roulettePadding = 0;
    rouletteCentreHeight = h * 0.305;
  }

  @override
  void initState() {
    super.initState();
    // TODO: implement initState

    getData();
    resetRoulettePosition();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _animation = Tween<double>(
      begin: 0,
      end: 2 * 3.1416,
    ).animate(_controller);
    _controller.repeat();
  }

  double h = Constants.screen.height;
  double w = Constants.screen.width;
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
    return SafeArea(
      child: PopScope(
        canPop: true,
        onPopInvoked: (val) {
          if (timer != null) {
            timer!.cancel();
          }
          //showExitPopup(context);
        },
        child: Scaffold(
            body: Stack(
          children: [
            Container(
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
            ),
            Positioned(
                top: 6,
                left: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Your Balance :",
                          textScaler: TextScaler.linear(
                              ScaleSize.textScaleFactor(w,
                                  maxTextScaleFactor: 2)),
                          style: const TextStyle(
                            color: colors.whiteTemp,
                          ),
                        ),
                        SizedBox(
                          width: w * 0.005,
                        ),
                        AnimatedSwitcher(
                          duration: 700.milliseconds,
                          child: Text(
                            currentUserBalance.toString(),
                            textScaler: TextScaler.linear(
                                ScaleSize.textScaleFactor(w,
                                    maxTextScaleFactor: 2)),
                            style: const TextStyle(
                              color: colors.whiteTemp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "Bet Amount:",
                          textScaler: TextScaler.linear(
                              ScaleSize.textScaleFactor(w,
                                  maxTextScaleFactor: 2)),
                          style: const TextStyle(
                            color: colors.whiteTemp,
                          ),
                        ),
                        SizedBox(
                          width: w * 0.005,
                        ),
                        Text(
                          betAmount.toString(),
                          textScaler: TextScaler.linear(
                              ScaleSize.textScaleFactor(w,
                                  maxTextScaleFactor: 2)),
                          style: const TextStyle(
                            color: colors.whiteTemp,
                          ),
                        ),
                      ],
                    ),
                  ],
                )),
            Positioned(
                top: 6,
                right: 20,
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (seconds.value < 11 || seconds.value > 58) {
                          Utils.mySnackBar(msg: 'Bet Time Over!!', maxWidth: 250);
                          return;
                        }
                        setState(() {
                          showSettings = !showSettings;
                          canceled = false;
                          canceledSpecificBet = false;
                        });
                      },
                      child: const Icon(
                        Icons.settings,
                        color: colors.white70,
                      ),
                    ),
                  ],
                )),
            Positioned(
                top: 6,
                right: 50,
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          widget.audioController.muteAudio();
                        });
                      },
                      child: Icon(
                        widget.audioController.mute
                            ? Icons.volume_off
                            : Icons.volume_up_rounded,
                        color: colors.white70,
                      ),
                    ),
                  ],
                )),
            SizedBox(
              height: h * 0.07,
            ),
            Positioned(
              left: 12,
              bottom: 16,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: GestureDetector(
                    onTap: () {
                      showExitPopup(context);
                    },
                    child: Image.asset(
                      ImagesPath.exitImage,
                      width: w * 0.15,
                    )),
              ),
            ),
            // Positioned(
            //   top: 0,
            //   left: 0,
            //   child: BaseAnimationWidget(
            //     type: AnimationType.OFFSET,
            //     duration: const Duration(milliseconds: 1000),
            //     body: CoinWidget(
            //       selected: selectedCoin == 50,
            //       foreGroundColor: Colors.teal.shade700,
            //       text: "50",
            //       onTap: () {
            //         // onCoinTap(50);
            //       },
            //       // selected: selectedCoin == 50,
            //     ),
            //     offset: const Offset(255, 237),
            //     offsetType: OffsetType.UP,
            //     animationSwitch: () => _animationSwitch,
            //   ),
            // ),
            Align(
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  Stack(
                    children: [
                      TopBoxesRow(
                        h: h,
                        w: w,
                        // minuteM: minutes,
                        secondS: seconds,
                        //   countDown: countdownTimer(onChange: (remainingSeconds){
                        //   // if(remainingSeconds %2 ==0){
                        //   //     playAudio(SoundSource.countDownSoundPath);
                        //   //   }
                        //     debugPrint(remainingSeconds.toString());
                        // }),
                        primaryWalletAmount: primaryAmount ?? "0",
                        // countDown: countDownStream,
                      ),
                      AnimatedPositioned(
                        duration: 900.milliseconds,
                        width: coinWidth,
                        height: coinHeight,
                        curve: Curves.easeIn,
                        top: fromTop,
                        left: fromLeft+extraFromLeft+extraFromLeft,
                        child:Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                                colors: [colors.whiteTemp,colors.goldCoinColor,colors.goldCoinColor,]),
                            boxShadow: [
                              BoxShadow(
                                  color: colors.borderColorDark,
                                  offset: Offset(2,2)
                              )
                            ],


                          ),
                          child:  Center(child: Text("₹",style: TextStyle(color: colors.blackTemp.withOpacity(0.4) ),)),
                        ),
                      ),

                      AnimatedPositioned(
                        duration: 700.milliseconds,
                        width: coinWidth,
                        height: coinHeight,
                        curve: Curves.easeIn,
                        top: fromTop,
                        left: fromLeft+extraFromLeft,
                        child:Container(
                          decoration: const BoxDecoration(
                              color: colors.goldCoinColor,
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                  colors: [colors.whiteTemp,colors.goldCoinColor,colors.goldCoinColor,]),
                              boxShadow: [
                                BoxShadow(
                                    color: colors.borderColorDark,
                                    offset: Offset(2,2)
                                )
                              ]
                          ),
                          child:  Center(child: Text("₹",style: TextStyle(color: colors.blackTemp.withOpacity(0.4) ),)),
                        ),
                      ),
                      AnimatedPositioned(
                          duration: 500.milliseconds,
                          width: coinWidth,
                          height: coinHeight,
                          curve: Curves.easeIn,
                          top: fromTop,
                          left: fromLeft,
                          child: Container(
                            decoration:const BoxDecoration(
                                color: colors.goldCoinColor,
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                    colors: [colors.white70,colors.goldCoinColor,colors.goldCoinColor,]),
                                boxShadow: [
                                  BoxShadow(
                                      color: colors.borderColorDark,
                                      offset: Offset(2,2)
                                  )
                                ]
                            ),
                            child:  Center(child: Text("₹",style: TextStyle(color: colors.blackTemp.withOpacity(0.4) ),)),
                          )
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                          onTap: () {
                            canceled = false;
                            canceledSpecificBet = false;
                            if (seconds.value > 10 || seconds.value < 59) {
                              if (selectedNumbers.isNotEmpty &&
                                  selectedCoins.isNotEmpty) {
                                widget.audioController.playSound(
                                    SoundSource.tableNumberRemoveSoundPath,
                                    'cancel');
                                ApiRequests().cancelBetApi("single");
                                canceledSpecificBet = true;
                                betId = null;
                                winningNumber = null;
                                betAmount -= selectedCoins.last;
                                currentUserBalance += selectedCoins.last;
                                selectedCoins.removeLast();
                                totalSelectedNumbers.removeRange(
                                    totalSelectedNumbers.length -
                                        selectedNumbers.length,
                                    totalSelectedNumbers.length);
                                debugPrint(
                                    "totalNumbers = $totalSelectedNumbers");
                                setState(() {});
                              } else {
                                Utils.mySnackBar(title: "Please select a bet", maxWidth: 250);
                              }
                            } else {
                              Utils.mySnackBar(
                                  title: "Bet Time Over , can't cancel now",);
                            }
                          },
                          child: BetBox(
                              text: "Cancel\n Specific Bet", w: w, h: h)),
                      SizedBox(
                        width: w * 0.02,
                      ),
                      // BaseAnimationWidget(
                      //   type: AnimationType.OFFSET,
                      //   duration: const Duration(milliseconds: 500),
                      //   body: CoinWidget(
                      //     selected: selectedCoin == 50,
                      //     foreGroundColor: Colors.teal.shade700,
                      //     text: "50",
                      //     onTap: () {
                      //       // onCoinTap(50);
                      //     },
                      //     // selected: selectedCoin == 50,
                      //   ),
                      //   offset: const Offset(277.5, 260.5),
                      //   offsetType: OffsetType.UP,
                      //   animationSwitch: () => _animationSwitch,
                      // ),
                      CoinWidget(
                        selected: selectedCoin == 10,
                        foreGroundColor: Colors.brown,
                        text: "10",
                        onTap: () {
                          onCoinTap(10);
                        },
                        // selected: selectedCoin == 50,
                      ),
                      SizedBox(
                        width: w * 0.02,
                      ),
                      CoinWidget(
                        selected: selectedCoin == 20,
                        foreGroundColor: Colors.yellow.shade700,
                        text: "20",
                        onTap: () {
                          onCoinTap(20);
                        },
                        // selected: selectedCoin == 50,
                      ),
                      SizedBox(
                        width: w * 0.02,
                      ),
                      CoinWidget(
                        selected: selectedCoin == 50,
                        foreGroundColor: Colors.teal.shade700,
                        text: "50",
                        onTap: () {
                          onCoinTap(50);
                        },
                        // selected: selectedCoin == 50,
                      ),
                      SizedBox(
                        width: w * 0.02,
                      ),
                      CoinWidget(
                        selected: selectedCoin == 100,
                        foreGroundColor: Colors.red.shade900,
                        text: "100",
                        onTap: () {
                          onCoinTap(100);
                        },
                        // selected: selectedCoin == 100,
                      ),
                      SizedBox(
                        width: w * 0.02,
                      ),
                      CoinWidget(
                        selected: selectedCoin == 200,
                        foreGroundColor: Colors.yellow.shade900,
                        text: "200",
                        onTap: () {
                          onCoinTap(200);
                        },
                        // selected: selectedCoin == 200,
                      ),
                      SizedBox(
                        width: w * 0.02,
                      ),
                      CoinWidget(
                        selected: selectedCoin == 500,
                        foreGroundColor: Colors.blueGrey.shade700,
                        text: "500",
                        onTap: () {
                          onCoinTap(500);
                        },
                        // selected: selectedCoin == 500,
                      ),
                      SizedBox(
                        width: w * 0.02,
                      ),
                      CoinWidget(
                        selected: selectedCoin == 1000,
                        foreGroundColor: Colors.pink.shade900,
                        text: "1000",
                        onTap: () {
                          onCoinTap(1000);
                        },
                        // selected: selectedCoin == 1000,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: h * 0.02,
                  ),
                  RouletteTable(
                    isBetTimeOverAndBetPlaced: (
                      seconds.value < 11 || seconds.value > 58,
                      betPlaced
                    ),
                    winningAmount: (amount) {
                      currentWinningAmount = amount;
                      // debugPrint("amount changes $currentWinningAmount");
                    },
                    selectedCoin: /*userBalance <= 0 || */
                        currentUserBalance <= 0 ||
                                (selectedCoin ?? 0) > currentUserBalance
                            ? 0
                            : selectedCoin ?? 0,
                    isClearSpecificOrReset: (
                      canceledSpecificBet ?? false,
                      canceled ?? false
                    ),
                    onChanged: (v) {
                      if (v) {
                        canceled = false;
                        canceledSpecificBet = false;
                        setState(() {});
                      }
                    },
                    selectedBetNumbers: (selectedNumbersAndCoinFromTable) {
                      if (selectedNumbersAndCoinFromTable.$1.isNotEmpty &&
                          selectedNumbersAndCoinFromTable.$2 != 0) {
                        canceled = false;
                        canceledSpecificBet = false;
                        selectedNumbers = selectedNumbersAndCoinFromTable.$1;
                        totalSelectedNumbers
                            .addAll(selectedNumbersAndCoinFromTable.$1);
                        selectedCoins.add(selectedNumbersAndCoinFromTable.$2);
                        setState(() {});
                        betAmount += selectedCoins.last;
                        currentUserBalance = userBalance - betAmount;
                        debugPrint(
                            "total selected numbers : $totalSelectedNumbers");
                        debugPrint(
                            "selected numbers ==> ${selectedNumbersAndCoinFromTable.$1}\n"
                            "selected coins ==> $selectedCoins");
                      }
                    },
                    winningNumber: winningNumber,
                    idChanged: (id) {
                      betId = id;
                      debugPrint("bet id = $betId");
                      widget.audioController.playSound(
                          SoundSource.numberClickSoundPath, 'number_tap');
                      if (betId != null &&
                          selectedNumbers.isNotEmpty &&
                          selectedCoins.isNotEmpty) {
                        ApiRequests().placeBetApi(
                          selectedCoins.last,
                          betId,
                          selectedNumbers,
                        );
                      }
                    },
                  ),
                  SizedBox(
                    height: h * 0.03,
                  ),
                  BottomBoxes(
                    onTake: () async {
                      if (seconds.value < 11 || seconds.value > 58) {
                        Utils.mySnackBar(title: "Bet Time over!!", maxWidth: 250);
                        return;
                      }
                      if (primaryAmount != null && primaryAmount != '0') {
                        widget.audioController.playSound(
                            SoundSource.tableNumberRemoveSoundPath, 'cancel');
                        setState(() {
                          canceled = false;
                          canceledSpecificBet = false;
                        });
                        await ApiRequests()
                            .addToWalletAmountApi()
                            .then((value) {
                          if (value.$1 == false) {
                            double collectableAmount =
                                double.parse(primaryAmount ?? "0");
                            widget.audioController.playSound(
                                SoundSource.coinCollectSoundPath,
                                'coin_collect');
                            primaryAmount = "0";
                            changeCoinHeight();
                            Future.delayed(900.milliseconds, () {
                              currentUserBalance += collectableAmount;
                              userBalance = currentUserBalance;
                              changeCoinPosition();
                              Future.delayed(1.seconds, () {
                                resetCoinPosition();
                              });
                            });
                          } else if (value.$2 == "Primary Wallet Empty !") {
                            primaryAmount = "0";
                            setState(() {});
                          }
                        });
                      } else {}
                    },
                    onCanceled: () {
                      canceled = false;
                      canceledSpecificBet = false;
                      if (seconds.value > 10 || seconds.value < 59) {
                        if (selectedCoins.isNotEmpty &&
                            selectedNumbers.isNotEmpty) {
                          widget.audioController.playSound(
                              SoundSource.tableNumberRemoveSoundPath, 'cancel');
                          ApiRequests().cancelBetApi("all");
                          canceled = true;
                          betId = null;
                          winningNumber = null;
                          currentUserBalance += betAmount;
                          betAmount = 0;
                          selectedCoins = [];
                          selectedNumbers = [];
                          totalSelectedNumbers = [];
                          setState(() {});
                        } else {
                          Utils.mySnackBar(title: "Please select a bet", maxWidth: 250);
                        }
                      } else {
                        Utils.mySnackBar(title: "Bet Time Over , can't cancel now");
                      }
                    },
                  )
                ],
              ),
            ),
            // Positioned(
            //   top: h*0.4,
            //     left: w*0.085,
            //     child: Opacity(
            //       opacity: opacity,
            //       child: Text(
            //         opacity !=0 && selectedCoin != null? lastCoin != null?"+$lastCoin":"-$selectedCoin":"",
            //         textScaler: TextScaler.linear(ScaleSize.textScaleFactor(w,maxTextScaleFactor: 3.5)),
            //         style: const TextStyle(
            //           color: colors.whiteTemp,
            //           fontWeight: FontWeight.bold,
            //         ),
            //       ),
            //     )),
            AnimatedPositioned(
              /*w * 0.19*/
              /*h*0.27*/
              duration: 1.seconds,
              top: rouletteFromTop,
              height: rouletteHeight,
              width: rouletteWidth,
              onEnd: () {
                setState(() {
                  showWheel = !showWheel;
                });
              },
              child: BlurryContainer(
                  blur: 2,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: roulettePadding),
                  /*// decoration: const BoxDecoration(boxShadow: [
                  //   BoxShadow(
                  //       color: Colors.black38,
                  //       blurRadius: 60,
                  //       spreadRadius: 12,
                  //       offset: Offset(1, 24))
                  // ]),*/
                  child: showWheel
                      ? Stack(alignment: Alignment.topCenter, children: [
                          ValueListenableBuilder(
                            valueListenable: turns,
                            builder: (_, turnsValue, child) {
                              return AnimatedRotation(
                                turns: turnsValue,
                                duration: 12.seconds,
                                child: Image.asset(
                                  ImagesPath.rouletteImage,
                                  // height: h*0.85,
                                ),
                              );
                            },
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: ValueListenableBuilder(
                                valueListenable: rotationAngle,
                                builder: (
                                  context,
                                  rotationAngleValue,
                                  child,
                                ) {
                                  return Transform.rotate(
                                    angle: rotationAngleValue * 3.14 / 180,
                                    // Convert degrees to radians
                                    child: Image.asset(
                                      ImagesPath.rouletteCenterImage,
                                      height: rouletteCentreHeight,
                                    ),
                                  );
                                }),
                          ),
                          const Icon(Icons.place,
                              size: 30, color: colors.yellow)
                        ])
                      : AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return Stack(
                                alignment: Alignment.topCenter,
                                children: [
                                  Transform.rotate(
                                    angle: -_animation.value / 2,
                                    child: Image.asset(
                                      ImagesPath.rouletteImage,
                                      // height: h*0.4,
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.center,
                                    child: Transform.rotate(
                                      angle: _animation.value,
                                      // Convert degrees to radians
                                      child: Image.asset(
                                        ImagesPath.rouletteCenterImage,
                                        height: rouletteCentreHeight,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.place,
                                      size: 30, color: colors.yellow)
                                ]);
                          })),
            ),
            /*showWheel
                ? Align(
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        BlurryContainer(
                          blur: 2,
                          height: h,
                          width: w,
                          padding: const EdgeInsets.all(24),
                          elevation: 0,
                          child: Container(
                            alignment: Alignment.center,
                            child: Stack(
                                alignment: Alignment.topCenter,
                                children: [
                                  ValueListenableBuilder(
                                    valueListenable: turns,
                                    builder: (_,turnsValue, child){
                                      return  AnimatedRotation(
                                        turns: turnsValue,
                                        duration: 12.seconds,
                                        child: Image.asset(
                                          ImagesPath.rouletteImage,

                                        ),
                                      );
                                    },
                                  ),
                                  Align(
                                    alignment: Alignment.center,
                                    child: ValueListenableBuilder(
                                    valueListenable: rotationAngle,
                                    builder: (
                                      context,
                                      rotationAngleValue,
                                      child,
                                    ) {
                                      return Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Transform.rotate(
                                          //   angle: -(rotationAngleValue *
                                          //       3.14 /
                                          //       550),
                                          //   child: Image.asset(
                                          //     ImagesPath.rouletteImage,
                                          //     scale: 1,
                                          //   ),
                                          // ),
                                          Transform.rotate(
                                            angle: rotationAngleValue *
                                                3.14 /
                                                180,
                                            // Convert degrees to radians
                                            child: Image.asset(
                                              ImagesPath.rouletteCenterImage,
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                              ),

                              const Icon(
                                  Icons.place,
                                  size: 30,
                                  color: colors.yellow)
                            ]),
                          ),
                        ),
                        close
                            ? Positioned(
                                right: 12,
                                top: 12,
                                child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        canceled = false;
                                        canceledSpecificBet = false;
                                        showWheel = !showWheel;
                                      });
                                      refresh();
                                    },
                                    icon: const Icon(
                                      Icons.close,
                                      color: colors.grad2Color,
                                    )))
                            : const SizedBox.shrink()
                      ],
                    ),
                  )
                : const SizedBox(),*/
            showSettings
                ? Align(
                    alignment: Alignment.bottomRight,
                    child: Stack(
                      children: [
                        AnimatedContainer(
                          decoration: const BoxDecoration(
                              color: colors.white70,
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  bottomLeft: Radius.circular(80))),
                          height: h * 0.9,
                          width: w * 0.25,
                          duration: const Duration(milliseconds: 1000),
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // const SizedBox(height: 20,),
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    color: colors.secondary,
                                    child: Row(
                                      children: [
                                        const CircleAvatar(
                                          radius: 20,
                                          backgroundColor: colors.whiteTemp,
                                          child: Icon(
                                            Icons.person,
                                            size: 30,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 5,
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text("$userName",
                                                style: const TextStyle(
                                                    color: colors.whiteTemp)),
                                            Text("$userUniqueId",
                                                style: const TextStyle(
                                                    color: colors.whiteTemp)),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  InkWell(
                                    onTap: () {
                                      timer?.cancel();
                                      showSettings = false;
                                      Get.to(() => const WinningList())
                                          ?.then((value) {
                                        refresh();
                                        startCountdown();
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      color: colors.secondary,
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.wallet,
                                            color: colors.whiteTemp,
                                          ),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Text(
                                            "Winner Number",
                                            style: TextStyle(
                                              color: colors.whiteTemp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  InkWell(
                                    onTap: () {
                                      timer?.cancel();
                                      showSettings = false;
                                      Get.to(() => ChangePassword())
                                          ?.then((value) {
                                        startCountdown();
                                        refresh();
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      color: colors.secondary,
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.lock_outlined,
                                            color: colors.whiteTemp,
                                          ),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Text(
                                            "Change Password",
                                            style: TextStyle(
                                              color: colors.whiteTemp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),

                                  InkWell(
                                    onTap: () {
                                      timer?.cancel();
                                      showSettings = false;
                                      Get.to(() => const PrivacyPolicy())
                                          ?.then((value) {
                                        refresh();
                                        startCountdown();
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      color: colors.secondary,
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.settings,
                                            color: colors.whiteTemp,
                                          ),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Text(
                                            "Privacy Policy",
                                            style: TextStyle(
                                              color: colors.whiteTemp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),

                                  InkWell(
                                    onTap: () {
                                      timer?.cancel();
                                      showSettings = false;
                                      Get.to(() => const TermAndCondition())
                                          ?.then((value) {
                                        refresh();
                                        startCountdown();
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      color: colors.secondary,
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.settings,
                                            color: colors.whiteTemp,
                                          ),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Text(
                                            "Term & Conditions",
                                            style: TextStyle(
                                              color: colors.whiteTemp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  InkWell(
                                    onTap: () {
                                      timer?.cancel();
                                      showSettings = false;
                                      Get.to(() => const AboutUs())
                                          ?.then((value) {
                                        refresh();
                                        startCountdown();
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      color: colors.secondary,
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.settings,
                                            color: colors.whiteTemp,
                                          ),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Text(
                                            "About Us",
                                            style: TextStyle(
                                              color: colors.whiteTemp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  InkWell(
                                    onTap: () {
                                      timer?.cancel();
                                      showSettings = false;
                                      Get.to(() => const ContactUs())
                                          ?.then((value) {
                                        refresh();
                                        startCountdown();
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      color: colors.secondary,
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.settings,
                                            color: colors.whiteTemp,
                                          ),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Text(
                                            "Contact Us",
                                            style: TextStyle(
                                              color: colors.whiteTemp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  InkWell(
                                    onTap: () {
                                      showLogOutPopup(context);
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: colors.secondary,
                                        borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(25)),
                                      ),
                                      padding: const EdgeInsets.all(5),
                                      child: const Padding(
                                        padding: EdgeInsets.only(left: 5),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.logout_outlined,
                                              color: colors.whiteTemp,
                                            ),
                                            SizedBox(
                                              width: 5,
                                            ),
                                            Text(
                                              "Logout",
                                              style: TextStyle(
                                                color: colors.whiteTemp,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(),
            activeConnection
                ? const SizedBox.shrink()
                : const BlurryContainer(
                    child: Center(
                    child: CupertinoActivityIndicator(
                      color: colors.whiteTemp,
                    ),
                  )),
          ],
        )),
      ),
    );
  }

  ///store UserID

  // getUserId() async {
  //   SharedPreferences preferences = await SharedPreferences.getInstance();
  //   userId = preferences.getString("userId");
  //   getPrimaryWalletApi();
  // }

  String? userId;
  String? userName, userUniqueId;
  String? primaryAmount;
  double currentUserBalance = 0;
  double userBalance = 0;
  Future<void> getData() async {
    _checkInternetConnection();
    // await checkUserConnection();
    await getProfile();
    startCountdown();
    userName = getProfileModel?.data.first.username ?? "";
    userUniqueId = getProfileModel?.data.first.loginId ?? "";
    userBalance = double.parse(getProfileModel?.data.first.wallet ?? "0");
    currentUserBalance = userBalance;
    primaryAmount = await ApiRequests().getPrimaryWalletAmountApi();
    setState(() {});
  }

  int? winningNumber;
  int? betId;

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
                              backgroundColor: colors.whiteTemp),
                          child: const Text("Yes",
                              style: TextStyle(color: Colors.black)),
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
                        child: const Text("No",
                            style: TextStyle(color: Colors.white)),
                      ))
                    ],
                  )
                ],
              ),
            ),
          );
        });
  }

  Future<bool> showLogOutPopup(context) async {
    return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white30,
            content: SizedBox(
              height: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Are you sure you want to logout?",
                    style: TextStyle(color: colors.whiteTemp),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (timer != null && timer!.isActive) {
                              timer!.cancel();
                            }
                            setLogOut();
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: colors.whiteTemp),
                          child: const Text("Logout",
                              style: TextStyle(color: Colors.black)),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                          child: ElevatedButton(
                        onPressed: () {
                          debugPrint('no selected');
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                        ),
                        child: const Text("No",
                            style: TextStyle(color: Colors.white)),
                      ))
                    ],
                  )
                ],
              ),
            ),
          );
        });
  }

  int? finalNumber;
  Future<bool> getFinalNumberApi() async {
    debugPrint("final number api called");
    canceled = false;
    canceledSpecificBet = false;
    var response = await http
        .get(Uri.parse("${Endpoints.baseUrl}${Endpoints.getFinalNumber}"));
    // request.headers.addAll(headers);

    dynamic finalResult;
    debugPrint("final api calling.. statuscode :${response.statusCode}");
    if (response.statusCode == 200) {
      // getWinnerNumberApi();
      debugPrint("final number api response : ${response.body}");
      var result = response.body;
      finalResult = jsonDecode(result);
      if (!(finalResult['error'] ?? true)) {
        getWinnerNumberApi();
      } else {
        getFinalNumberApi();
      }
    } else {
      debugPrint('final api error: ${response.reasonPhrase}');
    }
    return finalResult != null ? finalResult['error'] ?? true : true;
  }

  Future<void> getWinnerNumberApi() async {
    debugPrint("winning number api called");
    canceled = false;
    canceledSpecificBet = false;
    var response = await http
        .get(Uri.parse("${Endpoints.baseUrl}${Endpoints.getWinnerNumber}"));
    debugPrint("winning api calling.. status code :${response.statusCode}");
    if (response.statusCode == 200) {
      debugPrint("win api calling.. status code :${response.body}");
      var result = response.body;
      var finalResult = jsonDecode(result);
      debugPrint("final result winning : $finalResult");
      if (finalResult['error'] == false) {
        finalNumber = int.parse(finalResult['winning_number']);
        debugPrint("final number:$finalNumber");
      } else {
        getWinnerNumberApi();
        // setLogOut();
      }
    } else {
      getWinnerNumberApi();
      debugPrint(response.reasonPhrase);
    }
  }

  GetProfileModel? getProfileModel;
  Future<GetProfileModel?> getProfile() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    userId = preferences.getString("userId");
    var headers = {'Cookie': 'ci_session=3s8dqkgvv46gsrpbcm2b10qpegedlr5e'};
    var request = http.MultipartRequest(
        'POST', Uri.parse('${Endpoints.baseUrl}${Endpoints.getProfile}'));
    request.fields.addAll({'user_id': userId ?? ""});
    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      var result = await response.stream.bytesToString();
      var finalResult = GetProfileModel.fromJson(json.decode(result));
      getProfileModel = finalResult;
      setState(() {});
    } else {
      Utils.mySnackBar(title: "Something went wrong!! Please logout and Login again");
      debugPrint(response.reasonPhrase);
    }
    return getProfileModel;
  }

  double? currentWinningAmount;

  refresh() async {
    betPlaced = false;
    canceled = true;
    selectedCoin = null;
    betAmount = 0;
    selectedCoins = [];
    selectedNumbers = [];
    winningNumber = null;
    finalNumber = null;
    betId = null;
    // await betTimeCount();
    // startCountdown();
    await getProfile();
    setState(() {});
  }

  setLogOut() async {
    if (timer != null) {
      timer!.cancel();
    }
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setBool("isLoggedIn", false);
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => LoginScreen(
                  audioController: widget.audioController,
                )));
  }
}
