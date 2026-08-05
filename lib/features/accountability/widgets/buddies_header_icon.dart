import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controller/buddies_controller.dart';
import '../ui/accountability_match_screen.dart';
import '../ui/buddies_hub_screen.dart';
import '../ui/buddy_questionnaire_screen.dart';

/// Small round Buddies shortcut for the Profile hero — sits under the "Add"
/// button. Deep-links to the right place for the user's current state.
class BuddiesHeaderIcon extends StatelessWidget {
  const BuddiesHeaderIcon({super.key});

  Future<void> _open() async {
    final c = BuddiesController.to;
    // Wait for the saved profile/match to load so we route on real state, not a
    // race (otherwise a saved profile looks unset and dumps you back into setup).
    await c.ensureLoaded();
    if (c.needsOnboarding) {
      Get.to(() => const BuddyQuestionnaireScreen());
    } else if (c.isMatched) {
      Get.to(() => const AccountabilityMatchScreen());
    } else {
      Get.to(() => const BuddiesHubScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _open,
      child: Container(
        width: 40.r,
        height: 40.r,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.35)),
        ),
        child: Icon(Icons.handshake_rounded, color: Colors.white, size: 20.r),
      ),
    );
  }
}
