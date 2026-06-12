import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/routes/app_routes.dart';

import '../model/vision_model.dart';

class VisionBoardController extends GetxController {
  final RxList<VisionBoardModel> visionBoardItems = <VisionBoardModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxSet<String> deletingIDs = <String>{}.obs;

  bool isDeleting(String id) => deletingIDs.contains(id);

  @override
  void onInit() {
    super.onInit();
    fetchVisionBoard();
  }

  Future<void> fetchVisionBoard() async {
    isLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.getVisionBoard,
        jsonEncode({}),
        is_auth: true,
      );

      if (response != null && response['success'] == true) {
        visionBoardItems.assignAll(
          (response['data'] as List).map((e) => VisionBoardModel.fromJson(e)),
        );
      }
    } catch (e) {
      log('fetchVisionBoard error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteVisionBoardItem(String id) async {
    final index = visionBoardItems.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final removed = visionBoardItems[index];
    deletingIDs.add(id);
    visionBoardItems.removeAt(index);

    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.DELETE,
        Urls.deleteVision(id),
        jsonEncode({}),
        is_auth: true,
      );

      if (response == null || response['success'] != true) {
        visionBoardItems.insert(index, removed);
        AppSnackBar.error(response?['message'] ?? 'Delete failed. Please try again.');
      }
    } catch (e) {
      log('deleteVisionBoardItem error: $e');
      visionBoardItems.insert(index, removed);
      AppSnackBar.error('Something went wrong. Please try again.');
    } finally {
      deletingIDs.remove(id);
    }
  }

  void onCreateNewTap() => Get.toNamed(AppRoutes.visionPageCreateScreen);

  // kept for UI compatibility
  void refreshVisionBoard() => fetchVisionBoard();
}
