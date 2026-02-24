import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/routes/app_routes.dart';

import '../model/vision_model.dart';

class VisionBoardController extends GetxController {
  final RxList<VisionBoardModel> visionBoardItems = <VisionBoardModel>[].obs;
  final RxBool isLoading = false.obs;

  // only load that specific item which is being deleted,
  // instead of loading the whole list again
  final RxSet<String> deletedIDs = <String>{}.obs;
  bool isDeleting(String id) => deletedIDs.contains(id);

  @override
  void onInit() {
    super.onInit();
    // loadVisionBoardItems();
    fetchVisionBoard();
  }

  Future<void> fetchVisionBoard() async {
    isLoading.value = true;
    final response = await NetworkConfig.instance.ApiRequestHandler(
      RequestMethod.GET,
      Urls.getVisionBoard,
      jsonEncode({}),
      is_auth: true,
    );


    try {
      if (response != null && response['success'] == true) {
        visionBoardItems.assignAll(
          (response['data'] as List).map((e) => VisionBoardModel.fromJson(e)),
        );
        isLoading.value = false;
      }
    } catch (e) {
      log('Fetching Vision Error: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void deleteVisionBoardItem(String id) async {
    deletedIDs.add(id);
    // isLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.DELETE,
        Urls.deleteVision(id),
        jsonEncode({}),
        is_auth: true,
      );
      if (response != null && response['success'] == true) {
        visionBoardItems.removeWhere((item) => item.id == id);
        isLoading.value = false;
      }
    } catch (e) {
      log('Deleting Vision Error: ${e.toString()}');
    } finally {
      // isLoading.value = false;
      deletedIDs.remove(id);
    }
  }

  void onCreateNewTap() {
    Get.toNamed(AppRoutes.visionPageCreateScreen);
  }

  void refreshVisionBoard() {
    // loadVisionBoardItems();
  }
}
