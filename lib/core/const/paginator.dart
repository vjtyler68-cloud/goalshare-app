// lib/core/paging/paged_controller.dart
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class PageResult<T> {
  final List<T> items;
  final int totalPage;
  PageResult({required this.items, required this.totalPage});
}

/// Mixin you can reuse in any GetX controller.
/// Implement `loadPage` to call your API and map it to PageResult<T>.
mixin PagedController<T> on GetxController {
  // public data
  final RxList<T> data = <T>[].obs;

  // paging flags
  final RxBool isInitialLoading = false.obs;
  final RxBool isFetchingMore = false.obs;
  final RxBool hasMore = true.obs;

  // state
  int page = 1;
  int limit = 10;        // change per screen if needed
  int totalPage = 1;

  // scroll
  final ScrollController scrollCtrl = ScrollController();

  @override
  void onReady() {
    super.onReady();
    scrollCtrl.addListener(_onScroll);
  }

  @override
  void onClose() {
    scrollCtrl.removeListener(_onScroll);
    scrollCtrl.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (!hasMore.value || isFetchingMore.value || isInitialLoading.value) return;
    final threshold = 200.0;
    if (scrollCtrl.position.pixels >= scrollCtrl.position.maxScrollExtent - threshold) {
      fetchNextPage();
    }
  }

  /// Call this from your controller's onInit()
  Future<void> fetchFirstPage() async {
    page = 1;
    hasMore.value = true;
    isInitialLoading.value = true;
    try {
      final res = await loadPage(page, limit);
      data.assignAll(res.items);
      totalPage = res.totalPage;
      hasMore.value = page < totalPage;
    } finally {
      isInitialLoading.value = false;
    }
  }

  Future<void> fetchNextPage() async {
    if (!hasMore.value) return;
    isFetchingMore.value = true;
    try {
      final next = page + 1;
      final res = await loadPage(next, limit);
      data.addAll(res.items);
      page = next;
      totalPage = res.totalPage;
      hasMore.value = page < totalPage;
    } finally {
      isFetchingMore.value = false;
    }
  }

  Future<void> refreshPaged() async {
    await fetchFirstPage();
  }

  /// You MUST implement this in your concrete controller.
  Future<PageResult<T>> loadPage(int page, int limit);
}
