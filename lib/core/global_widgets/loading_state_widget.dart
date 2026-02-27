import 'package:flutter/material.dart';
import 'package:spanx/core/const/app_colors.dart';

/// Standardized loading state widget
class LoadingStateWidget extends StatelessWidget {
  final String? message;
  final Color? color;

  const LoadingStateWidget({
    super.key,
    this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: color ?? AppColors.primaryColor,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: AppColors.greyColor70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
