import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/models/patient_model.dart';
import 'patient_history_screen.dart';
import 'daily_care_agenda_screen.dart';
import 'referral_letter_screen.dart';
import 'smart_meal_detail_screen.dart';
import 'auth_welcome_screen.dart';
import '../widgets/notification_bell_widget.dart';

class ProfileScreen extends StatefulWidget {
  final PatientModel? patient;
  const ProfileScreen({super.key, this.patient});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _patientName = '';
  String _patientNik = '';
  String _patientEmail = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('user_name');
    final savedEmail = prefs.getString('user_email');
    final savedNik = prefs.getString('user_nik');

    final name = (widget.patient?.fullName.isNotEmpty == true)
        ? widget.patient!.fullName
        : ((savedName != null && savedName.isNotEmpty)
            ? savedName
            : (ApiClient().currentUser?.fullName.isNotEmpty == true
                ? ApiClient().currentUser!.fullName
                : 'Pengguna RETIVA'));

    final email = (savedEmail != null && savedEmail.isNotEmpty)
        ? savedEmail
        : (ApiClient().currentUser?.email.isNotEmpty == true
            ? ApiClient().currentUser!.email
            : (widget.patient != null
                ? '${widget.patient!.fullName.toLowerCase().replaceAll(' ', '.')}@gmail.com'
                : 'pengguna@retiva.id'));

    final nik = (widget.patient?.nik.isNotEmpty == true)
        ? widget.patient!.nik
        : ((savedNik != null && savedNik.isNotEmpty)
            ? savedNik
            : '3404011204650001');

    if (mounted) {
      setState(() {
        _patientName = name;
        _patientEmail = email;
        _patientNik = nik;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientName = _patientName.isNotEmpty
        ? _patientName
        : (widget.patient?.fullName.isNotEmpty == true ? widget.patient!.fullName : 'Pengguna RETIVA');
    final patientNik = _patientNik.isNotEmpty
        ? _patientNik
        : (widget.patient?.nik.isNotEmpty == true ? widget.patient!.nik : '3404011204650001');
    final patientEmail = _patientEmail.isNotEmpty
        ? _patientEmail
        : 'pengguna@retiva.id';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: const [
          Center(child: NotificationBellWidget()),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header Info (CareSync style)
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD6E4FF), width: 2),
                        color: const Color(0xFFEFF6FF),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/mascot_laptop.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.check, size: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        patientEmail,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF4FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'NIK: $patientNik',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Health Overview (CareSync 2x2 Grid)
            const Text(
              'Ikhtisar Kesehatan',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildHealthCard(
                    icon: Icons.favorite_rounded,
                    iconColor: const Color(0xFF246BFD),
                    iconBg: const Color(0xFFEFF6FF),
                    label: 'Detak Jantung',
                    value: '72',
                    unit: 'bpm',
                    extraWidget: _buildEcgWave(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHealthCard(
                    icon: Icons.bloodtype_rounded,
                    iconColor: const Color(0xFFEF4444),
                    iconBg: const Color(0xFFFEE2E2),
                    label: 'Gula Darah',
                    value: '90',
                    unit: 'mg/dL',
                    subtitle: 'Normal (Puasa)',
                    subtitleColor: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildHealthCard(
                    icon: Icons.speed_rounded,
                    iconColor: const Color(0xFF246BFD),
                    iconBg: const Color(0xFFEFF6FF),
                    label: 'Tekanan Darah',
                    value: '120/80',
                    unit: 'mmHg',
                    subtitle: 'Optimal Perdami',
                    subtitleColor: const Color(0xFF246BFD),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHealthCard(
                    icon: Icons.medication_rounded,
                    iconColor: const Color(0xFF246BFD),
                    iconBg: const Color(0xFFEFF6FF),
                    label: 'Jadwal Obat',
                    value: '2/3',
                    unit: 'Diminum',
                    subtitle: 'Jadwal Obat Aktif',
                    subtitleColor: const Color(0xFF246BFD),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // CareSync Menu List (Semua Ikon Warna Biru Retiva & Bahasa Indonesia)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.description_outlined,
                    iconColor: const Color(0xFF246BFD),
                    iconBg: const Color(0xFFEFF6FF),
                    title: 'Hasil Lab & Skrining Retina',
                    subtitle: 'Hasil foto fundus & telaah AI',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PatientHistoryScreen()),
                    ),
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.calendar_month_outlined,
                    iconColor: const Color(0xFF246BFD),
                    iconBg: const Color(0xFFEFF6FF),
                    title: 'Janji Temu & Agenda Pasien',
                    subtitle: 'Jadwal kontrol mata & obat rutin',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DailyCareAgendaScreen(patient: widget.patient),
                      ),
                    ),
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.restaurant_outlined,
                    iconColor: const Color(0xFF246BFD),
                    iconBg: const Color(0xFFEFF6FF),
                    title: 'Nutrisi Pintar (Diet 3J)',
                    subtitle: 'Rekomendasi gizi stabil diabetes',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SmartMealDetailScreen()),
                    ),
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.local_hospital_outlined,
                    iconColor: const Color(0xFF246BFD),
                    iconBg: const Color(0xFFEFF6FF),
                    title: 'Konsultasi & Rujukan Medis',
                    subtitle: 'Surat rujukan BPJS & RS rujukan',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReferralLetterScreen(patient: widget.patient),
                      ),
                    ),
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    iconColor: const Color(0xFF246BFD),
                    iconBg: const Color(0xFFEFF6FF),
                    title: 'Pengaturan Aplikasi',
                    subtitle: 'Notifikasi, bahasa & privasi medis',
                    onTap: () => _showSettingsModal(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Log Out Button (CareSync style)
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD6E4FF), width: 1.5),
                color: Colors.white,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    await ApiClient().clearToken();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthWelcomeScreen()),
                        (route) => false,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Log out',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    required String unit,
    String? subtitle,
    Color? subtitleColor,
    Widget? extraWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          if (extraWidget != null) ...[
            const SizedBox(height: 6),
            extraWidget,
          ] else if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: subtitleColor ?? AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSettingsModal(BuildContext context) {
    bool notifObat = true;
    bool notifKontrol = true;
    bool syncSatuSehat = true;
    bool offlineMode = true;
    bool largeTextMode = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.82,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pengaturan Aplikasi',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFFF1F5F9)),
                Expanded(
                  child: ListView(
                    children: [
                      // Section 1: Pengingat & Notifikasi
                      const Text(
                        'PENGINGAT & NOTIFIKASI MEDIS',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primary,
                        title: const Text('Pengingat Minum Obat Harian', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                        subtitle: const Text('Alarm otomatis sesuai dosis resep dokter', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        value: notifObat,
                        onChanged: (v) => setModalState(() => notifObat = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primary,
                        title: const Text('Pengingat Skrining Retina Berkala', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                        subtitle: const Text('Notifikasi skrining ulang 6-12 bulan sesuai rekomendasi Perdami', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        value: notifKontrol,
                        onChanged: (v) => setModalState(() => notifKontrol = v),
                      ),
                      const SizedBox(height: 16),

                      // Section 2: Integrasi Faskes
                      const Text(
                        'INTEGRASI FASKES & REKAM MEDIS',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primary,
                        title: const Text('Sinkronisasi SatuSehat Kemenkes RI', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                        subtitle: const Text('Kirim telaah AI fundus ke rekam medis nasional', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        value: syncSatuSehat,
                        onChanged: (v) => setModalState(() => syncSatuSehat = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primary,
                        title: const Text('Mode Skrining Tanpa Sinyal (Offline AI)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                        subtitle: const Text('Inferensi model di perangkat jika koneksi Puskesmas terputus', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        value: offlineMode,
                        onChanged: (v) => setModalState(() => offlineMode = v),
                      ),
                      const SizedBox(height: 16),

                      // Section 3: Aksesibilitas
                      const Text(
                        'BAHASA & AKSESIBILITAS PASIEN',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.language_rounded, color: AppColors.primary),
                        title: const Text('Bahasa Aplikasi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFDBEAFE)),
                          ),
                          child: const Text('Bahasa Indonesia', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primary,
                        title: const Text('Mode Huruf Besar (Aksesibilitas Lansia)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                        subtitle: const Text('Meningkatkan keterbacaan hasil diagnosis retinopati', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        value: largeTextMode,
                        onChanged: (v) => setModalState(() => largeTextMode = v),
                      ),
                      const SizedBox(height: 16),

                      // Section 4: Privasi & Data
                      const Text(
                        'PRIVASI & PENYIMPANAN DATA',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cache foto fundus dan data temporer berhasil dibersihkan!'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                        icon: const Icon(Icons.cleaning_services_rounded, size: 16, color: AppColors.primary),
                        label: const Text('Bersihkan Cache Foto Retina Lokal', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFBFDBFE)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          'Retiva CareSync Mobile v2.4.0 (Build 2026.10)\nPlatform Skrining Nasional Retinopati Diabetik',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade400, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEcgWave() {
    return SizedBox(
      height: 16,
      child: CustomPaint(
        painter: _EcgPainter(),
        size: const Size(double.infinity, 16),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 68,
      endIndent: 16,
      color: Color(0xFFF1F5F9),
    );
  }
}

class _EcgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF246BFD)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final w = size.width;
    final h = size.height;
    final mid = h / 2;

    path.moveTo(0, mid);
    path.lineTo(w * 0.25, mid);
    path.lineTo(w * 0.32, mid - 2);
    path.lineTo(w * 0.40, mid + 3);
    path.lineTo(w * 0.48, mid - h * 0.45);
    path.lineTo(w * 0.58, mid + h * 0.35);
    path.lineTo(w * 0.65, mid);
    path.lineTo(w * 0.72, mid - 4);
    path.lineTo(w * 0.80, mid);
    path.lineTo(w, mid);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
