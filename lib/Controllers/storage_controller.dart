

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class StorageController extends GetxController{

  final _box = GetStorage();
  final _loginKey = 'isLogin';

   setLogin(bool val){
     _box.write(_loginKey, val);
   }

   bool getLogin() => _box.read<bool>(_loginKey)??false;

}