import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spanx/core/user_info/user_info_controller.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/local/local_data.dart';
import '../../../core/network_caller/endpoints.dart';
import '../../../routes/app_routes.dart';

class EditProfileController extends GetxController {
 final userInfo = Get.find<UserInfoController>();
  final ImagePicker _picker = ImagePicker();
  final profileImage = Rxn<File>();
  final profileImageUrl = ''.obs;

  // Image selection methods
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
      //     GetSnackBar  .show(
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
        log("Image selected from gallery: ${image.path}");
      }
    } catch (e) {
      log("Error picking image from gallery: $e");
      // AppSnackbar.show(
      //   message: 'Failed to select image: ${e.toString()}',
      //   isSuccess: false,
      // );
    }
  }

  void removeProfileImage() {
    profileImage.value = null;
    profileImageUrl.value = '';
    log("Profile image removed");
  }

  void clearImage() {
    profileImage.value = null;
  }

  // Profile Info
  final fullName = TextEditingController(); //
  final email = TextEditingController();
  final businessType = TextEditingController();
  final describeProfession = TextEditingController(); //
  final city = TextEditingController(); //
  final fullAddress = TextEditingController(); //
  final phoneNumber = TextEditingController(); //

  // ========== api for profile picture ==============
  final RxBool isPictureLoading = false.obs;

  Future<void> saveProfilePicture() async {
    isPictureLoading.value = true;

    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse(Urls.userUploadPhoto),
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
        userInfo.loadAndSetUserInfo();
        Get.back();

        // clearField();
        // clearImage();

      }
    } catch (e) {
      log("Error: ${e.toString()}");
    } finally {
      isPictureLoading.value = false;
    }
  }
}
