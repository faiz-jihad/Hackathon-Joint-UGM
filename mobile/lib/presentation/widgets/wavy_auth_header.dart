import 'package:flutter/material.dart';

/// WavyAuthHeader — Header dengan kurva gelombang ombak laut yang mulus (smooth cubic ocean wave)
/// dan gradien biru-ungu elektrik dengan logo putih resmi RETIVA.
class WavyAuthHeader extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final double height;

  const WavyAuthHeader({
    super.key,
    this.title = 'RETIVA',
    this.showBackButton = false,
    this.onBackPressed,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: height + statusBarHeight,
      width: double.infinity,
      child: Stack(
        children: [
          // Background Layer Wave 2 (Aksen Transparan Ungu-Cyan)
          Positioned.fill(
            child: ClipPath(
              clipper: _WaveClipperSecondary(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF38BDF8), // Cyan ocean surf
                      Color(0xFF60A5FA), // Light blue ocean
                      Color(0xFF2563EB), // Vibrant blue
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Primary Layer Wave 1 (Gradien Utama Biru Samudra Elektrik)
          Positioned.fill(
            child: ClipPath(
              clipper: _WaveClipperPrimary(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1E3A8A), // Deep Ocean Navy
                      Color(0xFF1D4ED8), // Deep Blue
                      Color(0xFF2563EB), // Vibrant Blue
                      Color(0xFF3B82F6), // Sky Ocean Blue
                    ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Stack(
                    children: [
                      // Dekorasi lingkaran halus di background
                      Positioned(
                        top: -30,
                        right: -20,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 40,
                        left: -40,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),

                      // Konten Logo & Brand di Tengah
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Logo resmi web warna putih
                              _buildBrandLogo(),
                              const SizedBox(height: 10),
                              Text(
                                title,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 2.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Tombol Kembali (Opsional)
                      if (showBackButton)
                        Positioned(
                          top: 10,
                          left: 16,
                          child: InkWell(
                            onTap: onBackPressed ?? () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Logo Resmi RETIVA warna putih dari web
  Widget _buildBrandLogo() {
    return Image.asset(
      'assets/images/logo-white.png',
      width: 48,
      height: 48,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.remove_red_eye_rounded,
        color: Colors.white,
        size: 40,
      ),
    );
  }
}

/// Custom Clipper untuk Gelombang Ombak Belakang (Translucent Ocean Surf)
/// Memiliki kurva C2 mulus yang menelusuri gelombang utama secara proporsional
class _WaveClipperSecondary extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.83);

    // Ombak 1: Lembah laut kiri
    path.cubicTo(
      size.width * 0.18,
      size.height * 0.97,
      size.width * 0.42,
      size.height * 0.97,
      size.width * 0.58,
      size.height * 0.87,
    );

    // Ombak 2: Puncak laut kanan
    path.cubicTo(
      size.width * 0.74,
      size.height * 0.77,
      size.width * 0.88,
      size.height * 0.75,
      size.width,
      size.height * 0.85,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

/// Custom Clipper untuk Gelombang Ombak Utama Depan (Smooth Ocean Wave)
/// Menggunakan kurva C2 continuous yang mengalir mulus tanpa sudut kaku atau kerutan
class _WaveClipperPrimary extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.75);

    // Ombak 1: Lembah samudra anggun kiri-tengah
    path.cubicTo(
      size.width * 0.16,
      size.height * 0.90,
      size.width * 0.40,
      size.height * 0.90,
      size.width * 0.56,
      size.height * 0.80,
    );

    // Ombak 2: Mengalir naik ke puncak ombak kanan lalu landai lembut
    path.cubicTo(
      size.width * 0.72,
      size.height * 0.70,
      size.width * 0.86,
      size.height * 0.68,
      size.width,
      size.height * 0.78,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
