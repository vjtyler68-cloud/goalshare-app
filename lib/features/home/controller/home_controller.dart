import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spanx/features/home/model/home_screen_model.dart';
import 'package:spanx/features/motivationalNudges/controller/motivational_nudges_controller.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/network_caller/endpoints.dart';
import '../../../core/network_caller/network_config.dart';

class HomeController extends GetxController {
  final motivations = Get.find<MotivationalNudgesController>();

  // url launcher
  Future<void> launchBibleSite(String webLink) async {
    final Uri url = Uri.parse(webLink);

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  final RxString randomMotivationLine =
      "Every great business starts with one small sale.".obs;

  int randomIndex() {
    final totalMotivations = motivations.motivationNudgesList.length;
    final int randomNumber = Random().nextInt(totalMotivations);
    return randomNumber;
  }

  @override
  void onInit() {
    super.onInit();
    getHomeMyWhy();
    getHomeAffirmation();
  }

  // CREATE ========== my why & affirmations =============
  final myWhyAffirmation = TextEditingController();
  final RxBool isLoading = false.obs;
  final RxList<HomeMyWhyModel> homeMyWhyList = <HomeMyWhyModel>[].obs;
  final RxList<HomeMyWhyModel> homeMyAffirmationList = <HomeMyWhyModel>[].obs;

  Future<void> createHomeMyWhy() async {
    isLoading.value = true;
    final inputText = myWhyAffirmation.text.trim();
    if (inputText.isEmpty) {
      isLoading.value = false;
      return;
    }

    final response = await NetworkConfig.instance.ApiRequestHandler(
      RequestMethod.POST,
      Urls.createHomeMYWHY,
      jsonEncode({"text": inputText}),
      is_auth: true,
    );

    try {
      if (response != null && response['success'] == true) {
        // ✅ Option 1: Use the returned data (best practice)
        if (response['data'] != null) {
          final newWhy = HomeMyWhyModel.fromJson(response['data']);
          homeMyWhyList.add(newWhy);
        } else {
          // ✅ Option 2: Fallback – create a temporary local model (less ideal)
          final tempWhy = HomeMyWhyModel(
            text: inputText,
            createdAt: DateTime.now(),
          );
          homeMyWhyList.add(tempWhy);
        }

        myWhyAffirmation.clear(); // Clear input
        Get.back(); // Close dialog or bottom sheet
      } else {
        Get.snackbar(
          'Failed',
          'My Why Creation Failed',
          backgroundColor: AppColors.redColor,
        );
      }
    } catch (e) {
      print("My Why Creation error: ${e.toString()}");
      Get.snackbar(
        'Error',
        'Something went wrong',
        backgroundColor: AppColors.redColor,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createHomeAffirmation() async {
    isLoading.value = true;
    final inputText = myWhyAffirmation.text.trim();
    if (inputText.isEmpty) {
      isLoading.value = false;
      return;
    }

    final response = await NetworkConfig.instance.ApiRequestHandler(
      RequestMethod.POST,
      Urls.createHomeMYAFFIRMATION,
      jsonEncode({"text": inputText}),
      is_auth: true,
    );

    try {
      if (response != null && response['success'] == true) {
        if (response['data'] != null) {
          final newAffirmation = HomeMyWhyModel.fromJson(response['data']);
          homeMyAffirmationList.add(newAffirmation);
        } else {
          final tempAffirmation = HomeMyWhyModel(
            text: inputText,
            createdAt: DateTime.now(),
          );
          homeMyAffirmationList.add(tempAffirmation);
        }

        myWhyAffirmation.clear();
        Get.back();
      } else {
        Get.snackbar(
          'Failed',
          'Affirmation Creation Failed',
          backgroundColor: AppColors.redColor,
        );
      }
    } catch (e) {
      print("Affirmation Creation error: ${e.toString()}");
      Get.snackbar(
        'Error',
        'Something went wrong',
        backgroundColor: AppColors.redColor,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // GET ========== my why & affirmations =============

  Future<void> getHomeMyWhy() async {
    isLoading.value = true;
    final response = await NetworkConfig.instance.ApiRequestHandler(
      RequestMethod.GET,
      Urls.getHomeMYWHY,
      jsonEncode({}),
      is_auth: true,
    );

    try {
      if (response != null && response['success'] == true) {
        homeMyWhyList.assignAll(
          (response['data'] as List)
              .map((e) => HomeMyWhyModel.fromJson(e))
              .toList(),
        );
        Get.back();
        isLoading.value = false;
      } else {
        Get.snackbar(
          'Failed',
          'My Why Creation Failed',
          backgroundColor: AppColors.redColor,
        );
      }
    } catch (e) {
      print("My Why Creation error: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getHomeAffirmation() async {
    isLoading.value = true;
    final response = await NetworkConfig.instance.ApiRequestHandler(
      RequestMethod.GET,
      Urls.getHomeMYAFFIRMATION,
      jsonEncode({}),
      is_auth: true,
    );

    try {
      if (response != null && response['success'] == true) {
        homeMyAffirmationList.assignAll(
          (response['data'] as List)
              .map((e) => HomeMyWhyModel.fromJson(e))
              .toList(),
        );
        Get.back();
        isLoading.value = false;
      } else {
        Get.snackbar(
          'Failed',
          'My Why Creation Failed',
          backgroundColor: AppColors.redColor,
        );
      }
    } catch (e) {
      print("My Why Creation error: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  // DELETE ========== my why & affirmations =============
  // Future<void> deleteHomeMyWhy(String myWhyID) async {
  //   isLoading.value = true;
  //   final response = await NetworkConfig.instance.ApiRequestHandler(
  //     RequestMethod.DELETE,
  //     '${Urls.deleteHomeMYWHY}/$myWhyID',
  //     jsonEncode({}),
  //     is_auth: true,
  //   );
  //
  //   try {
  //     if (response != null && response['success'] == true) {
  //       homeMyWhyList.assignAll(
  //         (response['data'] as List)
  //             .map((e) => HomeMyWhyModel.fromJson(e))
  //             .toList(),
  //       );
  //       Get.back();
  //       isLoading.value = false;
  //     } else {
  //       Get.snackbar(
  //         'Failed',
  //         'My Why Creation Failed',
  //         backgroundColor: AppColors.redColor,
  //       );
  //     }
  //   } catch (e) {
  //     print("My Why Creation error: ${e.toString()}");
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  Future<void> deleteHomeMyWhy(String myWhyID) async {
    try {
      // 🔹 Find and remove locally first (optimistic update)
      final index = homeMyWhyList.indexWhere((e) => e.id == myWhyID);
      if (index == -1) return;

      final removedItem = homeMyWhyList[index];
      homeMyWhyList.removeAt(index);

      // 🔹 Run delete API call in background
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.DELETE,
        '${Urls.deleteHomeMYWHY}/$myWhyID',
        jsonEncode({}),
        is_auth: true,
      );

      // 🔹 Validate response
      if (response != null && response['success'] == true) {
        Get.snackbar(
          'Deleted',
          'My Why deleted successfully',
          backgroundColor: AppColors.greenColor,
        );
      } else {
        // ❌ Revert UI if failed
        homeMyWhyList.insert(index, removedItem);
        Get.snackbar(
          'Failed',
          'Delete failed, please try again',
          backgroundColor: AppColors.redColor,
        );
      }
    } catch (e) {
      print("Delete error: ${e.toString()}");
      Get.snackbar(
        'Error',
        'Something went wrong',
        backgroundColor: AppColors.redColor,
      );
    }
  }

  Future<void> deleteHomeAffirmation(String affirmationID) async {
    try {
      // 🔹 Find and remove locally first (optimistic UI update)
      final index =
      homeMyAffirmationList.indexWhere((e) => e.id == affirmationID);
      if (index == -1) return;

      final removedItem = homeMyAffirmationList[index];
      homeMyAffirmationList.removeAt(index);

      // 🔹 Run delete API call in background
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.DELETE,
        '${Urls.deleteHomeMYAFFIRMATION}/$affirmationID',
        jsonEncode({}),
        is_auth: true,
      );

      // 🔹 Validate response
      if (response != null && response['success'] == true) {
        Get.snackbar(
          'Deleted',
          'Affirmation deleted successfully',
          backgroundColor: AppColors.greenColor,
        );
      } else {
        // ❌ Revert UI if failed
        homeMyAffirmationList.insert(index, removedItem);
        Get.snackbar(
          'Failed',
          'Delete failed, please try again',
          backgroundColor: AppColors.redColor,
        );
      }
    } catch (e) {
      print("Affirmation Delete error: ${e.toString()}");
      Get.snackbar(
        'Error',
        'Something went wrong',
        backgroundColor: AppColors.redColor,
      );
    }
  }


}
