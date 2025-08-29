import 'package:get/get.dart';

class SplashScreenController extends GetxController{
  @override
  void onInit() {
    super.onInit();
    _navigateToNextPage();
  }

  void _navigateToNextPage() async{
    await Future.delayed(Duration(seconds: 2));
    
  }
}