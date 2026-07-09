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
        // Play inside the app rather than kicking out to fullscreen/native.
        playsInline: true,
        // YouTube's IFrame API validates the embedding origin. Inside an iOS
        // WKWebView there is no page origin, so without this the embed can fail
        // to initialize and fall back to the YouTube homepage. Declaring a
        // valid origin makes in-app playback reliable.
        origin: 'https://www.youtube.com',
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
