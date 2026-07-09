import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart' show Color;
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

const String kPrimingVideoId = 'faTGTgid8Uc';

class PrimingController extends GetxController {
  var isCompleted = false.obs;

  late final WebViewController webController;

  @override
  void onInit() {
    super.onInit();

    // iOS (WKWebView) needs inline playback explicitly enabled, otherwise the
    // video is forced into native fullscreen instead of playing in the card.
    late final PlatformWebViewControllerCreationParams params;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    webController = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      // Navigate DIRECTLY to the YouTube embed URL instead of using
      // loadHtmlString. On iOS, WKWebView does NOT grant loadHtmlString content
      // the network origin of `baseUrl`, so the YouTube IFrame API rejected it
      // ("Error code: 152"). Loading the embed URL directly gives the page a
      // genuine youtube.com origin, so the video plays inline inside the app.
      // playsinline=1 (+ allowsInlineMediaPlayback on iOS) keeps it in the card.
      ..loadRequest(Uri.parse(
        'https://www.youtube.com/embed/$kPrimingVideoId'
        '?playsinline=1&rel=0&modestbranding=1&fs=1',
      ));
  }

  void markCompleted() => isCompleted.value = true;
}
