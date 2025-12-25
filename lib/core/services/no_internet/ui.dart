import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/services/no_internet/controller.dart';

class NoInternetPage extends StatefulWidget {
  const NoInternetPage({super.key});

  @override
  State<NoInternetPage> createState() => _NoInternetPageState();
}

class _NoInternetPageState extends State<NoInternetPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _floatController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _floatAnimation;

  final ConnectivityController _connectivityController = Get.find();

  @override
  void initState() {
    super.initState();

    // Pulse animation for outer circle
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Rotate animation for icon
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.easeInOut),
    );

    // Float animation for entire icon container
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: AppColors.formBackgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              // Background gradient circles
              Positioned(
                top: -100.h,
                right: -100.w,
                child: Container(
                  width: 300.w,
                  height: 300.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryColor.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -150.h,
                left: -100.w,
                child: Container(
                  width: 350.w,
                  height: 350.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryColor.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Main content
              Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated icon container
                        AnimatedBuilder(
                          animation: _floatAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _floatAnimation.value),
                              child: child,
                            );
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer pulsing circle
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Container(
                                      width: 200.w,
                                      height: 200.h,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.primaryColor
                                              .withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Middle circle
                              Container(
                                width: 160.w,
                                height: 160.h,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryColor.withOpacity(
                                    0.5,
                                  ),
                                  border: Border.all(
                                    color: AppColors.primaryColor.withOpacity(
                                      0.2,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                              ),

                              // Inner circle with rotating icon
                              Container(
                                width: 120.w,
                                height: 120.h,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primaryColor.withOpacity(0.8),
                                      AppColors.primaryColor.withOpacity(0.6),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryColor.withOpacity(
                                        0.3,
                                      ),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: AnimatedBuilder(
                                  animation: _rotateAnimation,
                                  builder: (context, child) {
                                    return Transform.rotate(
                                      angle:
                                          _rotateAnimation.value * 2 * 3.14159,
                                      child: Icon(
                                        Icons.wifi_off_rounded,
                                        size: 60.sp,
                                        color: AppColors.whiteColor,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        TweenAnimationBuilder(
                          duration: const Duration(milliseconds: 800),
                          tween: Tween<double>(begin: 0, end: 1),
                          builder: (context, double value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            'Oops!',
                            style: TextStyle(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.blackColor,
                              letterSpacing: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        TweenAnimationBuilder(
                          duration: const Duration(milliseconds: 1000),
                          tween: Tween<double>(begin: 0, end: 1),
                          builder: (context, double value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            'No Internet Connection',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.greyColor70.withOpacity(0.9),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 10.h),

                        /*
                        // Description
                        TweenAnimationBuilder(
                          duration: const Duration(milliseconds: 1200),
                          tween: Tween<double>(begin: 0, end: 1),
                          builder: (context, double value, child) {
                            return Opacity(
                              opacity: value,
                              child: child,
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 16.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.containerButtonColor
                                  .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.white,
                                  size: 24.sp,
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'It seems you\'re offline right now.\nCheck your connection and try again.',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppColors.grayColor,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 10.h),
*/

                        // Retry button
                        Obx(() {
                          return TweenAnimationBuilder(
                            duration: const Duration(milliseconds: 1400),
                            tween: Tween<double>(begin: 0, end: 1),
                            builder: (context, double value, child) {
                              return Transform.scale(
                                scale: value,
                                child: child,
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              height: 30.h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16.r),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryColor.withOpacity(
                                      0.4,
                                    ),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap:
                                      _connectivityController
                                          .isCheckingConnection
                                          .value
                                      ? null
                                      : () => _connectivityController
                                            .retryConnection(),
                                  borderRadius: BorderRadius.circular(16.r),
                                  child: Center(
                                    child:
                                        _connectivityController
                                            .isCheckingConnection
                                            .value
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 20.w,
                                                height: 20.h,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(AppColors.blackColor),
                                                ),
                                              ),
                                              SizedBox(width: 12.w),
                                              Text(
                                                'Checking...',
                                                style: TextStyle(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.blackColor,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.refresh_rounded,
                                                color: AppColors.blackColor,
                                                size: 24.sp,
                                              ),
                                              SizedBox(width: 8.w),
                                              Text(
                                                'Try Again',
                                                style: TextStyle(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.blackColor,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                        SizedBox(height: 20.h),

                        // Tips section
                        TweenAnimationBuilder(
                          duration: const Duration(milliseconds: 1600),
                          tween: Tween<double>(begin: 0, end: 1),
                          builder: (context, double value, child) {
                            return Opacity(opacity: value, child: child);
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quick Tips',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.blackColor,
                                ),
                              ),
                              SizedBox(height: 10.h),
                              _buildTipItem(
                                Icons.wifi_rounded,
                                'Check your Wi-Fi or mobile data',
                              ),
                              SizedBox(height: 5.h),
                              _buildTipItem(
                                Icons.airplanemode_active_rounded,
                                'Turn off Airplane mode',
                              ),
                              SizedBox(height: 5.h),
                              _buildTipItem(
                                Icons.router_rounded,
                                'Check your router connection',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColors.formBackgroundColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 16.sp, color: AppColors.primaryColor),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13.sp, color: AppColors.greyColor70),
          ),
        ),
      ],
    );
  }
}
