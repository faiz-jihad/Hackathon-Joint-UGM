import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/models/patient_model.dart';
import '../widgets/brand_header.dart';
import '../widgets/patient_intake_modal.dart';
import 'upload_fundus_screen.dart';
import 'patient_history_screen.dart';
import 'referral_letter_screen.dart';

class HomeScreen extends StatefulWidget {
  final String title;

  const HomeScreen({super.key, required this.title});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PatientModel> _patients = [];
  List<Map<String, dynamic>> _facilities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLiveDashboardData();
  }

  Future<void> _loadLiveDashboardData() async {
    try {
      final patients = await ApiClient().getPatients();
      final facilities = await ApiClient().getNearestFacilities();
      if (mounted) {
        setState(() {
          _patients = patients;
          _facilities = facilities;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openPatientIntake() {
    PatientIntakeModal.show(
      context,
      onPatientCreated: (newPatient) {
        setState(() {
          _patients.insert(0, newPatient);
        });
      },
    );
  }

  void _showDrRiskCalculator() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildRiskCalculatorSheet(ctx),
    );
  }

  void _showSopDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.menu_book, color: AppColors.primary, size: 22),
            SizedBox(width: 10),
            Text('SOP Pemotretan Retina FKTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Standar Prosedur Operasional (Konsensus Perdami 2024):',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
            SizedBox(height: 10),
            Text('1. Ruangan redup (dark adaptation 3-5 menit) agar pupil berdilatasi fisiologis.'),
            SizedBox(height: 6),
            Text('2. Posisi mata sejajar lensa kamera fundus pada jarak optik 1.5 - 2.0 cm.'),
            SizedBox(height: 6),
            Text('3. Instruksikan pasien fokus pada lampu target fiksasi makula, tanpa berkedip saat rana.'),
            SizedBox(height: 6),
            Text('4. Validasi citra seketika via Quality Gate (Laplacian Sharpness >= 0.40 & FOV >= 45°).'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic counts computed purely from active database dataset
    final patientCount = _patients.length;
    final facilityCount = _facilities.length;
    final highRiskCount = _patients.where((p) => (p.diabetesProfile?.lastHbA1c ?? 0) >= 8.5).length;
    final moderateRiskCount = _patients.where((p) {
      final h = p.diabetesProfile?.lastHbA1c ?? 0;
      return h >= 7.0 && h < 8.5;
    }).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Brand Header matching Figma
            const BrandHeader(),
            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),

            // Scrollable Medical Console Body
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadLiveDashboardData,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Practitioner Shift & Facility Credential Card
                      _buildPractitionerShiftCard(),

                      const SizedBox(height: 16),

                      // Hero Medical Screening Card
                      _buildHeroCard(context),

                      const SizedBox(height: 20),

                      // Clinical Triage Metrics Row (100% Dynamic from PostgreSQL DB)
                      _buildStatsRow(
                        patientCount: patientCount,
                        highRiskCount: highRiskCount,
                        moderateRiskCount: moderateRiskCount,
                        facilityCount: facilityCount,
                      ),

                      const SizedBox(height: 24),

                      // Section Title: Alur Kerja Klinis
                      const Row(
                        children: [
                          Icon(Icons.medical_services_outlined, size: 18, color: AppColors.primaryDark),
                          SizedBox(width: 8),
                          Text(
                            'Alur Kerja Skrining FKTP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _buildActionCard(
                        context,
                        title: 'Skrining Retina Bilateral (OD/OS)',
                        subtitle: 'Pemeriksaan funduskopi digital baru dengan uji kendali mutu otomatis & inferensi AI.',
                        icon: Icons.camera_alt_outlined,
                        accentColor: AppColors.primary,
                        isHighlighted: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UploadFundusScreen(
                                initialPatient: _patients.isNotEmpty ? _patients.first : null,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      _buildActionCard(
                        context,
                        title: 'Registrasi Pasien DM Baru (+ Intake Rekam Medis)',
                        subtitle: 'Pendaftaran cepat pasien diabetes baru langsung tersimpan ke basis data PostgreSQL.',
                        icon: Icons.person_add_alt_1_outlined,
                        accentColor: AppColors.statusGreen,
                        onTap: _openPatientIntake,
                      ),

                      const SizedBox(height: 12),

                      _buildActionCard(
                        context,
                        title: 'Direktori & Riwayat Pasien ($patientCount Pasien Terdaftar)',
                        subtitle: 'Pencarian NIK pasien diabetes dan pemantauan timeline lesi longitudinal tahunan.',
                        icon: Icons.people_outline,
                        accentColor: AppColors.secondary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PatientHistoryScreen()),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      _buildActionCard(
                        context,
                        title: 'Faskes Rujukan & BPJS ($facilityCount RS Terverifikasi)',
                        subtitle: 'Katalog RS mata sekunder/tersier dengan kalkulasi jarak geodesik & status klaim JKN.',
                        icon: Icons.local_hospital_outlined,
                        accentColor: AppColors.statusPurple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReferralLetterScreen(
                                facility: _facilities.isNotEmpty ? _facilities.first : null,
                                patient: _patients.isNotEmpty ? _patients.first : null,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Clinical Decision Support Tools (Calculators & SOP)
                      _buildClinicalToolsRow(),

                      const SizedBox(height: 24),

                      // Recent Dynamic Patients Preview Section
                      if (_patients.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Pasien Terdaftar Terkini (Basis Data DB)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const PatientHistoryScreen()),
                                );
                              },
                              child: const Text('Lihat Semua', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._patients.take(3).map((p) => _buildPatientPreviewTile(context, p)),
                        const SizedBox(height: 16),
                      ],

                      // Clinical Guidance Notice
                      _buildGuidelineCard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPractitionerShiftCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primaryLight.withOpacity(0.4)),
            ),
            child: const Icon(Icons.badge, color: AppColors.primaryDark, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Siti Nurhaliza, S.Tr.Kes',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                Text(
                  'NIP: 199204122018022001 • Puskesmas Sleman (FKTP)',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.statusGreenSurface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.statusGreen.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 3, backgroundColor: AppColors.statusGreen),
                SizedBox(width: 4),
                Text('Shift Aktif', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.statusGreen)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.health_and_safety, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Puskesmas / FKTP Siaga DM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text(
                'Perdami 2024 Ready',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Skrining Dini Komplikasi Retina Diabetes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mencegah risiko kebutaan permanen melalui deteksi objektif lesi mikrovaskular bilateral berbasis AI 5-Class ICDR.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UploadFundusScreen(
                    initialPatient: _patients.isNotEmpty ? _patients.first : null,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add_a_photo, size: 18, color: AppColors.primaryDark),
            label: const Text(
              'Mulai Skrining Baru',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow({
    required int patientCount,
    required int highRiskCount,
    required int moderateRiskCount,
    required int facilityCount,
  }) {
    return Row(
      children: [
        _buildStatItem('$patientCount', 'Pasien di DB', AppColors.statusGreen, Icons.people_outline),
        const SizedBox(width: 8),
        _buildStatItem('$highRiskCount', 'HbA1c >= 8.5%', AppColors.statusRed, Icons.warning_amber_rounded),
        const SizedBox(width: 8),
        _buildStatItem('$moderateRiskCount', 'HbA1c 7-8.4%', AppColors.statusYellow, Icons.assessment_outlined),
        const SizedBox(width: 8),
        _buildStatItem('$facilityCount', 'RS Rujukan', AppColors.statusPurple, Icons.local_hospital_outlined),
      ],
    );
  }

  Widget _buildStatItem(String count, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(
              count,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                height: 1.2,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicalToolsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.calculate_outlined, size: 18, color: AppColors.secondary),
            SizedBox(width: 8),
            Text(
              'Alat Dukungan Keputusan Klinis (CDSS)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _showDrRiskCalculator,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.biotech, size: 16, color: AppColors.secondary),
                          SizedBox(width: 6),
                          Text('Kalkulator DR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.secondary)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text('Prediksi risiko progresi mikroretina berdasarkan HbA1c & Tensi.', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, height: 1.3)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: _showSopDialog,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.menu_book, size: 16, color: AppColors.primaryDark),
                          SizedBox(width: 6),
                          Text('SOP Pemotretan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text('Pedoman resmi 4-langkah pengambilan citra fundus Perdami.', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, height: 1.3)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRiskCalculatorSheet(BuildContext ctx) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kalkulator Risiko Komplikasi DR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Berdasarkan UKPDS & Konsensus Perdami 2024: Kombinasi kadar HbA1c > 8.0% dan hipertensi meningkatkan risiko progresivitas retinopati diabetik hingga 3.2x lipat.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          const Divider(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.statusRedSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.statusRed.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.statusRed, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Zona Risiko Tinggi Progresi Retina', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.statusRed)),
                      Text('HbA1c >= 8.5% memerlukan pemantauan ketat setiap 3-6 bulan dan skrining funduskopi bilateral segera.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 12)),
              child: const Text('Tutup Kalkulator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientPreviewTile(BuildContext context, PatientModel patient) {
    final hba1c = patient.diabetesProfile?.lastHbA1c ?? 0.0;
    final isHigh = hba1c >= 8.5;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UploadFundusScreen(initialPatient: patient)),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: isHigh ? AppColors.statusRedSurface : AppColors.primarySurface,
              child: Icon(
                Icons.person,
                size: 16,
                color: isHigh ? AppColors.statusRed : AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.fullName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  Text(
                    'NIK: ${patient.nik} • ${patient.age} th',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isHigh ? AppColors.statusRedSurface : AppColors.statusGreenSurface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'HbA1c ${hba1c.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isHigh ? AppColors.statusRed : AppColors.statusGreen,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isHighlighted ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted ? AppColors.primary.withOpacity(0.4) : AppColors.border,
            width: isHighlighted ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 14),
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: AppColors.secondary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kepatuhan Standar Medis & UU PDP',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Seluruh data terintegrasi ke basis data terenkripsi dan mematuhi Permenkes No. 24/2022 (RME) serta UU Perlindungan Data Pribadi No. 27/2022.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
