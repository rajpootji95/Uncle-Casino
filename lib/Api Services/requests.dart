import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:http/http.dart' as http;
import 'package:roullet_app/Api%20Services/api_end_points.dart';
import 'package:roullet_app/Helper_Constants/colors.dart';
import 'package:roullet_app/Screens/Splash/select_game_type.dart';
import 'package:roullet_app/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiRequests {
  final String baseUrl = Endpoints.baseUrl;
  final String login = Endpoints.login;
  final String placeBetRequest = Endpoints.placeBet;
  final String changePassword = Endpoints.changePasswordRequest;

  String? userId;

  ///show loader
  showLoader(){

    Get.dialog(
        const Dialog(
          backgroundColor: Colors.transparent,
          child: SizedBox(
            child:  CupertinoActivityIndicator(
              color: colors.whiteTemp,
              radius: 20,
            ),
          ),
        ),
    );
  }

  /// login api
  Future<void> userLogin(String mobile, String password,audioController) async {
    var headers = {'Cookie': 'ci_session=c7797mp92d9k6gmq38epdr8hm70h9vab'};
    var request = http.MultipartRequest('POST', Uri.parse("$baseUrl$login"));
    request.fields.addAll({'mobile': mobile, 'password': password});

    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();
    debugPrint("status code : ${response.statusCode}");
    if (response.statusCode == 200) {

      var result = await response.stream.bytesToString();
      var finalResult = jsonDecode(result);
      if (finalResult['error'] == false) {
        SharedPreferences preferences = await SharedPreferences.getInstance();
        preferences.setBool("isLoggedIn", true);
        preferences.setString("userId", finalResult['data']['id'] ?? "");
        preferences.setString(
            "userName", finalResult['data']['username'] ?? "");
        preferences.setString("userEmail", finalResult['data']['email'] ?? "");

        Get.to(SelectGame(audioController:audioController));
        } else {
        Utils.mySnackBar(title: '${finalResult['message']}');
      }
    } else {
      debugPrint(response.reasonPhrase);
    }
  }

  /// change password api
  Future<bool> changePasswordApi(String oldPassword, String newPassword, String confirmPassword,) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    userId = preferences.getString("userId");
    var headers = {'Cookie': 'ci_session=c7797mp92d9k6gmq38epdr8hm70h9vab'};
    var request =
        http.MultipartRequest('POST', Uri.parse("$baseUrl$changePassword"));
    request.fields.addAll({
      'user_id': userId.toString(),
      'old_password': oldPassword,
      'new_password': newPassword,
      'confirm_password': confirmPassword
    });
    debugPrint(request.fields.toString());
    request.headers.addAll(headers);
    bool error = true;
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      var result = await response.stream.bytesToString();
      debugPrint("response $result");
      var finalResult = jsonDecode(result);
      error = finalResult['error']??true;
      if (finalResult['error'] == false) {
        Get.back();
        Utils.mySnackBar(title: 'Success',msg: '${finalResult['message']}');
      } else {
        Utils.mySnackBar(title: '${finalResult['message']}');
      }
    } else {
      debugPrint(response.reasonPhrase.toString());
    }
    return error;
  }

  /// place bet api
  Future<void> placeBetApi(int? amount, betType, number,) async {
    debugPrint("api called  => numbers : $number");
    SharedPreferences preferences = await SharedPreferences.getInstance();
    userId = preferences.getString("userId");

    var headers = {'Cookie': 'ci_session=c7797mp92d9k6gmq38epdr8hm70h9vab'};
    var request =
        http.MultipartRequest('POST', Uri.parse("$baseUrl$placeBetRequest"));
    request.fields.addAll({
      'user_id': userId.toString(),
      'bet_type_id': betType.toString(),
      'amount': amount.toString(),
      'number': number.join(','),
    });
    debugPrint(request.fields.toString());
     request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      debugPrint("api called response 200 => numbers : $number");
      var result = await response.stream.bytesToString();
      var finalResult = jsonDecode(result);
      if (finalResult['error'] == false){
        debugPrint(finalResult['message']);
      } else {

      }
    } else {
      // Utils.mySnackBar(title:'Something went wrong please try again!!');
      debugPrint(response.reasonPhrase);
    }
  }

  /// cancel bet api
  Future<void> cancelBetApi(String?type) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    userId = preferences.getString("userId");

    var headers = {'Cookie': 'ci_session=c7797mp92d9k6gmq38epdr8hm70h9vab'};
    var request =
        http.MultipartRequest('POST', Uri.parse("$baseUrl${Endpoints.cancelBet}"));
    request.fields.addAll({
      'user_id': userId??"",
      "type":type??""
    });
    debugPrint(request.fields.toString());
     request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var result = await response.stream.bytesToString();
      var finalResult = jsonDecode(result);
      debugPrint("cancel bet response: $finalResult");
    } else {
      debugPrint(response.reasonPhrase);
    }
  }

  /// add To Wallet Amount
  Future<(bool,String)> addToWalletAmountApi() async {
    showLoader();
    SharedPreferences preferences = await SharedPreferences.getInstance();
    userId = preferences.getString("userId");
    var headers = {'Cookie': 'ci_session=c7797mp92d9k6gmq38epdr8hm70h9vab'};
    var request = http.MultipartRequest(
        'POST',
        Uri.parse("${Endpoints.baseUrl}${Endpoints.addToWalletAmount}"));
    request.fields.addAll({
      'user_id': userId.toString(),
    });
    debugPrint("this is a parameter--->${request.fields}");
    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();
    (bool,String) errorMsg = (true,"");
    if (response.statusCode == 200) {
      Get.back();
      var result = await response.stream.bytesToString();
      var finalResult = jsonDecode(result);
      errorMsg = (finalResult['error']??true,finalResult['message']??"");
      if (finalResult['error']??true) {
        Utils.mySnackBar(msg: '${finalResult['message']??""}',title:"Primary Wallet Not Found");
      }
    } else {
      Get.back();
      Utils.mySnackBar(title:"Primary Wallet Not Found", maxWidth:300);
      debugPrint(response.reasonPhrase);
    }
   return errorMsg;
  }

  /// last ten winner api
  Future<dynamic> getLastTenWinnerNumbersApi() async {
    // var headers = {'Cookie': 'ci_session=d32fl5jiqq17lamd73ho05s1kmri534r'};
    var request = http.MultipartRequest(
        'GET', Uri.parse("${Endpoints.baseUrl}${Endpoints.lastTenWinningNumbers}"));
    // request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();
    dynamic winnersData;
    if (response.statusCode == 200) {
      var result = await response.stream.bytesToString();
      var finalResult = jsonDecode(result);
      if (finalResult['error'] == false) {
        winnersData = finalResult['data'];
      } else {
        Utils.mySnackBar(title:'Something wrong please logout and login again' );
      }
    } else {
      debugPrint(response.reasonPhrase);
    }
    return winnersData;
  }

  /// get primary wallet Amount
  Future<String?> getPrimaryWalletAmountApi() async {
    String? primaryWalletAmount;
    SharedPreferences preferences = await SharedPreferences.getInstance();
    userId = preferences.getString("userId");

    var headers = {'Cookie': 'ci_session=c7797mp92d9k6gmq38epdr8hm70h9vab'};
    var request = http.MultipartRequest(
        'POST',
        Uri.parse("${Endpoints.baseUrl}${Endpoints.getPrimaryWallet}"));
    request.fields.addAll({
      'user_id': userId.toString(),
    });
    debugPrint("this is a parameter--->${request.fields}");
    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var result = await response.stream.bytesToString();
      var finalResult = jsonDecode(result);
      if (finalResult['error'] == false) {
        primaryWalletAmount = finalResult['data'];
      } else {
        Utils.mySnackBar(title: '${finalResult['message']}');
      }
    } else {
      Utils.mySnackBar(title:'Something wrong please logout and login again' );
      debugPrint(response.reasonPhrase);
    }
    return primaryWalletAmount;
  }

}
