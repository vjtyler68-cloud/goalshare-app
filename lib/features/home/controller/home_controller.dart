import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';


class HomeController extends GetxController{


  // url launcher
  Future<void> launchBibleSite(String webLink) async {
    final Uri url = Uri.parse(webLink);

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }


}