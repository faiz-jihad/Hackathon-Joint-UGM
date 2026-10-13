import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class QualityIndicatorTile extends StatelessWidget {
  final String title;
  final String standardText;
  final double score;
  final double threshold;
  final bool isPassed;

  const QualityIndicatorTile({
    super.key,
    required this.title,
    required this.standardText,
    required this.score,
    required this.threshold,
    required this.isPassed,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isPassed ? AppColors.statusGreen : AppColors.statusRed;
    final statusBg = isPassed ? AppColors.statusGreenSurface : AppColors.statusRedSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPassed ? Icons.check_circle_outline : Icons.cancel_outlined,
                  size: 18,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      standardText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(score * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score.clamp(0.0, 1.0),
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
