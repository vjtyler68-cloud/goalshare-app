import 'package:get/get.dart';
import 'package:spanx/routes/app_routes.dart';

class SplashScreenController extends GetxController{
  @override
  void onInit() {
    super.onInit();
    _navigateToNextPage();
  }

  void _navigateToNextPage() async{
    await Future.delayed(Duration(seconds: 2));
    Get.offAllNamed(AppRoutes.onboardingScreen);
    
  }
}