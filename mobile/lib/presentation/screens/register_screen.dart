import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../widgets/wavy_auth_header.dart';
import 'login_screen.dart';
import 'home_screen.dart';

/// RegisterScreen — Layar Pendaftaran Akun Pengguna
/// Menampilkan form registrasi dengan nama lengkap, email, nomor telepon, dan kata sandi,
/// langsung membuatkan akun Pengguna ketika disubmit tanpa perlu verifikasi OTP.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap menyetujui syarat & ketentuan layanan RETIVA.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await ApiClient().register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF059669),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Akun berhasil dibuat! Selamat datang, ${user.fullName}!',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
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
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg.isNotEmpty ? msg : 'Gagal mendaftarkan akun. Silakan coba kembali.'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Wavy Header dengan Logo & Tombol Kembali
            WavyAuthHeader(
              title: 'RETIVA',
              showBackButton: Navigator.canPop(context),
              onBackPressed: () => Navigator.pop(context),
              height: 220,
            ),

            // Form Register
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Daftar akun Pengguna untuk mengakses hasil skrining retina mandiri, jadwal kontrol, dan rekomendasi perawatan.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Input 1: Nama Lengkap
                    _buildLabel('Nama Lengkap'),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: _buildInputDecoration(
                        hint: 'Contoh: Budi Santoso',
                        prefixIcon: Icons.person_outline_rounded,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                    ),

                    const SizedBox(height: 14),

                    // Input 2: Email
                    _buildLabel('Alamat Email'),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: _buildInputDecoration(
                        hint: 'nama@email.com',
                        prefixIcon: Icons.email_outlined,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                        if (!v.contains('@')) return 'Format email tidak valid';
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    // Input 3: Nomor Telepon / WA
                    _buildLabel('Nomor WhatsApp / Handphone'),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: _buildInputDecoration(
                        hint: '+62 812-4567-890',
                        prefixIcon: Icons.phone_android_rounded,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nomor HP wajib diisi' : null,
                    ),

                    const SizedBox(height: 14),

                    // Input 4: Password
                    _buildLabel('Kata Sandi'),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: _buildInputDecoration(
                        hint: 'Minimal 8 karakter',
                        prefixIcon: Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 20,
                            color: const Color(0xFF64748B),
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 6) return 'Kata sandi minimal 6 karakter';
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    // Input 5: Konfirmasi Password
                    _buildLabel('Konfirmasi Kata Sandi'),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: _buildInputDecoration(
                        hint: 'Ulangi kata sandi',
                        prefixIcon: Icons.lock_reset_rounded,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 20,
                            color: const Color(0xFF64748B),
                          ),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                      validator: (v) {
                        if (v != _passwordController.text) return 'Konfirmasi kata sandi tidak cocok';
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    // Syarat & Ketentuan Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agreeTerms,
                            activeColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                            onChanged: (val) => setState(() => _agreeTerms = val ?? true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Saya menyetujui Ketentuan Layanan Pengguna dan Kebijakan Privasi Pemeriksaan RETIVA.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Tombol Register (Pill Gradien)
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF2563EB)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                              )
                            : const Text(
                                'Daftar Akun',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Already have an account? Sign In
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF64748B), size: 20),
      suffixIcon: suffixIcon,
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
    );
  }
}
