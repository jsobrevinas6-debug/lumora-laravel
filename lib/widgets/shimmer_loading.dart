import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A champagne silk shimmer loading widget delivering high-end editorial placeholder loading.
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isCircle;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
    this.isCircle = false,
  });

  const ShimmerLoading.circular({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = 999,
        isCircle = true;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _gradientPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _gradientPosition = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _gradientPosition,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius:
                widget.isCircle ? null : BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_gradientPosition.value - 1, 0),
              end: Alignment(_gradientPosition.value, 0),
              colors: const [
                Color(0xFFF6F0EC),
                Color(0xFFECE0D8),
                Color(0xFFFBF7F5),
                Color(0xFFF6F0EC),
              ],
              stops: const [0.0, 0.45, 0.55, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Ready-to-use luxury product card skeleton placeholder
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ShimmerLoading(width: double.infinity, height: 126, borderRadius: 0),
          Padding(
            padding: EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(width: 50, height: 8, borderRadius: 4),
                SizedBox(height: 6),
                ShimmerLoading(width: 120, height: 12, borderRadius: 4),
                SizedBox(height: 4),
                ShimmerLoading(width: 80, height: 12, borderRadius: 4),
                SizedBox(height: 8),
                ShimmerLoading(width: 65, height: 14, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
