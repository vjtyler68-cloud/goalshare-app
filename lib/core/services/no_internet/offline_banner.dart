import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controller.dart';

/// Slim, non-blocking "you're offline" strip shown at the very top of the app.
///
/// This replaces the old full-screen no-internet takeover. GoalShare is
/// offline-capable: missions & career stats, leads, nutrition log, gratitude
/// journal, todos, goals, budget, the Bible reader, the daily spark, and cached
/// chat all read from on-device storage and keep working with no signal. So we
/// no longer trap the user on a dead-end screen — we just quietly signal the
/// state here, and network-only actions surface their own inline message when
/// tried. The strip slides away on its own the moment the connection returns.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ConnectivityController>()) {
      return const SizedBox.shrink();
    }
    final controller = Get.find<ConnectivityController>();

    return Obx(() {
      final offline = !controller.isConnected.value;
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: offline
            ? const Align(
                alignment: Alignment.topCenter,
                child: Material(
                  color: const Color(0xFF334155),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              "You're offline — your work is saved and syncs when you're back.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      );
    });
  }
}
