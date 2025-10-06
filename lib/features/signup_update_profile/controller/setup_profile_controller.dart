import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spanx/core/user_info/user_info_controller.dart';
import 'package:spanx/features/editprofile/controller/edit_profile_controller.dart';
import 'package:spanx/routes/app_routes.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/local/local_data.dart';
import '../../../core/network_caller/endpoints.dart';
import '../../../core/network_caller/network_config.dart';
import 'package:flutter/material.dart';

class SetupProfileController extends GetxController {
  final fullName = TextEditingController();
  final email = TextEditingController();
  final businessType = TextEditingController();
  final describeProfession = TextEditingController();
  final city = TextEditingController();
  final fullAddress = TextEditingController();
  final phoneNumber = TextEditingController();
  
  // =================== Setup Profile =========================
  final RxBool isInfoLoading = false.obs;
  /// Save profile info API
  Future<void> saveProfileInfo(String name) async {
    isInfoLoading.value = true;

    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.PUT,
        Urls.userUpdateProfile,
        jsonEncode({
          "fullName": name,
          "phoneNumber": "+44${phoneNumber.text}",
          "describe": describeProfession.text,
          "city": city.text,
          "businessType": businessType.text,
          "address": fullAddress.text,
        }),
        is_auth: true,
      );

      if (response != null && response['success'] == true) {
            isInfoLoading.value = false;
        Get.offNamed(AppRoutes.uploadProfilePictureScreen);
      
      } else {
        throw Exception(response?['message'] ?? 'Info update failed');
      }
    } catch (e) {
      log("Error saving profile info: $e");
      throw e;
    } finally {
      isInfoLoading.value = false;
    }
  }

  // =====================================================================
  // final Rx<File?>
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


  // Loading indicator
  final RxBool isPictureLoading = false.obs;

  /// Save profile picture API
  Future<void> saveProfilePicture() async {
    log(LocalService().getToken().toString());
    if (profileImage.value == null) {
      // If no image selected, just return true to not block saving profile info
       Get.snackbar(
        'Failed',
        'No Images Found',
        colorText: AppColors.blackColor,
        backgroundColor: AppColors.redColor,
      );
    }

    isPictureLoading.value = true;

    try {
      final String token = await LocalService().getToken();


      final request = http.MultipartRequest(
        'PUT',
        Uri.parse(Urls.userUploadPhoto),
      );

      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        'Authorization': token,
      });

      var imageBytes = await profileImage.value!.readAsBytes();
      var multipartFile = http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final newRes = json.decode(response.body);
        if (newRes != null && newRes['success'] == true) {

          Get.snackbar(
            'Success',
            '${newRes['message']}',
            colorText: AppColors.blackColor,
            backgroundColor: AppColors.greenColor,
          );
          Get.offAllNamed(AppRoutes.loginScreen);
          isPictureLoading.value = false;
        } else {
          throw Exception(newRes?['message'] ?? 'Failed to upload profile picture');
        }
      } else {
        throw Exception("Failed to upload image. Status: ${response.statusCode}");
      }
    } catch (e) {
      log("Error saving profile picture: $e");
      throw e;
    } finally {
      isPictureLoading.value = false;
    }
  }



}
