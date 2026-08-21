import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final double blurSigma;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 18.0,
    this.blurSigma = 10.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Colors.white.withValues(alpha: 0.85);
    final border = borderColor ?? AppTheme.primaryTeal.withValues(alpha: 0.15);

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    return content;
  }
}
