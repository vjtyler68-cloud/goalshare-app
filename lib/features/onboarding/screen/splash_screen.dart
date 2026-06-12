import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_size.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffE84040), Color(0xff9B1414)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(top: -60, right: -60, child: _circle(200, Colors.white.withOpacity(0.06))),
            Positioned(bottom: 100, left: -80, child: _circle(260, Colors.white.withOpacity(0.05))),
            Positioned(top: 120, left: -40, child: _circle(120, Colors.white.withOpacity(0.05))),
            Positioned(bottom: -40, right: -40, child: _circle(180, Colors.white.withOpacity(0.06))),

            // Center content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo container
                  Container(
                    width: 90.r,
                    height: 90.r,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(26.r),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                    ),
                    child: const Icon(Icons.bolt, color: Colors.white, size: 50),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'GOALSHARE',
                    style: AppFonts.spaceGrotesk.copyWith(
                      color: Colors.white,
                      fontSize: 34.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Your Sales Performance OS',
                    style: AppFonts.spaceGrotesk.copyWith(
                      color: Colors.white70,
                      fontSize: 14.sp,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            // Bottom loader
            Positioned(
              bottom: 60.h,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Loading your world...',
                    style: AppFonts.spaceGrotesk.copyWith(color: Colors.white54, fontSize: 12.sp),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle(double size, Color color) =>
      Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}
