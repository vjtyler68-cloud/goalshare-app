import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/features/motivationalNudges/controller/motivational_nudges_controller.dart';

class CreateMotivationController extends GetxController {
  final ImagePicker _picker = ImagePicker();

  final profileImage = Rxn<File>();
  final RxBool isLoading = false.obs;

  final createMotivation = TextEditingController();

  final motivation = Get.find<MotivationalNudgesController>();

  static const int maxFileSize = 5 * 1024 * 1024; // 5MB

  // ================= IMAGE PICK =================

  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        if (await file.length() > maxFileSize) {
          Fluttertoast.showToast(
            msg: "Image must be less than 5MB",
            backgroundColor: AppColors.redColor,
          );
          return;
        }
        profileImage.value = file;
      }
    } catch (e) {
      log("Camera error: $e");
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        if (await file.length() > maxFileSize) {
          Fluttertoast.showToast(
            msg: "Image must be less than 5MB",
            backgroundColor: AppColors.redColor,
          );
          return;
        }
        profileImage.value = file;
      }
    } catch (e) {
      log("Gallery error: $e");
    }
  }

  void removeProfileImage() {
    profileImage.value = null;
  }

  void clearField() {
    createMotivation.clear();
  }

  // ================= API =================

  Future<void> saveMotivation() async {
    if (isLoading.value) return;

    if (createMotivation.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: "Please write your motivation first",
        backgroundColor: AppColors.redColor,
      );
      return;
    }

    isLoading.value = true;

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(Urls.createMotivationalNudges),
      );

      final String token = await LocalService().getToken() ?? '';

      if (token.isEmpty) {
        Fluttertoast.showToast(
          msg: "Authentication error",
          backgroundColor: AppColors.redColor,
        );
        return;
      }

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': token, // raw JWT — backend rejects "Bearer " prefix
      });

      Map<String, dynamic> createData = {
        "title": createMotivation.text.trim(),
      };

      request.fields['data'] = json.encode(createData);

      if (profileImage.value != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            profileImage.value!.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      // Parse defensively: a cold-start / proxy outage can return an HTML page,
      // and an unconditional json.decode would throw into the generic catch and
      // hide the real reason from the user.
      Map<String, dynamic>? newRes;
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) newRes = decoded;
      } catch (_) {
        newRes = null;
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          newRes != null &&
          newRes['success'] == true) {
        Get.snackbar(
          'Success',
          newRes['message'] ?? "Created successfully",
          backgroundColor: AppColors.greenColor,
        );

        motivation.fetchMotivationalNudges();

        clearField();
        removeProfileImage();
        Get.back();
      } else {
        Fluttertoast.showToast(
          msg: newRes?['message'] ?? "Something went wrong",
          backgroundColor: AppColors.redColor,
        );
      }
    } catch (e) {
      log("Save motivation error: $e");
      Fluttertoast.showToast(
        msg: "Failed to create motivation",
        backgroundColor: AppColors.redColor,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    createMotivation.dispose();
    super.onClose();
  }
}
