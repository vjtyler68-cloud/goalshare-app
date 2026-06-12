import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

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
            'Terms & Conditions',
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
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.description_rounded,
                        size: 48.w,
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Terms & Conditions',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.greyColor70,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Last Updated: February 24, 2026',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[600]!,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Introduction
                _buildIntroSection(),

                SizedBox(height: 20.h),

                // Terms Sections
                _buildTermSection(
                  '1. Acceptance of Terms',
                  'By downloading, installing, or using the GoalShare application, you agree to be bound by these Terms and Conditions. '
                      'If you do not agree to these terms, please do not use our service. We reserve the right to modify these terms at any time, '
                      'and your continued use of the app constitutes acceptance of any changes.',
                ),

                _buildTermSection(
                  '2. User Account',
                  'To access certain features, you must create an account. You are responsible for:\n\n'
                      '• Maintaining the confidentiality of your account credentials\n'
                      '• All activities that occur under your account\n'
                      '• Notifying us immediately of any unauthorized use\n'
                      '• Ensuring all information provided is accurate and up-to-date\n\n'
                      'You must be at least 13 years old to use this service.',
                ),

                _buildTermSection(
                  '3. User Conduct',
                  'You agree not to:\n\n'
                      '• Use the app for any illegal or unauthorized purpose\n'
                      '• Violate any laws in your jurisdiction\n'
                      '• Transmit any harmful code, viruses, or malware\n'
                      '• Harass, abuse, or harm other users\n'
                      '• Impersonate any person or entity\n'
                      '• Collect or harvest information from other users\n'
                      '• Interfere with or disrupt the service or servers',
                ),

                _buildTermSection(
                  '4. Subscription & Payment',
                  'Some features require a paid subscription:\n\n'
                      '• Subscriptions are billed in advance on a recurring basis\n'
                      '• Prices are subject to change with 30 days notice\n'
                      '• You can cancel your subscription at any time\n'
                      '• Refunds are handled according to our refund policy\n'
                      '• Free trials may be offered at our discretion\n'
                      '• Payment processing is handled securely by third-party providers',
                ),

                _buildTermSection(
                  '5. Content & Intellectual Property',
                  'All content, features, and functionality of GoalShare are owned by us and protected by international copyright, trademark, and other intellectual property laws.\n\n'
                      'You retain ownership of content you create (goals, notes, vision boards), but grant us a license to use, display, and process this content to provide our services.',
                ),

                _buildTermSection(
                  '6. Data Privacy',
                  'Your privacy is important to us. Our collection and use of personal information is governed by our Privacy Policy. '
                      'By using GoalShare, you consent to our data practices as described in the Privacy Policy.',
                ),

                _buildTermSection(
                  '7. Termination',
                  'We reserve the right to suspend or terminate your account at any time for:\n\n'
                      '• Violation of these Terms and Conditions\n'
                      '• Fraudulent or illegal activity\n'
                      '• Extended periods of inactivity\n\n'
                      'You may also delete your account at any time through the app settings. Upon termination, your right to use the service ceases immediately.',
                ),

                _buildTermSection(
                  '8. Disclaimers & Limitations',
                  'GoalShare is provided "as is" without warranties of any kind. We do not guarantee:\n\n'
                      '• Uninterrupted or error-free service\n'
                      '• That defects will be corrected\n'
                      '• That the service is free of viruses or harmful components\n\n'
                      'We are not liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of the service.',
                ),

                _buildTermSection(
                  '9. Third-Party Services',
                  'GoalShare may contain links to third-party websites or services. We are not responsible for the content, privacy policies, or practices of any third-party sites. '
                      'Your interactions with third-party services are solely between you and that third party.',
                ),

                _buildTermSection(
                  '10. Changes to Service',
                  'We reserve the right to modify or discontinue the service (or any part thereof) at any time with or without notice. '
                      'We shall not be liable to you or any third party for any modification, suspension, or discontinuance of the service.',
                ),

                _buildTermSection(
                  '11. Governing Law',
                  'These Terms shall be governed by and construed in accordance with the laws of the jurisdiction in which our company is registered, '
                      'without regard to its conflict of law provisions.',
                ),

                _buildTermSection(
                  '12. Contact Us',
                  'If you have any questions about these Terms and Conditions, please contact us at:\n\n'
                      '📧 legal@goalshare.com\n'
                      '🌐 www.goalshare.com/support\n'
                      '📍 San Francisco, CA',
                ),

                // SizedBox(height: 24.h),

                // Footer
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primaryColor,
                        size: 20.w,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'By continuing to use GoalShare, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.greyColor70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.lightPinkColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        'Welcome to GoalShare! These Terms and Conditions outline the rules and regulations for the use of our application. '
        'Please read these terms carefully before using our service.',
        textAlign: TextAlign.justify,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
          color: Colors.grey[800]!,
        ),
      ),
    );
  }

  Widget _buildTermSection(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.greyColor70,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            content,
            textAlign: TextAlign.justify,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
              color: Colors.grey[700]!,
            ),
          ),
          SizedBox(height: 12.h),
          Divider(
            color: Colors.grey[300],
            thickness: 1,
          ),
        ],
      ),
    );
  }
}
