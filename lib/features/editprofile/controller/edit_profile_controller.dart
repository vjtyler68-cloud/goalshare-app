import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/const/country_list.dart';
import '../../../core/local/local_data.dart';
import '../../../core/network_caller/endpoints.dart';
import '../../../core/network_caller/network_config.dart';
import '../../../core/user_info/user_info_controller.dart';

class EditProfileController extends GetxController {
  final userInfo = Get.find<UserInfoController>();
  final ImagePicker _picker = ImagePicker();
  final localService = LocalService();

  // ────────────────────────────────────────────────────────────────────────────
  // UI State
  final profileImage = Rxn<File>();
  final profileImageUrl = ''.obs;
  final RxBool isSaving = false.obs;
  final RxBool isPictureLoading = false.obs;

  // ────────────────────────────────────────────────────────────────────────────
  // Form Controllers
  final fullName = TextEditingController();
  final email = TextEditingController();
  final businessType = TextEditingController();
  final describeProfession = TextEditingController();
  final city = TextEditingController();
  final fullAddress = TextEditingController();
  final phoneNumber = TextEditingController();

  // Country code
  final RxString selectedCountryCode = '+44'.obs;
  final RxString selectedCountryFlag = '🇬🇧'.obs;

  // Always compute at request time (do NOT store as late field)
  String get fullPhoneNumber => '${selectedCountryCode.value}${phoneNumber.text.trim()}';

  // ────────────────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _ensureUserLoadedAndPrefill();
  }

  Future<void> _ensureUserLoadedAndPrefill() async {
    // If user data not loaded yet, fetch it
    if (userInfo.userData.value == null) {
      await userInfo.getUserInfo();
    }
    _prefillFromUserData();
  }

  void _prefillFromUserData() {
    final u = userInfo.userData.value;
    if (u == null) return;

    // Prefill form fields with existing values (prevents wiping)
    fullName.text = u.fullName ?? '';
    email.text = u.email ?? '';
    businessType.text = u.businessType ?? '';
    describeProfession.text = u.describe ?? '';
    city.text = u.city ?? '';
    fullAddress.text = u.address ?? '';

    // If backend stores full phone including country code, just set it.
    // If you store country separately, you can split it here.
    phoneNumber.text = u.phoneNumber ?? '';

    // If you have image URL in model
    profileImageUrl.value = (u.profile ?? '');
  }

  // ────────────────────────────────────────────────────────────────────────────
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
  String getFlagByCode(String code) {
    return countryList.firstWhere(
          (c) => c['code'] == code,
      orElse: () => {'icon': '🌍'},
    )['icon']!;
  }


  // ────────────────────────────────────────────────────────────────────────────
  /// Upload profile picture (PUT multipart)
  /// NOTE: do NOT manually set Content-Type for MultipartRequest.
  Future<bool> saveProfilePicture() async {
    if (profileImage.value == null) return true;

    isPictureLoading.value = true;
    try {
      // Your LocalService has a singleton; do NOT do LocalService()
      final token = localService.getToken() ?? '';
      if (token.isEmpty) {
        throw Exception("Authentication error: token missing");
      }

      final request = http.MultipartRequest('PUT', Uri.parse(Urls.userUploadPhoto));
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': token, // or 'Bearer $token' if backend uses Bearer
      });

      final bytes = await profileImage.value!.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file', // must match backend field name
          bytes,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final res = json.decode(response.body);
        if (res != null && res['success'] == true) {
          await userInfo.loadAndSetUserInfo();
          return true;
        }
        throw Exception(res?['message'] ?? 'Failed to upload profile picture');
      }

      throw Exception("Failed to upload image. Status: ${response.statusCode}");
    } finally {
      isPictureLoading.value = false;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  /// Update profile info (PUT JSON)
  /// IMPORTANT: backend wipes missing fields, so we SEND MERGED FULL PAYLOAD.
  Future<bool> saveProfileInfo() async {
    isSaving.value = true;
    try {
      // Ensure we have latest data
      if (userInfo.userData.value == null) {
        await userInfo.getUserInfo();
      }
      final u = userInfo.userData.value;
      if (u == null) throw Exception("User info not loaded");

      // Merge: if text is empty -> use existing value
      final mergedBody = <String, dynamic>{
        // editable fields
        "fullName": fullName.text.trim().isNotEmpty ? fullName.text.trim() : (u.fullName ?? ''),
        "phoneNumber": phoneNumber.text.trim().isNotEmpty ? fullPhoneNumber : (u.phoneNumber ?? ''),
        "describe": describeProfession.text.trim().isNotEmpty ? describeProfession.text.trim() : (u.describe ?? ''),
        "city": city.text.trim().isNotEmpty ? city.text.trim() : (u.city ?? ''),
        "address": fullAddress.text.trim().isNotEmpty ? fullAddress.text.trim() : (u.address ?? ''),

        // non-edited fields that MUST NOT be wiped (include everything your backend stores)
        "email": u.email ?? '',
        "businessType": u.businessType ?? '',
        "profile": u.profile ?? '',

        // If your model has more fields, add them here so backend won’t clear them:
        // "id": u.id ?? '',
        // "role": u.role ?? '',
        // "country": u.country ?? '',
        // ...
      };

      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.PUT,
        Urls.userUpdateProfile,
        jsonEncode(mergedBody),
        is_auth: true,
      );

      if (response != null && response['success'] == true) {
        await userInfo.loadAndSetUserInfo();
        return true;
      }
      throw Exception(response?['message'] ?? 'Info update failed');
    } finally {
      isSaving.value = false;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  /// Save both changes
  /// IMPORTANT: do NOT run both in Future.wait; last write can wipe fields.
  Future<void> saveAllProfileChanges() async {
    isSaving.value = true;
    try {
      await saveProfilePicture();
      await saveProfileInfo();

      Get.snackbar('Success', 'Profile updated successfully');
      Get.back();
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    fullName.dispose();
    email.dispose();
    businessType.dispose();
    describeProfession.dispose();
    city.dispose();
    fullAddress.dispose();
    phoneNumber.dispose();
    super.onClose();
  }
}
