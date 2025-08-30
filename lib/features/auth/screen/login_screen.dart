import 'package:flutter/material.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_size.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/features/auth/widget/heading_title_subtitle_widget.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.w(30),
              vertical: AppSizes.h(30),
            ),
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.center,
              // crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // heading
                HeadingTitleSubtitleWidget(),
                // email
                Column(
                  children: [
                    // text
                    Text('Email Address')
                    // form field
                    // TextField()
                  ],
                )
                // password
                // forgot password
                // button
                // don't have any account
                // google oAuth
              ],
            ),
          ),
        ),
      ),
    );
  }
}
