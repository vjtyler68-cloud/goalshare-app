import 'package:spanx/core/const/app_images.dart';

class OnboardingModel {
  final String slogan;
  final String subSlogan;
  final String imgPath;

  OnboardingModel(this.slogan, this.subSlogan, this.imgPath);

  final List<OnboardingModel> onboardingList = [
    OnboardingModel(
      "Turn Your Schedule into Sales",
      "Whether you’re a barber, beautician, or sales professional — manage clients, track earnings, and grow your business in one app.",
      AppImages.backgroundScreenGrid,
    ),
  ];
}
