import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:http/http.dart' as http;
import 'package:spanx/features/vision_board/controller/vision_controller.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/local/local_data.dart';
import '../../../core/network_caller/endpoints.dart';
import '../../../routes/app_routes.dart';

class VisionBoardCreateController extends GetxController{
final visonController = Get.find<VisionBoardController>();
  final ImagePicker _picker = ImagePicker();

  final profileImage = Rxn<File>();

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
        // log("Image selected from camera: ${image.path}");
      }
    } catch (e) {
      // log("Error picking image from camera: $e");
      // AppSnackbar.show(
      //   message: 'Failed to capture image: ${e.toString()}',
      //   isSuccess: false,
      // );
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (image != null) {
        profileImage.value = File(image.path);
        // log("Image selected from gallery: ${image.path}");
      }
    } catch (e) {
      // log("Error picking image from gallery: $e");
      // AppSnackbar.show(
      //   message: 'Failed to select image: ${e.toString()}',
      //   isSuccess: false,
      // );
    }
  }

  void removeProfileImage() {
    profileImage.value = null;
    // log("Profile image removed");
  }

  void clearImage() {
    profileImage.value = null;
  }

  // =========== Date ==============
  final RxString selectedDate = ''.obs;

  Future<void> pickDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
    );
    if (picked != null) {
      String formattedDate = DateFormat('dd MMMM yyyy').format(picked);
      // selectedDate.value = "${picked.toLocal()}".split(' ')[0];
      selectedDate.value = formattedDate;
    }
  }

  // ========= save vision ============
  final RxBool isLoading = false.obs;
  Future<void> saveMotivation() async {
    isLoading.value = true;

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(Urls.createVisionBoard),
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

      Map<String, dynamic> createData = {"year": selectedDate.value};
      request.fields['data'] = json.encode(createData);

      if (profileImage.value != null) {
        var imageBytes = await profileImage.value!.readAsBytes();
        var multipartFile = http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'vision_${DateTime.now().millisecondsSinceEpoch}.jpg',
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
        visonController.fetchVisionBoard();
        Get.offNamed(AppRoutes.visionPageScreen);
        clearField();
        clearImage();


      }
    } catch (e) {
      log("Error: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  void clearField() {
    selectedDate.value = '';
  }

}