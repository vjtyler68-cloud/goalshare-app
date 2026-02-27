import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/routes/app_routes.dart';

import '../../../core/const/app_colors.dart';

class SubscriptionOverUi extends StatefulWidget {
  const SubscriptionOverUi({super.key});

  @override
  State<SubscriptionOverUi> createState() => _SubscriptionOverUiState();
}

class _SubscriptionOverUiState extends State<SubscriptionOverUi>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.formBackgroundColor,
              AppColors.lightPinkColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.formBackgroundColor,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.2),
                      blurRadius: 25,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryColor.withOpacity(0.1),
                        ),
                        child: Icon(
                          Icons.lock_outline_rounded,
                          size: 48,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Subscription Expired",
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.greyColor70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Your premium access has ended.\nSubscribe again to continue enjoying all features.",
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 15,
                        color: AppColors.greyColor70.withOpacity(0.7),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 8,
                          shadowColor:
                          AppColors.primaryColor.withOpacity(0.4),
                        ),
                        onPressed: () {
                          Get.toNamed(AppRoutes.subscriptionScreen);
                        },
                        child:  Text(
                          "Go To Subscribe",
                          style: AppFonts.spaceGrotesk.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppColors.primaryColor,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () async {
                          // Clear all user data
                          await LocalService().clearUserData();
                          // Navigate to login screen and remove all previous routes
                          Get.offAllNamed(AppRoutes.loginScreen);
                        },
                        child: Text(
                          "Switch Account",
                          style: AppFonts.spaceGrotesk.copyWith(
                            color: AppColors.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}