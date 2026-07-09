import 'package:flutter/material.dart';

/// Tappable 1–5 star rating with a satisfying scale bounce on tap.
/// Uses [Icons.star_rounded] to match the rest of the app.
class StarRating extends StatefulWidget {
  const StarRating({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 34,
    this.color = const Color(0xffF59E0B),
    this.readOnly = false,
    this.spacing = 6,
  });

  final int value; // 0..5 (0 = unset)
  final ValueChanged<int>? onChanged;
  final double size;
  final Color color;
  final bool readOnly;
  final double spacing;

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  int? _popped;

  void _tap(int index) {
    if (widget.readOnly || widget.onChanged == null) return;
    widget.onChanged!(index + 1);
    setState(() => _popped = index);
    Future.delayed(const Duration(milliseconds: 160), () {
      if (mounted) setState(() => _popped = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < widget.value;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _tap(i),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
            child: AnimatedScale(
              scale: _popped == i ? 1.35 : 1.0,
              duration: const Duration(milliseconds: 130),
              curve: Curves.easeOutBack,
              child: Icon(
                filled ? Icons.star_rounded : Icons.star_outline_rounded,
                color: filled ? widget.color : widget.color.withOpacity(0.35),
                size: widget.size,
              ),
            ),
          ),
        );
      }),
    );
  }
}
