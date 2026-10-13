import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class BrandHeader extends StatelessWidget {
  final VoidCallback? onBack;
  final bool showBack;
  final Widget? trailing;

  const BrandHeader({
    super.key,
    this.onBack,
    this.showBack = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (showBack)
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              ),
            if (showBack) const SizedBox(width: 12),

            // Retiva Logo Image from Figma (Node 25:95)
            Image.asset(
              'assets/images/retiva_logo.png',
              width: 40,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 38,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.figmaBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.visibility, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 10),

            // App Title & Tagline (Figma Nodes 25:11 & 25:13)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Retiva',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.figmaBlue,
                      letterSpacing: -0.4,
                      height: 1.25,
                    ),
                  ),
                  const Text(
                    'Ophthalmology AI Screening',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.figmaTextMuted,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),

            if (trailing != null)
              trailing!
            else
              // Figma Version Pill (Node 25:14)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.figmaBlueSurface,
                  border: Border.all(color: const Color(0x332196F3), width: 1),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: const Text(
                  'v1.0',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.figmaBlue,
                    height: 1.2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
