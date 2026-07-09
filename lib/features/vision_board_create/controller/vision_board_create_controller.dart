import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:spanx/features/vision_board/controller/vision_controller.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/local/local_data.dart';
import '../../../core/network_caller/endpoints.dart';
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
        imageQuality: 80,
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
  final RxString selectedDate = ''.obs; // human-readable, for display only
  final Rxn<DateTime> selectedDateTime = Rxn<DateTime>(); // actual value sent

  Future<void> pickDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      selectedDateTime.value = picked;
      selectedDate.value = DateFormat('dd MMMM yyyy').format(picked);
    }
  }

  // ========= save vision ============
  final RxBool isLoading = false.obs;
  Future<void> saveMotivation() async {
    final pickedDate = selectedDateTime.value;
    if (pickedDate == null) {
      Fluttertoast.showToast(
        msg: "Please select a date",
        backgroundColor: AppColors.redColor,
      );
      return;
    }
    if (profileImage.value == null) {
      Fluttertoast.showToast(
        msg: "Please choose a photo",
        backgroundColor: AppColors.redColor,
      );
      return;
    }
    isLoading.value = true;

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(Urls.createVisionBoard),
      );
      final String token = await LocalService().getToken() ?? '';

      if (token.isEmpty) {
        Fluttertoast.showToast(
          msg: "Authentication error",
          backgroundColor: AppColors.redColor,
        );
        return;
      }

      // For a MultipartRequest, DO NOT set Content-Type manually — the http
      // package generates it WITH the required "boundary=..." parameter on
      // send(). Setting it here strips the boundary, so the server cannot parse
      // the upload and the save silently fails.
      request.headers.addAll({
        'Authorization': token, // raw JWT — backend rejects "Bearer " prefix
      });

      // Send an ISO-8601 date so the backend (and our own model, which does
      // DateTime.parse) can reliably parse it. The old human format
      // ("09 July 2026") could fail to parse and hide saved boards.
      Map<String, dynamic> createData = {"year": pickedDate.toIso8601String()};
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

      var streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
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
        Get.back();
        clearField();
        clearImage();
      } else {
        Get.snackbar(
          'Failed',
          newRes?['message']?.toString() ??
              'Could not save vision board. Please try again.',
          colorText: AppColors.blackColor,
          backgroundColor: AppColors.redColor,
        );
      }
    } catch (e) {
      log("Error: ${e.toString()}");
      Get.snackbar(
        'Error',
        'Something went wrong. Please try again.',
        colorText: AppColors.blackColor,
        backgroundColor: AppColors.redColor,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void clearField() {
    selectedDate.value = '';
    selectedDateTime.value = null;
  }

}