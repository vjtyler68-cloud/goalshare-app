import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';

/// A generic in-app web view for org tools — the appointment scheduler (a
/// booking widget) and the territory map (an ArcGIS web map) both open here so
/// members never leave the app.
class OrgWebScreen extends StatefulWidget {
  final String url;
  final String title;

  /// Optional widget pinned below the web view (e.g. the territory-map metrics
  /// bar). The web page keeps most of the screen; the bar sits under it.
  final Widget? bottomBar;

  const OrgWebScreen({
    super.key,
    required this.url,
    this.title = 'GoalShare',
    this.bottomBar,
  });

  @override
  State<OrgWebScreen> createState() => _OrgWebScreenState();
}

class _OrgWebScreenState extends State<OrgWebScreen> {
  static const _kBg = Color(0xffF6F4F2);
  static const _kText = Color(0xff1A1010);

  late final WebViewController _controller;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (err) {
            // Only surface top-level failures, not sub-resource hiccups.
            if (err.isForMainFrame == true && mounted) {
              setState(() {
                _loading = false;
                _error = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _reload() {
    setState(() {
      _error = false;
      _loading = true;
    });
    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primaryColor;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back, color: _kText)),
        title: Text(widget.title,
            style: AppFonts.spaceGrotesk.copyWith(
                color: _kText, fontWeight: FontWeight.w800, fontSize: 16.sp)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded, color: _kText),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _error
                ? _errorView(accent)
                : Stack(
                    children: [
                      WebViewWidget(controller: _controller),
                      if (_loading)
                        Container(
                          color: Colors.white,
                          child: Center(
                            child: CircularProgressIndicator(color: accent),
                          ),
                        ),
                    ],
                  ),
          ),
          if (widget.bottomBar != null) widget.bottomBar!,
        ],
      ),
    );
  }

  Widget _errorView(Color accent) => Center(
        child: Padding(
          padding: EdgeInsets.all(28.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.public_off_rounded, size: 46.r, color: accent),
              SizedBox(height: 14.h),
              Text('Couldn\'t load this',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: _kText)),
              SizedBox(height: 6.h),
              Text('Check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 12.5.sp, color: const Color(0xff9E9090))),
              SizedBox(height: 18.h),
              GestureDetector(
                onTap: _reload,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 26.w, vertical: 12.h),
                  decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(30.r)),
                  child: Text('Retry',
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      );
}
