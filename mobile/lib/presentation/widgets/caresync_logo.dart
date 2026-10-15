import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// CareSync Logo — Heart with stethoscope motif
/// Sesuai UI Kit CareSync Healthcare
class CareSyncLogo extends StatelessWidget {
  final double size;
  final Color color;
  final bool showText;
  final String text;
  final String? subtitle;

  const CareSyncLogo({
    super.key,
    this.size = 32,
    this.color = AppColors.primary,
    this.showText = true,
    this.text = 'CareSync',
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(size * 0.32),
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.favorite_rounded,
                  color: color,
                  size: size * 0.65,
                ),
                Positioned(
                  bottom: size * 0.15,
                  child: Container(
                    width: size * 0.22,
                    height: size * 0.22,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: size * 0.1,
                        height: size * 0.1,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: size * 0.52,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'RETIVA',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 1),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: size * 0.28,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                    height: 1.1,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
