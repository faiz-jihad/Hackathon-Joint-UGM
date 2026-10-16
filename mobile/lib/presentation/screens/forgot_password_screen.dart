import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../widgets/wavy_auth_header.dart';
import 'otp_verification_screen.dart';

/// ForgotPasswordScreen — Layar Lupa Sandi
/// Mengirimkan 4-digit kode OTP langsung ke email terdaftar pengguna melalui SMTP,
/// dengan gaya visual konsisten Wavy Header gradien RETIVA.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contactController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _contactController.text.trim();
    setState(() => _isLoading = true);
    try {
      final otpRes = await ApiClient().requestResetPasswordOtp(email);
      final receivedOtp = otpRes['otp']?.toString();
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF059669),
          content: Row(
            children: [
              const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  receivedOtp != null
                      ? 'Kode OTP ($receivedOtp) telah dikirim ke $email. Silakan periksa inbox / spam.'
                      : 'Kode OTP 4-digit telah dikirim ke $email. Silakan periksa inbox / spam email Anda.',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 6),
        ),
      );

      // Navigasi ke Layar OTP dengan flag isPasswordReset = true & otpCode
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            destination: email,
            isPasswordReset: true,
            otpCode: receivedOtp,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      final errorMsg = e.toString().replaceAll('Exception:', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFDC2626),
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  errorMsg,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Wavy Header
            WavyAuthHeader(
              title: 'RETIVA',
              showBackButton: Navigator.canPop(context),
              onBackPressed: () => Navigator.pop(context),
              height: 230,
            ),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Forgot password ?',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Masukkan email terdaftar untuk menerima 4-digit kode pemulihan akun Anda.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Input Field (Hanya Alamat Email)
                    const Text(
                      'Alamat Email Terdaftar',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _contactController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'nama@email.com',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        prefixIcon: const Icon(
                          Icons.alternate_email_rounded,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.6),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!val.contains('@') || !val.contains('.')) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    // Tombol Kirim Kode OTP (Gradient Pill)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF2563EB)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Send Code',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Link Kembali ke Login
                    Center(
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                              children: [
                                TextSpan(text: 'Remember your password? '),
                                TextSpan(
                                  text: 'Login',
                                  style: TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w700,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
