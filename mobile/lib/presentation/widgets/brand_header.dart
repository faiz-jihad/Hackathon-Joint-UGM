import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';

class BrandHeader extends StatefulWidget {
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
  State<BrandHeader> createState() => _BrandHeaderState();
}

class _BrandHeaderState extends State<BrandHeader> {
  void _openServerSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isDomain = ApiConstants.currentEnvironment == BackendEnvironment.onlineDomain;
            final isVpsIp = ApiConstants.currentEnvironment == BackendEnvironment.onlineVpsIp;
            final isLaptop = ApiConstants.currentEnvironment == BackendEnvironment.offlineLaptop;
            final isEmulator = ApiConstants.currentEnvironment == BackendEnvironment.offlineEmulator;

            return Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.cloud_sync_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Koneksi Server Faskes',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.figmaTextHeading,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Pilih endpoint backend aktif untuk pengujian',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.figmaTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Option 1: Official Subdomain HTTPS
                  _buildServerOption(
                    title: 'Domain Resmi HTTPS (Produksi)',
                    subtitle: 'https://hackathon.mataceria.my.id',
                    isSelected: isDomain,
                    isHealthy: true,
                    icon: Icons.verified_user_rounded,
                    activeColor: const Color(0xFF059669),
                    onTap: () {
                      setState(() {
                        ApiConstants.useDomain();
                      });
                      setModalState(() {});
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tersambung ke Domain Resmi: https://hackathon.mataceria.my.id'),
                          backgroundColor: Color(0xFF059669),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // Option 2: VPS Direct IP
                  _buildServerOption(
                    title: 'IP VPS Direct HTTP',
                    subtitle: 'http://43.173.35.200 (IP Langsung)',
                    isSelected: isVpsIp,
                    isHealthy: true,
                    icon: Icons.public,
                    activeColor: AppColors.figmaBlue,
                    onTap: () {
                      setState(() {
                        ApiConstants.useVpsIp();
                      });
                      setModalState(() {});
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tersambung ke IP VPS: http://43.173.35.200'),
                          backgroundColor: AppColors.figmaBlue,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // Option 3: Laptop Local Wi-Fi
                  _buildServerOption(
                    title: 'Server Laptop via Wi-Fi (Offline Lokal)',
                    subtitle: 'http://192.168.1.13:3000 (Test HP & Laptop Satu Wi-Fi)',
                    isSelected: isLaptop,
                    isHealthy: false,
                    icon: Icons.laptop_chromebook,
                    activeColor: const Color(0xFFD97706),
                    onTap: () {
                      setState(() {
                        ApiConstants.useLaptopWifi();
                      });
                      setModalState(() {});
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Beralih ke Server Laptop: 192.168.1.13:3000'),
                          backgroundColor: Color(0xFFD97706),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // Option 3: Emulator Localhost
                  _buildServerOption(
                    title: 'Android Emulator (Loopback)',
                    subtitle: 'http://10.0.2.2:3000 (Host Virtual Machine)',
                    isSelected: isEmulator,
                    isHealthy: false,
                    icon: Icons.phone_android,
                    activeColor: AppColors.figmaBlue,
                    onTap: () {
                      setState(() {
                        ApiConstants.useEmulator();
                      });
                      setModalState(() {});
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Beralih ke Emulator: 10.0.2.2:3000'),
                          backgroundColor: AppColors.figmaBlue,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildServerOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isHealthy,
    required IconData icon,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withOpacity(0.12) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: isSelected ? activeColor : AppColors.figmaTextMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: AppColors.figmaTextHeading,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.figmaTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: activeColor, size: 20)
            else
              const Icon(Icons.radio_button_unchecked, color: Color(0xFFCBD5E1), size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDomain = ApiConstants.currentEnvironment == BackendEnvironment.onlineDomain;
    final isVpsIp = ApiConstants.currentEnvironment == BackendEnvironment.onlineVpsIp;
    final isOnline = isDomain || isVpsIp;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
        boxShadow: const [
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
            if (widget.showBack)
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
                  onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
                ),
              ),

            // Logo with Medica Style Gradient Container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33246BFD),
                    offset: Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/retiva_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.remove_red_eye_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),

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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'FKTP / Faskes',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0369A1),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Poli Diabetes & Mata • Standar ICDR',
                    style: TextStyle(
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

            if (widget.trailing != null)
              widget.trailing!
            else
              // Interactive Server Status Pill (Tap to Switch)
              InkWell(
                onTap: () => _openServerSwitcher(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOnline ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                    border: Border.all(
                      color: isOnline ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          boxShadow: [
                            BoxShadow(
                              color: isOnline
                                  ? const Color(0xFF10B981).withOpacity(0.5)
                                  : const Color(0xFFF59E0B).withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isDomain
                            ? 'mataceria.my.id'
                            : (isVpsIp ? 'VPS Online' : 'Offline'),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isOnline ? const Color(0xFF065F46) : const Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 14,
                        color: isOnline ? const Color(0xFF065F46) : const Color(0xFF92400E),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
