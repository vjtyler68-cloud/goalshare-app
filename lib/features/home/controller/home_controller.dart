import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/features/home/model/home_screen_model.dart';
import 'package:spanx/features/motivationalNudges/controller/motivational_nudges_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeController extends GetxController {
  final motivations = Get.find<MotivationalNudgesController>();

  final RxString randomMotivationLine =
      'Every great business starts with one small sale.'.obs;
  final RxBool isLoading = false.obs;
  final RxList<HomeMyWhyModel> homeMyWhyList = <HomeMyWhyModel>[].obs;
  final RxList<HomeMyWhyModel> homeMyAffirmationList = <HomeMyWhyModel>[].obs;
  final myWhyAffirmation = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    getHomeMyWhy();
    getHomeAffirmation();
  }

  @override
  void onClose() {
    myWhyAffirmation.dispose();
    super.onClose();
  }

  Future<void> launchBibleSite(String webLink) async {
    final uri = Uri.parse(webLink);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      AppSnackBar.error('Could not open link');
    }
  }

  int randomIndex() {
    final total = motivations.motivationNudgesList.length;
    if (total == 0) return 0;
    return Random().nextInt(total);
  }

  Future<void> createHomeMyWhy() async {
    final inputText = myWhyAffirmation.text.trim();
    if (inputText.isEmpty) return;
    isLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.createHomeMYWHY,
        jsonEncode({'text': inputText}),
        is_auth: true,
      );

      if (response != null && response['success'] == true) {
        final newWhy = response['data'] != null
            ? HomeMyWhyModel.fromJson(response['data'])
            : HomeMyWhyModel(text: inputText, createdAt: DateTime.now());
        homeMyWhyList.add(newWhy);
        myWhyAffirmation.clear();
        Get.back();
        AppSnackBar.success('My Why added!');
      } else {
        AppSnackBar.error(response?['message'] ?? 'Failed to add My Why');
      }
    } catch (e) {
      log('createHomeMyWhy error: $e');
      AppSnackBar.error('Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createHomeAffirmation() async {
    final inputText = myWhyAffirmation.text.trim();
    if (inputText.isEmpty) return;
    isLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.createHomeMYAFFIRMATION,
        jsonEncode({'text': inputText}),
        is_auth: true,
      );

      if (response != null && response['success'] == true) {
        final newAffirmation = response['data'] != null
            ? HomeMyWhyModel.fromJson(response['data'])
            : HomeMyWhyModel(text: inputText, createdAt: DateTime.now());
        homeMyAffirmationList.add(newAffirmation);
        myWhyAffirmation.clear();
        Get.back();
        AppSnackBar.success('Affirmation added!');
      } else {
        AppSnackBar.error(response?['message'] ?? 'Failed to add affirmation');
      }
    } catch (e) {
      log('createHomeAffirmation error: $e');
      AppSnackBar.error('Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getHomeMyWhy() async {
    isLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.getHomeMYWHY,
        jsonEncode({}),
        is_auth: true,
      );

      if (response != null && response['success'] == true) {
        homeMyWhyList.assignAll(
          (response['data'] as List).map((e) => HomeMyWhyModel.fromJson(e)),
        );
      }
    } catch (e) {
      log('getHomeMyWhy error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getHomeAffirmation() async {
    isLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.getHomeMYAFFIRMATION,
        jsonEncode({}),
        is_auth: true,
      );

      if (response != null && response['success'] == true) {
        homeMyAffirmationList.assignAll(
          (response['data'] as List).map((e) => HomeMyWhyModel.fromJson(e)),
        );
      }
    } catch (e) {
      log('getHomeAffirmation error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteHomeMyWhy(String myWhyID) async {
    final index = homeMyWhyList.indexWhere((e) => e.id == myWhyID);
    if (index == -1) return;

    final removedItem = homeMyWhyList[index];
    homeMyWhyList.removeAt(index);

    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.DELETE,
        '${Urls.deleteHomeMYWHY}/$myWhyID',
        jsonEncode({}),
        is_auth: true,
      );

      if (response == null || response['success'] != true) {
        homeMyWhyList.insert(index, removedItem);
        AppSnackBar.error('Delete failed. Please try again.');
      }
    } catch (e) {
      log('deleteHomeMyWhy error: $e');
      homeMyWhyList.insert(index, removedItem);
      AppSnackBar.error('Something went wrong. Please try again.');
    }
  }

  Future<void> deleteHomeAffirmation(String affirmationID) async {
    final index =
        homeMyAffirmationList.indexWhere((e) => e.id == affirmationID);
    if (index == -1) return;

    final removedItem = homeMyAffirmationList[index];
    homeMyAffirmationList.removeAt(index);

    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.DELETE,
        '${Urls.deleteHomeMYAFFIRMATION}/$affirmationID',
        jsonEncode({}),
        is_auth: true,
      );

      if (response == null || response['success'] != true) {
        homeMyAffirmationList.insert(index, removedItem);
        AppSnackBar.error('Delete failed. Please try again.');
      }
    } catch (e) {
      log('deleteHomeAffirmation error: $e');
      homeMyAffirmationList.insert(index, removedItem);
      AppSnackBar.error('Something went wrong. Please try again.');
    }
  }
}
