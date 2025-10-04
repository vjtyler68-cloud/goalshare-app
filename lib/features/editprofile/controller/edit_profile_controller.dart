import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/core/user_info/user_info_controller.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/local/local_data.dart';
import '../../../core/network_caller/endpoints.dart';

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

  // Profile Info Text Controllers
  final fullName = TextEditingController();
  final email = TextEditingController();
  final businessType = TextEditingController();
  final describeProfession = TextEditingController();
  final city = TextEditingController();
  final fullAddress = TextEditingController();
  final phoneNumber = TextEditingController();

  // Loading indicator
  final RxBool isPictureLoading = false.obs;

  /// Save profile picture API
  Future<bool> saveProfilePicture() async {
    if (profileImage.value == null) {
      // If no image selected, just return true to not block saving profile info
      return true;
    }

    isPictureLoading.value = true;

    try {
      final String token = await LocalService().getToken();

      if (token.isEmpty) {
        throw Exception("Authentication error");
      }

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
          userInfo.loadAndSetUserInfo();
          Get.snackbar(
            'Success',
            '${newRes['message']}',
            colorText: AppColors.blackColor,
            backgroundColor: AppColors.greenColor,
          );
          return true;
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

  /// Save profile info API
  Future<bool> saveProfileInfo() async {
    isPictureLoading.value = true;

    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.PUT,
        Urls.userUpdateProfile,
        jsonEncode({
          "fullName": fullName.text,
          "phoneNumber": "+44${phoneNumber.text}",
          "describe": describeProfession.text,
          "city": city.text,
          "address": fullAddress.text,
        }),
        is_auth: true,
      );

      if (response != null && response['success'] == true) {
        userInfo.loadAndSetUserInfo();
        return true;
      } else {
        throw Exception(response?['message'] ?? 'Info update failed');
      }
    } catch (e) {
      log("Error saving profile info: $e");
      throw e;
    } finally {
      isPictureLoading.value = false;
    }
  }

  /// Save both profile picture and info simultaneously
  Future<void> saveAllProfileChanges() async {
    isPictureLoading.value = true;

    try {
      await Future.wait([
        saveProfilePicture(),
        saveProfileInfo(),
      ]);

      Get.snackbar('Success', 'Profile updated successfully');
      Get.back();
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isPictureLoading.value = false;
    }
  }
}
