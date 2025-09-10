import 'package:get/get.dart';
import 'package:spanx/features/auth/controller/apply_code_controller.dart';
import 'package:spanx/features/auth/controller/login_controller.dart';
import 'package:spanx/features/auth/controller/reset_code_controller.dart';
import 'package:spanx/features/auth/controller/reset_password_controller.dart';
import 'package:spanx/features/auth/controller/signup_controller.dart';
import 'package:spanx/features/goals/controller/goals_controller.dart';
import 'package:spanx/features/mainnavbar/controller/main_navbar_controller.dart';
import 'package:spanx/features/mybudget/controller/my_budget_controller.dart';
import 'package:spanx/features/priming/controller/priming_controller.dart';
import 'package:spanx/features/profile/controller/setup_profile_controller.dart';

class AppBindings extends Bindings{
  @override
  void dependencies() {
    Get.lazyPut(()=> LoginController());
    Get.lazyPut(()=> SignupController());
    Get.lazyPut(()=> ResetCodeController());
    Get.lazyPut(()=> ApplyCodeController());
    Get.lazyPut(()=> ResetPasswordController());
    Get.lazyPut(()=> SetupProfileController());
    Get.lazyPut(()=> MainNavBarController());
    Get.lazyPut(()=> GoalsController());
    Get.lazyPut(()=> PrimingController());
    Get.lazyPut(()=> MyBudgetController());
  }
}