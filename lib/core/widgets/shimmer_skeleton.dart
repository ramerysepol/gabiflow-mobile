import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/design_tokens.dart';

/// Utilitário de shimmer loading com variantes de card, círculo e linha.
abstract final class ShimmerSkeleton {
  static Widget card({double height = 120}) => _ShimmerCard(height: height);
  static Widget circle({double size = 48}) => _ShimmerCircle(size: size);
  static Widget line({double? width, double height = 14}) =>
      _ShimmerLine(width: width, height: height);
}

class _ShimmerBase extends StatelessWidget {
  const _ShimmerBase({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.neutral200Dark : AppColors.neutral200Light,
      highlightColor:
          isDark ? AppColors.neutral300Dark : AppColors.neutral100Light,
      child: child,
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return _ShimmerBase(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
    );
  }
}

class _ShimmerCircle extends StatelessWidget {
  const _ShimmerCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return _ShimmerBase(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ShimmerLine extends StatelessWidget {
  const _ShimmerLine({this.width, required this.height});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _ShimmerBase(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
      ),
    );
  }
}
