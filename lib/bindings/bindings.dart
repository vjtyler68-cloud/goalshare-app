import 'package:get/get.dart';
import 'package:spanx/core/user_info/user_info_controller.dart';
import 'package:spanx/features/auth/controller/apply_code_controller.dart';
import 'package:spanx/features/auth/controller/change_password_controller.dart';
import 'package:spanx/features/auth/controller/forgetpassword_controller.dart';
import 'package:spanx/features/auth/controller/login_controller.dart';
import 'package:spanx/features/auth/controller/reset_code_controller.dart';
import 'package:spanx/features/auth/controller/reset_password_controller.dart';
import 'package:spanx/features/auth/controller/signup_controller.dart';
import 'package:spanx/features/community_profile/controller/community_profile_controller.dart';
import 'package:spanx/features/customer_details/controller/customer_details_controller.dart';
import 'package:spanx/features/editprofile/controller/edit_profile_controller.dart';
import 'package:spanx/features/home/controller/home_controller.dart';
import 'package:spanx/features/mainnavbar/controller/main_navbar_controller.dart';
import 'package:spanx/features/mission/controller/mission_controller.dart';
import 'package:spanx/features/motivationalNudges/controller/motivational_nudges_controller.dart';
import 'package:spanx/features/mybudget/controller/my_budget_controller.dart';
import 'package:spanx/features/priming/controller/priming_controller.dart';
import 'package:spanx/features/subscription_page/controller/subscription_page_controller.dart';
import 'package:spanx/features/subscriptions/controller/subscription_controller.dart';
import 'package:spanx/features/vision_board_create/controller/vision_board_create_controller.dart';
import '../features/create_motivation/controller/create_motivation_controller.dart';
import '../features/signup_update_profile/controller/setup_profile_controller.dart';
import '../features/vision_board/controller/vision_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Auth
    Get.lazyPut<LoginController>(() => LoginController());
    Get.lazyPut<SignupController>(() => SignupController());
    Get.lazyPut<ForgetPasswordController>(() => ForgetPasswordController());
    Get.lazyPut<ResetCodeController>(() => ResetCodeController());
    Get.lazyPut<ApplyCodeController>(() => ApplyCodeController());
    Get.lazyPut<ResetPasswordController>(() => ResetPasswordController());
    Get.lazyPut<ChangePasswordController>(() => ChangePasswordController());

    // Core / User
    Get.lazyPut<UserInfoController>(() => UserInfoController(), fenix: true);

    // App / Main
    Get.lazyPut<MainNavBarController>(
      () => MainNavBarController(),
      fenix: true,
    );
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);

    // Features
    Get.lazyPut<SetupProfileController>(() => SetupProfileController());
    Get.lazyPut<MissionController>(() => MissionController(), fenix: true);
    Get.lazyPut<PrimingController>(() => PrimingController(), fenix: true);
    Get.lazyPut<MyBudgetController>(() => MyBudgetController(), fenix: true);
    Get.lazyPut<CommunityProfileController>(
      () => CommunityProfileController(),
      fenix: true,
    );
    Get.lazyPut<VisionBoardCreateController>(
      () => VisionBoardCreateController(),
      fenix: true,
    );
    Get.lazyPut<VisionBoardController>(
          () => VisionBoardController(),
      fenix: true,
    );
    Get.lazyPut<CustomerDetailsController>(
      () => CustomerDetailsController(),
      fenix: true,
    );
    Get.lazyPut<MotivationalNudgesController>(
      () => MotivationalNudgesController(),
      fenix: true,
    );

    // Edit Profile (IMPORTANT: so Get.find() works in screen & controller stays available)
    Get.lazyPut<EditProfileController>(
      () => EditProfileController(),
      fenix: true,
    );

    // Subscription
    Get.lazyPut<SubscriptionPageController>(
      () => SubscriptionPageController(),
      fenix: true,
    );
    Get.lazyPut<SubscriptionController>(
      () => SubscriptionController(),
      fenix: true,
    );

    Get.lazyPut<CreateMotivationController>(() => CreateMotivationController());
  }
}
