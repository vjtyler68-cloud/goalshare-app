import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
            'Privacy Policy',
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
                        Icons.privacy_tip_rounded,
                        size: 48.w,
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Privacy Policy',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.greyColor70,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Effective Date: February 24, 2026',
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

                // Privacy Sections
                _buildPrivacySection(
                  '1. Information We Collect',
                  'We collect several types of information to provide and improve our service:\n\n'
                      '📝 Personal Information:\n'
                      '• Name and email address\n'
                      '• Profile picture\n'
                      '• Account credentials\n'
                      '• Subscription and payment information\n\n'
                      '📊 Usage Data:\n'
                      '• App interactions and features used\n'
                      '• Goals, budgets, and progress tracking data\n'
                      '• Vision board content you create\n'
                      '• Analytics and performance data\n\n'
                      '📱 Device Information:\n'
                      '• Device type and operating system\n'
                      '• IP address and location data\n'
                      '• Mobile device identifiers\n'
                      '• Browser type and version',
                ),

                _buildPrivacySection(
                  '2. How We Use Your Information',
                  'We use the collected information for various purposes:\n\n'
                      '✅ To provide and maintain our service\n'
                      '✅ To notify you about changes to our service\n'
                      '✅ To provide customer support\n'
                      '✅ To gather analysis and valuable insights\n'
                      '✅ To monitor the usage of our service\n'
                      '✅ To detect, prevent, and address technical issues\n'
                      '✅ To send you motivational content and updates\n'
                      '✅ To personalize your experience\n'
                      '✅ To process your payments and subscriptions',
                ),

                _buildPrivacySection(
                  '3. Data Storage & Security',
                  'We take the security of your data seriously:\n\n'
                      '🔒 Encryption: Your data is encrypted in transit and at rest using industry-standard encryption protocols.\n\n'
                      '🔒 Secure Servers: We store data on secure servers with restricted access.\n\n'
                      '🔒 Authentication: We use secure authentication mechanisms to protect your account.\n\n'
                      '🔒 Regular Audits: We conduct regular security audits and updates.\n\n'
                      'However, no method of transmission over the Internet is 100% secure. While we strive to protect your personal information, we cannot guarantee its absolute security.',
                ),

                _buildPrivacySection(
                  '4. Data Sharing & Disclosure',
                  'We do not sell your personal information. We may share your information only in these circumstances:\n\n'
                      '• Service Providers: With trusted third-party companies that help us operate our service (analytics, payment processing, cloud storage)\n\n'
                      '• Legal Requirements: When required by law or to protect our rights and safety\n\n'
                      '• Business Transfers: In connection with a merger, acquisition, or sale of assets\n\n'
                      '• With Your Consent: When you explicitly agree to share information\n\n'
                      'All third-party service providers are required to maintain the confidentiality of your information.',
                ),

                _buildPrivacySection(
                  '5. Third-Party Services',
                  'Our app may use third-party services that collect information:\n\n'
                      '• Authentication providers (Google, Apple)\n'
                      '• Analytics tools (to understand app usage)\n'
                      '• Payment processors (for subscriptions)\n'
                      '• Cloud storage providers\n\n'
                      'These third parties have their own privacy policies. We encourage you to review their policies when you interact with their services.',
                ),

                _buildPrivacySection(
                  '6. Your Data Rights',
                  'You have several rights regarding your personal data:\n\n'
                      '✅ Access: Request a copy of your personal data\n'
                      '✅ Correction: Update or correct inaccurate information\n'
                      '✅ Deletion: Request deletion of your account and data\n'
                      '✅ Portability: Export your data in a readable format\n'
                      '✅ Opt-Out: Unsubscribe from marketing communications\n'
                      '✅ Withdraw Consent: Revoke previously given consent\n\n'
                      'To exercise these rights, please contact us at privacy@spanx.com or use the in-app settings.',
                ),

                _buildPrivacySection(
                  '7. Data Retention',
                  'We retain your personal information only as long as necessary:\n\n'
                      '• Active accounts: Data is retained while your account is active\n'
                      '• Deleted accounts: Data is deleted within 30 days of account deletion\n'
                      '• Legal obligations: Some data may be retained longer for legal or regulatory purposes\n'
                      '• Backups: Backup copies may persist for up to 90 days\n\n'
                      'You can delete your account at any time from the app settings.',
                ),

                _buildPrivacySection(
                  '8. Children\'s Privacy',
                  'Our service is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. '
                      'If you are a parent or guardian and believe your child has provided us with personal information, please contact us immediately, and we will delete such information.',
                ),

                _buildPrivacySection(
                  '9. Cookies & Tracking',
                  'We use cookies and similar tracking technologies to:\n\n'
                      '• Remember your preferences and settings\n'
                      '• Understand how you use our app\n'
                      '• Improve our service\n'
                      '• Provide personalized content\n\n'
                      'You can control cookies through your device settings, but disabling them may affect app functionality.',
                ),

                _buildPrivacySection(
                  '10. International Data Transfers',
                  'Your information may be transferred to and maintained on servers located outside your jurisdiction. '
                      'By using SPANX, you consent to the transfer of your information to countries that may have different data protection laws. '
                      'We ensure appropriate safeguards are in place to protect your data during international transfers.',
                ),

                _buildPrivacySection(
                  '11. Changes to This Policy',
                  'We may update our Privacy Policy from time to time. We will notify you of any changes by:\n\n'
                      '• Posting the new Privacy Policy in the app\n'
                      '• Sending an email notification\n'
                      '• Showing an in-app notification\n\n'
                      'Changes become effective immediately upon posting. Your continued use of the service after changes constitutes acceptance of the updated policy.',
                ),

                _buildPrivacySection(
                  '12. Contact Us',
                  'If you have any questions or concerns about this Privacy Policy or our data practices, please contact us:\n\n'
                      '📧 Email: privacy@spanx.com\n'
                      '🌐 Website: www.spanx.com/privacy\n'
                      '📍 Address: San Francisco, CA\n'
                      '📞 Phone: Available through support portal\n\n'
                      'We aim to respond to all inquiries within 48 hours.',
                ),

                SizedBox(height: 24.h),

                // Key Points Summary
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primaryColor,
                            size: 20.w,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Key Takeaways',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.greyColor70,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      _buildKeyPoint('We never sell your personal data'),
                      _buildKeyPoint('You have full control over your data'),
                      _buildKeyPoint('We use encryption to protect your information'),
                      _buildKeyPoint('You can delete your account anytime'),
                      _buildKeyPoint('We are committed to transparency'),
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
        'At SPANX, your privacy is our priority. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application. '
        'Please read this policy carefully to understand our practices regarding your data.',
        textAlign: TextAlign.justify,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
          color: Colors.grey[800]!,
        ),
      ),
    );
  }

  Widget _buildPrivacySection(String title, String content) {
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

  Widget _buildKeyPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.fiber_manual_record,
            size: 8.w,
            color: AppColors.primaryColor,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700]!,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
