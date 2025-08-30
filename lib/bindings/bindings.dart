import 'package:get/get.dart';
import 'package:spanx/features/auth/controller/login_controller.dart';

class AppBindings extends Bindings{
  @override
  void dependencies() {
    Get.lazyPut(()=> LoginController());
  }
}