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
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.18),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.28),
            child: Image.asset(
              'assets/images/retiva_app_badge.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(size * 0.28),
                ),
                child: Center(
                  child: Icon(Icons.remove_red_eye_rounded, color: color, size: size * 0.65),
                ),
              ),
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
