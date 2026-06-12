import 'package:get/get.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

const String kPrimingVideoId = 'faTGTgid8Uc';

class PrimingController extends GetxController {
  var isCompleted = false.obs;

  late YoutubePlayerController youtubeController;

  @override
  void onInit() {
    super.onInit();
    youtubeController = YoutubePlayerController.fromVideoId(
      videoId: kPrimingVideoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        loop: false,
        strictRelatedVideos: true,
      ),
    );
  }

  void markCompleted() => isCompleted.value = true;

  @override
  void onClose() {
    youtubeController.close();
    super.onClose();
  }
}
