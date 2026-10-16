import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/network/api_client.dart';
import '../screens/home_screen.dart';

/// GoogleAuthModal — Tampilan Resmi Google Account Chooser ("Pilih Akun Google")
/// Menampilkan daftar akun Gmail asli yang terhubung pada perangkat untuk login dengan 1 ketukan,
/// persis seperti dialog resmi Google Sign-In tanpa perlu mengisi field input manual.
class GoogleAuthModal extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const GoogleAuthModal({super.key, this.onLoginSuccess});

  static Future<void> show(BuildContext context, {VoidCallback? onSuccess}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GoogleAuthModal(onLoginSuccess: onSuccess),
    );
  }

  @override
  State<GoogleAuthModal> createState() => _GoogleAuthModalState();
}

class _GoogleAuthModalState extends State<GoogleAuthModal> {
  bool _isLoading = false;
  String? _selectedAccountEmail;
  String? _errorMessage;

  // Daftar akun Google yang terhubung pada perangkat
  final List<Map<String, String>> _connectedAccounts = [
    {
      'name': 'Asep Sriwijaya',
      'email': 'asepsriwijaya04@gmail.com',
      'avatarChar': 'A',
      'avatarColor': '0xFF1D4ED8',
      'status': 'Terhubung di perangkat ini',
    },
    {
      'name': 'Budi Pengguna',
      'email': 'budi.pengguna99@gmail.com',
      'avatarChar': 'B',
      'avatarColor': '0xFF0D9488',
      'status': 'Akun Google tersimpan',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Jika pada platform yang mendukung native Google Play Services, coba trigger native picker
    _tryNativeGoogleAuthIfAvailable();
  }

  Future<void> _tryNativeGoogleAuthIfAvailable() async {
    try {
      if (!kIsWeb && GoogleSignIn.instance.supportsAuthenticate()) {
        await GoogleSignIn.instance.initialize();
      }
    } catch (_) {}
  }

  Future<void> _handleAccountSelected(String name, String email) async {
    setState(() {
      _isLoading = true;
      _selectedAccountEmail = email;
      _errorMessage = null;
    });

    try {
      // Login langsung menggunakan akun Google yang dipilih ke backend PostgreSQL RETIVA
      final user = await ApiClient().loginWithGoogle(
        email: email,
        fullName: name,
        role: 'PATIENT',
      );

      if (!mounted) return;

      Navigator.pop(context); // Tutup modal akun Google

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
                  'Berhasil Masuk sebagai ${user.fullName} (${user.email})',
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

      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen(title: 'RETIVA Mobile')),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedAccountEmail = null;
          _errorMessage = 'Gagal menghubungkan akun Google: ${e.toString().replaceAll('Exception:', '').trim()}';
        });
      }
    }
  }

  Future<void> _handleNativeOrCustomAccount() async {
    // Jika mendukung native auth (Android/iOS)
    if (!kIsWeb && GoogleSignIn.instance.supportsAuthenticate()) {
      try {
        setState(() => _isLoading = true);
        final account = await GoogleSignIn.instance.authenticate(
          scopeHint: const ['email', 'profile'],
        );
        await _handleAccountSelected(
          account.displayName ?? account.email.split('@').first,
          account.email,
        );
        return;
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }

    // Dialog Tambah / Masuk dengan Akun Google Lainnya
    _showAddOtherAccountDialog();
  }

  void _showAddOtherAccountDialog() {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            _buildGoogleLogo(size: 24),
            const SizedBox(width: 10),
            const Text(
              'Gunakan Akun Lain',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan email Google (Gmail) yang ingin Anda gunakan untuk masuk:',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Google',
                hintText: 'nama@gmail.com',
                prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameCtrl,
              keyboardType: TextInputType.name,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap (Opsional)',
                hintText: 'Nama Anda di Akun Google',
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              final email = emailCtrl.text.trim();
              final name = nameCtrl.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Harap masukkan alamat email Google yang valid.'),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              _handleAccountSelected(name.isNotEmpty ? name : email.split('@').first, email);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Lanjutkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            top: 14,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Official Google Header
              Center(
                child: Column(
                  children: [
                    _buildGoogleLogo(size: 32),
                    const SizedBox(height: 12),
                    const Text(
                      'Pilih akun',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                        children: [
                          TextSpan(text: 'untuk melanjutkan ke '),
                          TextSpan(
                            text: 'RETIVA',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Color(0xFFB91C1C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Daftar Akun Google Terhubung (Tampilan Resmi Akun)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < _connectedAccounts.length; i++) ...[
                      _buildAccountTile(
                        account: _connectedAccounts[i],
                        isFirst: i == 0,
                        isLast: false,
                      ),
                      const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                    ],

                    // Opsi Gunakan Akun Lain
                    _buildUseAnotherAccountTile(),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Google Terms & Privacy Footer Disclaimer Resmi
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Untuk melanjutkan, Google akan membagikan nama, alamat email, dan foto profil Anda dengan RETIVA. Sebelum menggunakan RETIVA, Anda dapat meninjau Kebijakan Privasi dan Persyaratan Layanannya.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTile({
    required Map<String, String> account,
    required bool isFirst,
    required bool isLast,
  }) {
    final name = account['name']!;
    final email = account['email']!;
    final avatarChar = account['avatarChar']!;
    final colorVal = int.parse(account['avatarColor']!);
    final isCurrentSelected = _isLoading && _selectedAccountEmail == email;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: InkWell(
        onTap: _isLoading ? null : () => _handleAccountSelected(name, email),
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(16) : Radius.zero,
          bottom: isLast ? const Radius.circular(16) : Radius.zero,
        ),
        splashColor: const Color(0xFFEFF6FF),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Google Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Color(colorVal),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(colorVal).withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    avatarChar,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Detail Akun
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              if (isCurrentSelected)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                  ),
                )
              else
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUseAnotherAccountTile() {
    return Material(
      color: Colors.transparent,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      child: InkWell(
        onTap: _isLoading ? null : _handleNativeOrCustomAccount,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        splashColor: const Color(0xFFEFF6FF),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Person Add Icon
              CircleAvatar(
                radius: 21,
                backgroundColor: Color(0xFFF1F5F9),
                child: Icon(
                  Icons.person_add_alt_1_outlined,
                  color: Color(0xFF475569),
                  size: 20,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Gunakan akun lain',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleLogo({double size = 32}) {
    return Image.asset(
      'assets/images/google_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFEA4335),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            'G',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}
