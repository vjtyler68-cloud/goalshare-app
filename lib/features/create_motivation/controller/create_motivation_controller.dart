import 'dart:io';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';


class CreateMotivationController extends GetxController{
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
}