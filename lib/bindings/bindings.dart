import 'package:get/get.dart';
import 'package:spanx/features/auth/controller/apply_code_controller.dart';
import 'package:spanx/features/auth/controller/login_controller.dart';
import 'package:spanx/features/auth/controller/reset_code_controller.dart';
import 'package:spanx/features/auth/controller/reset_password_controller.dart';

class AppBindings extends Bindings{
  @override
  void dependencies() {
    Get.lazyPut(()=> LoginController());
    Get.lazyPut(()=> ResetCodeController());
    Get.lazyPut(()=> ApplyCodeController());
    Get.lazyPut(()=> ResetPasswordController());
  }
}