import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20.w),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'About Us',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Logo/Icon Section
              Center(
                child: Container(
                  // width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 60.w,
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'GoalShare',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Your Personal Productivity Companion',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[600]!,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // Mission Section
              _buildSectionCard(
                title: 'Our Mission',
                content:
                    'GoalShare is designed to help you achieve your goals and maximize productivity. '
                    'We believe that everyone has the potential to accomplish great things with the right tools and motivation. '
                    'Our mission is to empower individuals to take control of their time, set meaningful goals, and track their progress effectively.',
                icon: Icons.rocket_launch_rounded,
              ),

              SizedBox(height: 16.h),

              // Vision Section
              _buildSectionCard(
                title: 'Our Vision',
                content:
                    'We envision a world where productivity meets purpose. GoalShare combines goal tracking, '
                    'motivational support, and community engagement to create a holistic approach to personal development. '
                    'We\'re building more than just an app—we\'re building a movement of achievers.',
                icon: Icons.visibility_rounded,
              ),

              SizedBox(height: 16.h),

              // Features Section
              _buildSectionCard(
                title: 'What We Offer',
                content: '',
                icon: Icons.apps_rounded,
                customContent: Column(
                  children: [
                    _buildFeatureItem('📊', 'Goal & Budget Tracking',
                        'Set and monitor your personal and financial goals'),
                    _buildFeatureItem('🔥', 'Motivational Support',
                        'Daily inspiration to keep you moving forward'),
                    _buildFeatureItem('👥', 'Community Engagement',
                        'Connect with like-minded achievers'),
                    _buildFeatureItem('📈', 'Analytics & Insights',
                        'Understand your productivity patterns'),
                    _buildFeatureItem('🎯', 'Vision Board',
                        'Visualize your dreams and aspirations'),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // Contact Section
              _buildSectionCard(
                title: 'Get In Touch',
                content:
                    'We\'d love to hear from you! Whether you have feedback, suggestions, or need support, '
                    'our team is here to help you succeed.',
                icon: Icons.mail_rounded,
                customContent: Column(
                  children: [
                    SizedBox(height: 12.h),
                    _buildContactItem(Icons.email_rounded, 'support@goalshare.com'),
                    SizedBox(height: 8.h),
                    _buildContactItem(Icons.language_rounded, 'www.goalshare.com'),
                    SizedBox(height: 8.h),
                    _buildContactItem(
                        Icons.location_on_rounded, 'San Francisco, CA'),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // App Version
              Center(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'Version 1.4.0',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600]!,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String content,
    required IconData icon,
    Widget? customContent,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryColor,
                  size: 24.w,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.greyColor70,
                ),
              ),
            ],
          ),
          if (content.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              content,
              textAlign: TextAlign.justify,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: Colors.grey[700]!,
              ),
            ),
          ],
          if (customContent != null) customContent,
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String title, String description) {
    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: TextStyle(fontSize: 20.sp)),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.greyColor70,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600]!,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryColor, size: 18.w),
        SizedBox(width: 8.w),
        Text(
          text,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700]!,
          ),
        ),
      ],
    );
  }
}
