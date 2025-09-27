import 'package:get/get.dart';
import 'package:spanx/core/user_info/user_info_controller.dart';
import 'package:spanx/features/auth/controller/apply_code_controller.dart';
import 'package:spanx/features/auth/controller/forgetpassword_controller.dart';
import 'package:spanx/features/auth/controller/login_controller.dart';
import 'package:spanx/features/auth/controller/reset_code_controller.dart';
import 'package:spanx/features/auth/controller/reset_password_controller.dart';
import 'package:spanx/features/auth/controller/signup_controller.dart';
import 'package:spanx/features/community_profile/controller/community_profile_controller.dart';
import 'package:spanx/features/home/controller/home_controller.dart';
import 'package:spanx/features/mainnavbar/controller/main_navbar_controller.dart';
import 'package:spanx/features/mission/controller/mission_controller.dart';
import 'package:spanx/features/mybudget/controller/my_budget_controller.dart';
import 'package:spanx/features/priming/controller/priming_controller.dart';
import 'package:spanx/features/vision_board_create/controller/vision_board_create_controller.dart';

import '../features/signup_update_profile/controller/setup_profile_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    //  Get.lazyPut(()=>SplashScreenController());
    Get.lazyPut(() => LoginController());
    Get.lazyPut(() => HomeController());
    Get.lazyPut(() => SignupController());
    Get.lazyPut(() => ForgetPasswordController());
    Get.lazyPut(() => ResetCodeController());
    Get.lazyPut(() => ApplyCodeController());
    Get.lazyPut(() => ResetPasswordController());
    Get.lazyPut(() => SetupProfileController());
    Get.lazyPut<MainNavBarController>(() => MainNavBarController());
    Get.lazyPut(() => MissionController());
    Get.lazyPut(() => PrimingController());
    Get.lazyPut(() => MyBudgetController());
    Get.lazyPut(() => CommunityProfileController());
    Get.lazyPut(() => HomeController());
    Get.lazyPut(() => VisionBoardCreateController());
    Get.lazyPut(() => UserInfoController());
  }
}
