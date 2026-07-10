import 'package:get/get.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/core/notifications/notification_service.dart';

/// Backs the Notifications settings screen. Loads the saved toggle state and
/// keeps the on-device schedule in sync as the user flips switches.
class NotificationsController extends GetxController {
  final LocalService _local = LocalService();

  final RxBool enabled = false.obs; // master
  final RxBool morningGoal = true.obs;
  final RxBool eveningStreak = true.obs;
  final RxBool leadFollowup = true.obs;
  final RxBool busy = false.obs; // guards the permission round-trip

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    enabled.value = await _local.getNotificationsEnabled();
    morningGoal.value = await _local.getNotifyMorningGoal();
    eveningStreak.value = await _local.getNotifyEveningStreak();
    leadFollowup.value = await _local.getNotifyLeadFollowup();
  }

  Future<void> toggleMaster(bool value) async {
    if (busy.value) return;
    busy.value = true;
    try {
      if (value) {
        final granted = await NotificationService.instance.requestPermission();
        if (!granted) {
          enabled.value = false;
          await _local.setNotificationsEnabled(false);
          AppSnackBar.error(
            'Allow notifications for GoalShare in your device Settings to turn these on.',
          );
          return;
        }
        enabled.value = true;
        await _local.setNotificationsEnabled(true);
        await NotificationService.instance.refreshSchedule();
        AppSnackBar.success("Reminders on. We'll help you keep the momentum.");
      } else {
        enabled.value = false;
        await _local.setNotificationsEnabled(false);
        await NotificationService.instance.cancelAll();
      }
    } finally {
      busy.value = false;
    }
  }

  Future<void> toggleMorning(bool v) => _setSub(
    morningGoal,
    _local.setNotifyMorningGoal,
    v,
  );

  Future<void> toggleEvening(bool v) => _setSub(
    eveningStreak,
    _local.setNotifyEveningStreak,
    v,
  );

  Future<void> toggleLeads(bool v) => _setSub(
    leadFollowup,
    _local.setNotifyLeadFollowup,
    v,
  );

  Future<void> _setSub(
    RxBool field,
    Future<void> Function(bool) save,
    bool value,
  ) async {
    field.value = value;
    await save(value);
    if (enabled.value) await NotificationService.instance.refreshSchedule();
  }

  Future<void> sendTest() async {
    if (!enabled.value) {
      AppSnackBar.error('Turn on reminders first.');
      return;
    }
    await NotificationService.instance.showTest();
    AppSnackBar.success('Test sent — check your notification tray.');
  }
}
