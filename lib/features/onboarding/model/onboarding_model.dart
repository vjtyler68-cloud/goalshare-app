import 'package:spanx/core/const/app_images.dart';

class OnboardingModel {
  final String slogan;
  final String subSlogan;
  final String imgPath;

  OnboardingModel(this.slogan, this.subSlogan, this.imgPath);

  static final List<OnboardingModel> onboardingList = [
    OnboardingModel(
      "Turn Your Schedule into Sales",
      "Whether you’re a barber, beautician, or sales professional — manage clients, track earnings, and grow your business in one app.",
      AppImages.onboarding1,
    ),
    OnboardingModel(
      "Stay on Top of Your Earnings",
      "See how much you’ve achieved today, this week, or this month — all at a glance. No more guesswork, only growth.",
      AppImages.onboarding2,
    ),
  ];
}
