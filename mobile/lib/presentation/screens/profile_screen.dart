import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/patient_model.dart';
import 'patient_history_screen.dart';
import 'daily_care_agenda_screen.dart';
import 'referral_letter_screen.dart';
import 'smart_meal_detail_screen.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  final PatientModel? patient;
  const ProfileScreen({super.key, this.patient});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final patientName = widget.patient?.fullName.isNotEmpty == true
        ? widget.patient!.fullName
        : 'Bpk. Bambang Sutrisno';
    final patientNik = widget.patient?.nik.isNotEmpty == true
        ? widget.patient!.nik
        : '3404011204650001';
    final patientEmail = 'bambang.sutrisno@gmail.com';

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
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur edit profil tersimpan')),
              );
            },
            child: const Text(
              'Edit profile',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
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
              'Health Overview',
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
                    label: 'Heart Rate',
                    value: '72',
                    unit: 'bpm',
                    extraWidget: _buildEcgWave(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHealthCard(
                    icon: Icons.bloodtype_rounded,
                    iconColor: const Color(0xFF00C566),
                    iconBg: const Color(0xFFE8F8F0),
                    label: 'Blood Sugar',
                    value: '90',
                    unit: 'mg/dL',
                    subtitle: 'Normal (Puasa)',
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
                    iconColor: const Color(0xFF3B82F6),
                    iconBg: const Color(0xFFEFF6FF),
                    label: 'Blood Pressure',
                    value: '120/80',
                    unit: 'mmHg',
                    subtitle: 'Optimal Perdami',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHealthCard(
                    icon: Icons.medication_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    iconBg: const Color(0xFFF5F3FF),
                    label: 'Pill Reminder',
                    value: '2/3',
                    unit: 'Diminum',
                    subtitle: 'Jadwal Obat Aktif',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // CareSync Menu List
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
                    title: 'My lab test & screening',
                    subtitle: 'Hasil foto fundus & telaah AI',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PatientHistoryScreen()),
                    ),
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.calendar_month_outlined,
                    iconColor: const Color(0xFF00C566),
                    iconBg: const Color(0xFFE8F8F0),
                    title: 'My appointment & agenda',
                    subtitle: 'Jadwal kontrol mata & obat',
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
                    iconColor: const Color(0xFFF59E0B),
                    iconBg: const Color(0xFFFFFBEB),
                    title: 'Smart nutrition (Pola 3J)',
                    subtitle: 'Rekomendasi gizi stabil diabetes',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SmartMealDetailScreen()),
                    ),
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.local_hospital_outlined,
                    iconColor: const Color(0xFF8B5CF6),
                    iconBg: const Color(0xFFF5F3FF),
                    title: 'My consultation & referral',
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
                    icon: Icons.people_outline_rounded,
                    iconColor: const Color(0xFF06B6D4),
                    iconBg: const Color(0xFFECFEFF),
                    title: 'Add family member',
                    subtitle: 'Daftarkan keluarga & caregiver',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pendaftaran anggota keluarga siap')),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    iconColor: const Color(0xFF64748B),
                    iconBg: const Color(0xFFF8FAFC),
                    title: 'Settings',
                    subtitle: 'Notifikasi, bahasa & privasi medis',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pengaturan sistem')),
                      );
                    },
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    );
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
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF059669),
              ),
            ),
          ],
        ],
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
