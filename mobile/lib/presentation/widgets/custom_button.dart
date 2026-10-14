import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// CustomButton — Medica Style Capsule Button
/// Mengadopsi style tombol kapsul modern dari Medica UI Kit:
/// - Rounded pill (BorderRadius 28)
/// - Height 54px dengan touch target ergonomis
/// - Soft blue elevation shadow untuk primary button
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? height;
  final double? borderRadius;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? 54.0;
    final effectiveRadius = borderRadius ?? 28.0;
    final isPrimary = backgroundColor == null || backgroundColor == AppColors.primary;

    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        height: effectiveHeight,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: backgroundColor ?? AppColors.primary,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(effectiveRadius),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          child: _buildChild(textColor ?? AppColors.primary),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: effectiveHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(effectiveRadius),
        boxShadow: (onPressed != null && !isLoading && isPrimary)
            ? AppColors.primaryButtonShadow
            : null,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: textColor ?? Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(effectiveRadius),
          ),
        ),
        child: _buildChild(textColor ?? Colors.white),
      ),
    );
  }

  Widget _buildChild(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.2, color: color),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      );
    }
    return Text(
      label,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        fontFamily: 'Inter',
        color: color,
        letterSpacing: 0.2,
      ),
    );
  }
}
