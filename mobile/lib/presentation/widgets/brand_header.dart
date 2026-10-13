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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
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

            // Retiva Logo Icon (Eye / Retina Aperture symbol)
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.visibility,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // App Title & Tagline
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Retiva',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          border: Border.all(color: AppColors.primaryLight.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'v1.0',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'CDSS Skrining Retinopati Diabetik',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
