import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/const/app_fonts.dart';
import '../repository/giphy_service.dart';

/// Bottom-sheet GIF picker backed by GIPHY. Opens on Trending, searches live as
/// you type (debounced). Tapping a GIF closes the sheet and returns its URL via
/// Navigator.pop — the caller sends it as a message. Content is pg-13 filtered
/// in [GiphyService] for App Store safety.
class GifPickerSheet extends StatefulWidget {
  const GifPickerSheet({super.key});

  @override
  State<GifPickerSheet> createState() => _GifPickerSheetState();
}

class _GifPickerSheetState extends State<GifPickerSheet> {
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;
  List<GiphyGif> _gifs = const [];
  bool _loading = true;

  Color get _accent => AppColors.primaryColor;

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load(String q) async {
    setState(() => _loading = true);
    final results = q.trim().isEmpty
        ? await GiphyService.trending()
        : await GiphyService.search(q);
    if (!mounted) return;
    setState(() {
      _gifs = results;
      _loading = false;
    });
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _load(q));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xffF6F4F2),
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: TextField(
                    controller: _search,
                    onChanged: _onChanged,
                    textInputAction: TextInputAction.search,
                    style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp),
                    decoration: InputDecoration(
                      hintText: 'Search GIFs',
                      hintStyle: AppFonts.spaceGrotesk
                          .copyWith(fontSize: 14.sp, color: Colors.black38),
                      prefixIcon: Icon(Icons.search, color: _accent, size: 22.r),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? Center(child: CircularProgressIndicator(color: _accent))
                    : _gifs.isEmpty
                        ? Center(
                            child: Text(
                              'No GIFs found',
                              style: AppFonts.spaceGrotesk.copyWith(
                                  color: Colors.black45, fontSize: 14.sp),
                            ),
                          )
                        : MasonryGridView.count(
                            controller: scrollController,
                            padding:
                                EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 12.h),
                            crossAxisCount: 2,
                            mainAxisSpacing: 8.h,
                            crossAxisSpacing: 8.w,
                            itemCount: _gifs.length,
                            itemBuilder: (context, i) {
                              final g = _gifs[i];
                              return GestureDetector(
                                onTap: () =>
                                    Navigator.of(context).pop(g.fullUrl),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: CachedNetworkImage(
                                    imageUrl: g.previewUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      height: 110.h,
                                      color: const Color(0xffEDEAE8),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      height: 110.h,
                                      color: const Color(0xffEDEAE8),
                                      alignment: Alignment.center,
                                      child: Icon(Icons.broken_image_outlined,
                                          color: Colors.black26, size: 24.r),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              // GIPHY attribution — required by their API terms of service.
              Padding(
                padding: EdgeInsets.only(bottom: 10.h, top: 2.h),
                child: Text(
                  'Powered by GIPHY',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 10.sp,
                    letterSpacing: 0.5,
                    color: Colors.black38,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
