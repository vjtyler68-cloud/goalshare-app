import 'dart:developer';

import 'package:get/get.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/routes/app_routes.dart';

import '../../../core/user_info/user_info_controller.dart';
import '../../mission/controller/mission_controller.dart';
import '../../motivationalNudges/controller/motivational_nudges_controller.dart';

class SplashScreenController extends GetxController {
  final LocalService localService = LocalService();

  @override
  void onInit() {
    super.onInit();
    _navigateToNextPage();
    
    // checkLoginStatus();
  }

  // void checkLoginStatus() async{
  //   final token = await localService.getValue(PreferenceKey.token);
  //   if(token != null){
  //       Get.toNamed(AppRoutes.mainNavBarScreen);
  //   }else{
  //     Get.toNamed(AppRoutes.onboardingScreen);
  //   }

  // }

  void _navigateToNextPage() async {
  await Future.delayed(Duration(seconds: 2));
  log('Starting token fetch...');
  
  final token = await localService.getToken();

  log('Token received: $token');

  if (token == null) {
    log('No token found. Navigating to login.');
    Get.toNamed(AppRoutes.loginScreen);
  } else {
    log('Token found. Navigating to main screen.');
    Get.toNamed(AppRoutes.mainNavBarScreen);
    Get.put(UserInfoController());
    Get.put(MotivationalNudgesController(), permanent: true);
    Get.put(MissionController(), permanent: true);
  }
}


  // void _navigateToNextPage() async {
  //   await Future.delayed(Duration(seconds: 2));
  //   final token = await localService.getValue(PreferenceKey.token);
  //   log('token searching start-----------');
  //   if (token == null) {
  //     Get.toNamed(AppRoutes.loginScreen);
  //   } else {
  //     Get.toNamed(AppRoutes.mainNavBarScreen);
  //   }
  // }

  @override
  void dispose() {
    super.dispose();
  }
}
