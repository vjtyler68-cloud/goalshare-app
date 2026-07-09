import 'package:get/get.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

const String kPrimingVideoId = 'faTGTgid8Uc';

class PrimingController extends GetxController {
  var isCompleted = false.obs;

  late final YoutubePlayerController ytController;

  @override
  void onInit() {
    super.onInit();

    // Use the dedicated YouTube IFrame player. Earlier hand-rolled WKWebView
    // attempts both failed:
    //   * loadHtmlString + baseUrl  -> Error 152 (WKWebView doesn't grant the
    //     content a real network origin, so the IFrame API rejected it).
    //   * loadRequest to the embed URL as the top-level document -> Error 153
    //     ("Video player configuration error") because a top-level embed load
    //     sends no HTTP referrer, which YouTube's player requires.
    // This package embeds the player inside a proper iframe with a valid origin
    // and manages iOS inline playback, so neither error occurs.
    ytController = YoutubePlayerController.fromVideoId(
      videoId: kPrimingVideoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        // No YoutubePlayerScaffold here, so the fullscreen toggle has nothing
        // to drive — hide it and rely on the "Watch on YouTube" button for the
        // full-screen experience.
        showFullscreenButton: false,
        playsInline: true,
        strictRelatedVideos: true,
      ),
    );
  }

  @override
  void onClose() {
    ytController.close();
    super.onClose();
  }

  void markCompleted() => isCompleted.value = true;
}
