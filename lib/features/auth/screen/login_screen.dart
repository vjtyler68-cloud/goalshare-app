import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/features/auth/controller/login_controller.dart';
import 'package:spanx/routes/app_routes.dart';

const _kRed   = Color(0xffE84040);
const _kRedDk = Color(0xff9B1414);
const _kBg    = Color(0xffF6F4F2);
const _kText  = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController loginController = Get.put(LoginController());
    return Scaffold(
      backgroundColor: _kBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero gradient top ──────────────────────────────────────────
            Container(
              height: 280.h,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kRed, _kRedDk],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(top: -40, right: -40, child: _Circle(120, Colors.white.withOpacity(0.07))),
                  Positioned(top: 60, right: 40, child: _Circle(60, Colors.white.withOpacity(0.07))),
                  Positioned(bottom: -20, left: -30, child: _Circle(100, Colors.white.withOpacity(0.07))),
                  // Content
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 28.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 20.h),
                          Container(
                            width: 54.r, height: 54.r,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: const Icon(Icons.bolt, color: Colors.white, size: 30),
                          ),
                          SizedBox(height: 16.h),
                          Text('Welcome Back', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 28.sp, fontWeight: FontWeight.w800, height: 1.1)),
                          SizedBox(height: 6.h),
                          Text('Sign in to track your goals &\nkeep your momentum going.', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white70, fontSize: 14.sp, height: 1.5)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Form area ─────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Email
                  Text('Email Address', style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w700, color: _kText)),
                  SizedBox(height: 8.h),
                  _InputField(
                    controller: loginController.emailController,
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    icon: Icons.email_outlined,
                  ),
                  SizedBox(height: 18.h),

                  // Password
                  Text('Password', style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w700, color: _kText)),
                  SizedBox(height: 8.h),
                  Obx(() => _InputField(
                    controller: loginController.passwordController,
                    hint: 'Enter your password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    isVisible: loginController.isPasswordVisible.value,
                    onToggle: loginController.makePasswordVisible,
                  )),
                  SizedBox(height: 8.h),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.forgetPasswordScreen),
                      child: Text('Forgot Password?', style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, color: _kRed, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  SizedBox(height: 28.h),

                  // Login button
                  Obx(() => loginController.isLoading.value
                      ? Center(child: LoadingAnimationWidget.staggeredDotsWave(color: _kRed, size: 30.h))
                      : GestureDetector(
                          onTap: () {
                            if (loginController.isInfoCompleted()) {
                              loginController.handleLogin();
                            } else {
                              Fluttertoast.showToast(msg: "Fields can't be incomplete", backgroundColor: AppColors.redColor);
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [_kRed, _kRedDk]),
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [BoxShadow(color: _kRed.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 5))],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Sign In', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w700)),
                                SizedBox(width: 8.w),
                                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        )),
                  SizedBox(height: 28.h),

                  // Divider
                  Row(children: [
                    const Expanded(child: Divider(color: Color(0xffE2E2E2))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Text('or', style: AppFonts.spaceGrotesk.copyWith(color: _kMuted, fontSize: 13.sp)),
                    ),
                    const Expanded(child: Divider(color: Color(0xffE2E2E2))),
                  ]),
                  SizedBox(height: 24.h),

                  // Register
                  Center(
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, color: _kMuted),
                        children: [
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () => Get.toNamed(AppRoutes.signUpScreen),
                              child: Text('Register', style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, color: _kRed, fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final Color color;
  const _Circle(this.size, this.color);
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final IconData icon;
  final bool isPassword;
  final bool isVisible;
  final VoidCallback? onToggle;

  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    required this.icon,
    this.isPassword = false,
    this.isVisible = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword && !isVisible,
        style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, color: _kText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, color: _kMuted),
          prefixIcon: Icon(icon, color: _kMuted, size: 20),
          suffixIcon: isPassword
              ? GestureDetector(
                  onTap: onToggle,
                  child: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: _kMuted, size: 20),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        ),
      ),
    );
  }
}
