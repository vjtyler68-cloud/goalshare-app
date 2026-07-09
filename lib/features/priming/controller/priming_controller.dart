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
      // The critical fix for YouTube embed "Error code: 152 - 4": the IFrame
      // API validates the page origin. Loading the HTML with a real
      // youtube.com baseUrl gives the embed a valid origin, which in-app
      // WebViews otherwise lack, so playback works inside the app.
      ..loadHtmlString(_playerHtml(kPrimingVideoId),
          baseUrl: 'https://www.youtube.com');
  }

  String _playerHtml(String videoId) => '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport"
          content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <style>
      html, body { margin:0; padding:0; background:#000; height:100%; width:100%; overflow:hidden; }
      .wrap { position:relative; width:100%; height:100%; }
      iframe { position:absolute; top:0; left:0; width:100%; height:100%; border:0; }
    </style>
  </head>
  <body>
    <div class="wrap">
      <iframe
        src="https://www.youtube.com/embed/$videoId?playsinline=1&rel=0&modestbranding=1&autoplay=0&controls=1&fs=1&enablejsapi=1&origin=https://www.youtube.com"
        frameborder="0"
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
        allowfullscreen>
      </iframe>
    </div>
  </body>
</html>
''';

  void markCompleted() => isCompleted.value = true;
}
