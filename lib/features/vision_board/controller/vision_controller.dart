import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spanx/routes/app_routes.dart';

import '../model/vision_model.dart';

class VisionBoardController extends GetxController {
  // Observable list of vision board items
  final RxList<VisionBoardItem> visionBoardItems = <VisionBoardItem>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadVisionBoardItems();
  }

  void loadVisionBoardItems() {
    isLoading.value = true;

    // Mock data with different aspect ratios for staggered layout
    final List<VisionBoardItem> items = [
      VisionBoardItem(
        id: '1',
        imageUrl:
            'https://images.unsplash.com/photo-1503376780353-7e6692767b70?fm=jpg&q=60&w=500',
        title: 'Dream Car',
        aspectRatio: 0.75, // Portrait
      ),
      VisionBoardItem(
        id: '2',
        imageUrl:
            'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?fm=jpg&q=60&w=500',
        title: 'Ocean View',
        aspectRatio: 1.0, // Square
      ),
      VisionBoardItem(
        id: '3',
        imageUrl:
            'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?fm=jpg&q=60&w=500',
        title: 'Mountain Adventure',
        aspectRatio: 1.3, // Landscape
      ),
      VisionBoardItem(
        id: '4',
        imageUrl:
            'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?fm=jpg&q=60&w=500',
        title: 'Sunset Dreams',
        aspectRatio: 1.5, // Wide landscape
      ),
      VisionBoardItem(
        id: '5',
        imageUrl:
            'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?fm=jpg&q=60&w=500',
        title: 'Modern Architecture',
        aspectRatio: 0.8, // Portrait
      ),
      VisionBoardItem(
        id: '6',
        imageUrl:
            'https://images.unsplash.com/photo-1544717297-fa95b6ee9643?fm=jpg&q=60&w=500',
        title: 'Happy Relationships',
        aspectRatio: 1.0, // Square
      ),
      VisionBoardItem(
        id: '7',
        imageUrl:
            'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?fm=jpg&q=60&w=500',
        title: 'Nature Escape',
        aspectRatio: 0.9, // Almost square
      ),
      VisionBoardItem(
        id: '8',
        imageUrl:
            'https://images.unsplash.com/photo-1518837695005-2083093ee35b?fm=jpg&q=60&w=500',
        title: 'Success Path',
        aspectRatio: 1.2, // Landscape
      ),
    ];

    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 500), () {
      visionBoardItems.assignAll(items);
      isLoading.value = false;
    });
  }

  void onCreateNewTap() {
    // Get.snackbar('Action', 'Create New Vision Board Item');
    Get.toNamed(AppRoutes.visionPageCreateScreen);
  }

  void onVisionItemTap(VisionBoardItem item) {
    Get.snackbar('Item Selected', item.title);
    // Add navigation or detail view logic here
  }

  void addNewVisionItem(VisionBoardItem item) {
    visionBoardItems.add(item);
  }

  void removeVisionItem(String id) {
    visionBoardItems.removeWhere((item) => item.id == id);
  }

  void updateVisionItem(VisionBoardItem updatedItem) {
    final index = visionBoardItems.indexWhere(
      (item) => item.id == updatedItem.id,
    );
    if (index != -1) {
      visionBoardItems[index] = updatedItem;
    }
  }

  void refreshVisionBoard() {
    loadVisionBoardItems();
  }
}
