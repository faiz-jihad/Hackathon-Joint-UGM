import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'notification_bell_widget.dart';

class BrandHeader extends StatelessWidget {
  final VoidCallback? onBack;
  final bool showBack;
  final Widget? trailing;
  final String? badgeText;
  final String? subtitle;

  const BrandHeader({
    super.key,
    this.onBack,
    this.showBack = false,
    this.trailing,
    this.badgeText,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x050F172A),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (showBack)
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textPrimary),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                ),
              ),

            // Official Retiva App Icon Badge
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2E246BFD),
                    offset: Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/retiva_app_badge.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.primary,
                    child: const Center(
                      child: Icon(Icons.remove_red_eye_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // App & Faskes Context Titles
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'RETIVA',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.figmaBlue,
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText ?? 'Portal Pasien',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0369A1),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle ?? 'Pendamping Diabetes & Mata • Standar PERDAMI',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.figmaTextMuted,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            if (trailing != null)
              trailing!
            else
              const NotificationBellWidget(),
          ],
        ),
      ),
    );
  }
}
