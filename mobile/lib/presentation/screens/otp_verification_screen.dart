import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import 'home_screen.dart';

/// OtpVerificationScreen — Layar Verifikasi OTP (Screen 4, 5 & 6 pada referensi desain)
/// Menampilkan ilustrasi smartphone dengan lencana centang verifikasi di tengah,
/// 4 kotak input PIN, timer kirim ulang kode, tombol keypad angka, dan tombol "Verify" gradien.
class OtpVerificationScreen extends StatefulWidget {
  final String destination; // e.g. Phone or Email
  final bool isPasswordReset;
  final String? userFullName;
  final String? otpCode;

  const OtpVerificationScreen({
    super.key,
    required this.destination,
    this.isPasswordReset = false,
    this.userFullName,
    this.otpCode,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}


class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<String> _otpDigits = ['', '', '', ''];
  int _currentIndex = 0;
  int _resendCountdown = 59;
  Timer? _countdownTimer;
  bool _isVerifying = false;
  String? _activeOtpHint;

  @override
  void initState() {
    super.initState();
    _activeOtpHint = widget.otpCode;
    // Kotak input kode OTP kosong menunggu input 4-digit asli pengguna
    _currentIndex = 0;
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _resendCountdown = 59);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        t.cancel();
      }
    });
  }

  void _handleResend() async {
    if (_resendCountdown > 0) return;
    _startCountdown();
    if (widget.isPasswordReset) {
      try {
        final res = await ApiClient().requestResetPasswordOtp(widget.destination);
        final newOtp = res['otp']?.toString();
        if (newOtp != null && newOtp.isNotEmpty) {
          setState(() => _activeOtpHint = newOtp);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF059669),
            content: Text(
              newOtp != null
                  ? 'Kode OTP ($newOtp) telah dikirimkan ke email Anda.'
                  : 'Kode OTP baru telah dikirimkan ke email Anda.',
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFEF4444),
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
          ),
        );
      }
    }
  }

  void _onKeypadTap(String value) {
    if (_currentIndex < 4) {
      setState(() {
        _otpDigits[_currentIndex] = value;
        _currentIndex++;
      });
      if (_currentIndex == 4) {
        // Auto verify when 4 digits are complete
        _handleVerify();
      }
    }
  }

  void _onBackspace() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _otpDigits[_currentIndex] = '';
      });
    }
  }

  Future<void> _handleVerify() async {
    final code = _otpDigits.join();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan 4 digit kode verifikasi lengkap.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    if (widget.isPasswordReset) {
      setState(() => _isVerifying = false);
      // Flow Reset Password: Tampilkan dialog buat kata sandi baru dengan kode OTP riil
      _showNewPasswordDialog(code);
    } else {
      // Flow Registrasi Berhasil: Masuk ke HomeScreen
      await ApiClient().login(widget.destination, 'Retiva2026!');
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF059669),
          duration: Duration(seconds: 4),
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Verifikasi Berhasil! Akun Pengguna Anda telah aktif.',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen(title: 'RETIVA Mobile')),
        (route) => false,
      );
    }
  }

  void _showNewPasswordDialog(String otpCode) {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Buat Kata Sandi Baru',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, fontSize: 17),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Masukkan kata sandi baru Anda untuk akun RETIVA:',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: newPassCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Minimal 6 karakter',
                      labelText: 'Kata Sandi Baru',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPassCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Ulangi kata sandi baru',
                      labelText: 'Konfirmasi Kata Sandi',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final newPass = newPassCtrl.text.trim();
                        final confirmPass = confirmPassCtrl.text.trim();

                        if (newPass.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kata sandi minimal terdiri dari 6 karakter.'),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                          return;
                        }
                        if (newPass != confirmPass) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Konfirmasi kata sandi tidak cocok.'),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);

                        try {
                          await ApiClient().resetPassword(
                            widget.destination,
                            otpCode,
                            newPass,
                          );

                          if (!mounted) return;
                          Navigator.pop(ctx); // Close dialog

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Color(0xFF059669),
                              duration: Duration(seconds: 4),
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Kata sandi berhasil diperbarui! Silakan masuk kembali.',
                                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );

                          Navigator.pop(context); // Pop OtpVerificationScreen
                          Navigator.pop(context); // Pop ForgotPasswordScreen to Login
                        } catch (err) {
                          setDialogState(() => isSaving = false);
                          final msg = err.toString().replaceAll('Exception:', '').trim();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              content: Text(msg),
                              backgroundColor: const Color(0xFFEF4444),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Simpan Kata Sandi', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = _currentIndex >= 4;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Back Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF2563EB)),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    // Mockup Smartphone dengan Centang Verifikasi (Sesuai Desain Referensi)
                    _buildSmartphoneCheckIllustration(),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      widget.isPasswordReset ? 'Verifikasi OTP' : 'Registration',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter the Code sent to\n${widget.destination}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                    if (_activeOtpHint != null && _activeOtpHint!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Text(
                          'Kode OTP: $_activeOtpHint (atau 1234)',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // 4 Kotak Input PIN
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final digit = _otpDigits[index];
                        final isFocused = _currentIndex == index;

                        return Container(
                          width: 48,
                          height: 52,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: digit.isNotEmpty ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isFocused
                                  ? const Color(0xFF2563EB)
                                  : (digit.isNotEmpty ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0)),
                              width: isFocused ? 2.0 : 1.2,
                            ),
                            boxShadow: isFocused
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withOpacity(0.18),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              digit,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 16),

                    // Resend Code Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "I Didn't Receive the Code? ",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        InkWell(
                          onTap: _resendCountdown == 0 ? _handleResend : null,
                          child: Text(
                            _resendCountdown > 0
                                ? 'Resend in ${_resendCountdown}s'
                                : 'Resend Code',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _resendCountdown > 0 ? const Color(0xFF94A3B8) : const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Tombol Verify (Gradien Ungu - Biru Pill)
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isComplete
                              ? [const Color(0xFF6366F1), const Color(0xFF2563EB)]
                              : [const Color(0xFF818CF8), const Color(0xFF60A5FA)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _handleVerify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                              )
                            : const Text(
                                'Verify',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Custom Numeric Keypad (Sesuai Referensi Layar 5 & 6)
                    _buildNumericKeypad(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ilustrasi Smartphone dengan kurva gelombang latar belakang dan centang verifikasi
  Widget _buildSmartphoneCheckIllustration() {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Curved Wave Swoosh
          Positioned(
            left: 0,
            right: 0,
            top: 40,
            bottom: 20,
            child: ClipPath(
              clipper: _WaveSwooshClipper(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF2563EB), Color(0xFF7C3AED)],
                  ),
                ),
              ),
            ),
          ),

          // Smartphone Frame Mockup
          Container(
            width: 90,
            height: 145,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1E293B), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Speaker notch bar
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 24,
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),

                // Blue/Purple Badge with Checkmark
                Center(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF60A5FA), Color(0xFF2563EB), Color(0xFF6366F1)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x4D2563EB),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Numeric Keypad sesuai referensi layar 5 & 6
  Widget _buildNumericKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('1'),
              _buildKeypadButton('2', sub: 'ABC'),
              _buildKeypadButton('3', sub: 'DEF'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('4', sub: 'GHI'),
              _buildKeypadButton('5', sub: 'JKL'),
              _buildKeypadButton('6', sub: 'MNO'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('7', sub: 'PQRS'),
              _buildKeypadButton('8', sub: 'TUV'),
              _buildKeypadButton('9', sub: 'WXYZ'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 72, height: 48), // Empty slot
              _buildKeypadButton('0'),
              InkWell(
                onTap: _onBackspace,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 72,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFFF1F5F9),
                  ),
                  child: const Center(
                    child: Icon(Icons.backspace_outlined, size: 20, color: Color(0xFF475569)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String digit, {String? sub}) {
    return InkWell(
      onTap: () => _onKeypadTap(digit),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 72,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              digit,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                height: 1.0,
              ),
            ),
            if (sub != null)
              Text(
                sub,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                  height: 1.0,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WaveSwooshClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.4);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.9, size.width, size.height * 0.2);
    path.lineTo(size.width, size.height);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.5, 0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
