import 'package:spanx/core/const/app_images.dart';

class OnboardingModel {
  final String slogan;
  final String subSlogan;
  final String imgPath;

  OnboardingModel(this.slogan, this.subSlogan, this.imgPath);

  static final List<OnboardingModel> onboardingList = [
    OnboardingModel(
      "Turn Your Goals into Achievements",
      "Set meaningful goals, build daily habits, and track your progress — all in one app designed to keep you moving forward.",
      AppImages.onboarding1,
    ),
    OnboardingModel(
      "Stay on Top of Your Progress",
      "See how much you’ve achieved today, this week, or this month — all at a glance. No more guesswork, only growth.",
      AppImages.onboarding2,
    ),
  ];
}
