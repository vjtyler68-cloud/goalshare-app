import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/features/motivationalNudges/controller/motivational_nudges_controller.dart';
import 'package:spanx/routes/app_routes.dart';

class CreateMotivationController extends GetxController {
  final ImagePicker _picker = ImagePicker();

  final profileImage = Rxn<File>();

  final motivation = Get.find<MotivationalNudgesController>();

  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (image != null) {
        profileImage.value = File(image.path);
        log("Image selected from camera: ${image.path}");
      }
    } catch (e) {
      log("Error picking image from camera: $e");
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 80,
      );

      if (image != null) {
        profileImage.value = File(image.path);
        log("Image selected from gallery: ${image.path}");
      }
    } catch (e) {
      log("Error picking image from gallery: $e");
    }
  }

  void removeProfileImage() {
    profileImage.value = null;
    // log("Profile image removed");
  }

  void clearImage() {
    profileImage.value = null;
  }

  // ============ api============
  final RxBool isLoading = false.obs;
  final createMotivation = TextEditingController();

  Future<void> saveMotivation() async {
    isLoading.value = true;

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(Urls.createMotivationalNudges),
      );
      final String token = await LocalService().getToken();

      if (token.isEmpty) {
        Fluttertoast.showToast(
          msg: "Authentication error",
          backgroundColor: AppColors.redColor,
        );
        return;
      }

      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        'Authorization': token,
      });

      Map<String, dynamic> createData = {"title": createMotivation.text.trim()};
      request.fields['data'] = json.encode(createData);

      if (profileImage.value != null) {
        var imageBytes = await profileImage.value!.readAsBytes();
        var multipartFile = http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        request.files.add(multipartFile);
      }

      var streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final newRes = json.decode(response.body);
      // log("NEW RES------- ${newRes.toString()}");
      // log("NEW RES------- ${response.statusCode.toString()}");
      if (newRes != null && newRes['success'] == true) {
        Get.snackbar(
          'Success',
          '${newRes['message']}',
          colorText: AppColors.blackColor,
          backgroundColor: AppColors.greenColor,
        );
        motivation.fetchMotivationalNudges();
        // Get.offNamed(AppRoutes.motivationalNudgeScreen);
        clearField();
        clearImage();
        Get.back();
      }
    } catch (e) {
      log("Error: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  void clearField() {
    createMotivation.clear();
  }
}
