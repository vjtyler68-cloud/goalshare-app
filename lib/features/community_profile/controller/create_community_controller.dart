import 'dart:io';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spanx/core/const/app_colors.dart';

class CreateCommunityController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  final communityImage = Rxn<File>();

  // select image from camera
  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      if (image != null) {
        communityImage.value = File(image.path);
      }
    } catch (e) {
      Get.snackbar(
        'Failed',
        'No image captured',
        backgroundColor: AppColors.redColor,
      );
    }
  }

  // select image from gallery
  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      if (image != null) {
        communityImage.value = File(image.path);
      }
    } catch (e) {
      Get.snackbar(
        'Failed',
        'No image captured',
        backgroundColor: AppColors.redColor,
      );
    }
  }

  void removeCommunityImage() {
    communityImage.value = null;
  }

  void saveButton(){

  }

  void skipButton(){

  }

}
