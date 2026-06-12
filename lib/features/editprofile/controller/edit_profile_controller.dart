// edit_profile_controller.dart
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

  // UI State
  final profileImage = Rxn<File>();
  final profileImageUrl = ''.obs;

  final RxBool isSaving = false.obs;
  final RxBool isPictureLoading = false.obs;

  // Form Controllers
  final fullName = TextEditingController();
  final businessType = TextEditingController();
  final describeProfession = TextEditingController();
  final city = TextEditingController();
  final fullAddress = TextEditingController();
  final phoneNumber = TextEditingController();

  // Country code
  final RxString selectedCountryCode = '+44'.obs;
  final RxString selectedCountryFlag = '🇬🇧'.obs;

  // E.164 formatted (example: +447700900123)
  String get fullPhoneNumber {
    final local = phoneNumber.text.replaceAll(RegExp(r'\s+'), '').trim();
    if (local.isEmpty) return selectedCountryCode.value; // safe fallback
    return '${selectedCountryCode.value}$local';
  }

  @override
  void onInit() {
    super.onInit();
    _ensureUserLoadedAndPrefill();
  }

  Future<void> _ensureUserLoadedAndPrefill() async {
    if (userInfo.userData.value == null) {
      await userInfo.getUserInfo();
    }
    _prefillFromUserData();
  }

  void _prefillFromUserData() {
    final u = userInfo.userData.value;
    if (u == null) return;

    fullName.text = (u.fullName ?? '').trim();
    businessType.text = (u.businessType ?? '').trim();
    describeProfession.text = (u.describe ?? '').trim();
    city.text = (u.city ?? '').trim();
    fullAddress.text = (u.address ?? '').trim();

    profileImageUrl.value = (u.profile ?? '').trim();

    // Phone: try to split country code + local number if it looks like +<code><number>
    final raw = (u.phoneNumber ?? '').trim();
    _applyPhoneToFields(raw);
  }

  void _applyPhoneToFields(String raw) {
    if (raw.isEmpty) {
      // keep default +44 and empty phone
      phoneNumber.text = '';
      return;
    }

    // Normalize
    final normalized = raw.replaceAll(RegExp(r'\s+'), '');

    // If it doesn't start with +, keep it as local
    if (!normalized.startsWith('+')) {
      phoneNumber.text = normalized;
      return;
    }

    // Find best (longest) matching country code from your list
    final codes = countryList
        .map((c) => c['code'] ?? '')
        .where((c) => c.startsWith('+'))
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length)); // longest first

    String? matched;
    for (final code in codes) {
      if (normalized.startsWith(code)) {
        matched = code;
        break;
      }
    }

    if (matched != null) {
      selectedCountryCode.value = matched;
      selectedCountryFlag.value = getFlagByCode(matched);
      phoneNumber.text = normalized.substring(matched.length);
    } else {
      // fallback: keep default code and put full string into local
      phoneNumber.text = normalized;
    }
  }

  String getFlagByCode(String code) {
    return countryList.firstWhere(
          (c) => c['code'] == code,
      orElse: () => {'icon': '🌍'},
    )['icon'] ??
        '🌍';
  }

  // Image selection
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

  /// Upload profile picture (PUT multipart)
  Future<bool> saveProfilePicture() async {
    if (profileImage.value == null) return true;

    isPictureLoading.value = true;
    try {
      final token = await localService.getToken() ?? '';
      if (token.isEmpty) {
        throw Exception('Authentication error: token missing');
      }

      final request =
          http.MultipartRequest('PUT', Uri.parse(Urls.userUploadPhoto));
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      final bytes = await profileImage.value!.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
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

  /// Update profile info (PUT JSON) — send merged full payload so backend won’t wipe fields
  Future<bool> saveProfileInfo() async {
    try {
      if (userInfo.userData.value == null) {
        await userInfo.getUserInfo();
      }
      final u = userInfo.userData.value;
      if (u == null) throw Exception("User info not loaded");

      final mergedBody = <String, dynamic>{
        "fullName": fullName.text.trim().isNotEmpty
            ? fullName.text.trim()
            : (u.fullName ?? ''),
        "phoneNumber": phoneNumber.text.trim().isNotEmpty
            ? fullPhoneNumber
            : (u.phoneNumber ?? ''),
        "describe": describeProfession.text.trim().isNotEmpty
            ? describeProfession.text.trim()
            : (u.describe ?? ''),
        "city": city.text.trim().isNotEmpty ? city.text.trim() : (u.city ?? ''),
        "address": fullAddress.text.trim().isNotEmpty
            ? fullAddress.text.trim()
            : (u.address ?? ''),

        // keep these so backend doesn't clear them
        "email": u.email ?? '',
        "businessType": businessType.text.trim().isNotEmpty
            ? businessType.text.trim()
            : (u.businessType ?? ''),
        "profile": u.profile ?? '',
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
    } catch (e) {
      rethrow;
    }
  }

  /// Save both changes (sequential)
  Future<void> saveAllProfileChanges() async {
    if (isSaving.value) return;

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
    businessType.dispose();
    describeProfession.dispose();
    city.dispose();
    fullAddress.dispose();
    phoneNumber.dispose();
    super.onClose();
  }
}
