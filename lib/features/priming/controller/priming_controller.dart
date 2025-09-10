import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class PrimingController extends GetxController {
  final String videoUrl =
      "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";

  late VideoPlayerController videoPlayerController;
  late Future<void> initializeFuture;

  @override
  void onInit() {
    videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    // Initialize first
    initializeFuture = videoPlayerController.initialize().then((_) {
      // Only play after initialization succeeds
      videoPlayerController.play();
      videoPlayerController.setLooping(true); // Optional: loop video
      update(); // Notify GetX to rebuild UI if needed
    }).catchError((error) {
      print("Error initializing video: $error");
    });

    super.onInit();
  }

  @override
  void dispose() {
    videoPlayerController.dispose();
    super.dispose();
  }
}