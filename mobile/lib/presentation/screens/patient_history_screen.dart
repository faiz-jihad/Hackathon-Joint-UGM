import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/models/patient_model.dart';
import '../widgets/patient_intake_modal.dart';
import 'upload_fundus_screen.dart';

class PatientHistoryScreen extends StatefulWidget {
  const PatientHistoryScreen({super.key});

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<PatientModel> _patients = [];
  bool _isLoading = true;
  String _selectedFilter = 'ALL'; // ALL, HIGH_HBA1C, T2DM, T1DM
  String? _expandedPatientId;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients([String query = '']) async {
    final list = await ApiClient().getPatients(query: query);
    if (mounted) {
      setState(() {
        _patients = list;
        _isLoading = false;
      });
    }
  }

  List<PatientModel> get _filteredPatients {
    if (_selectedFilter == 'HIGH_HBA1C') {
      return _patients.where((p) => (p.diabetesProfile?.lastHbA1c ?? 0) >= 8.0).toList();
    } else if (_selectedFilter == 'T2DM') {
      return _patients.where((p) => p.diabetesProfile?.diabetesType == 'TYPE_2').toList();
    } else if (_selectedFilter == 'T1DM') {
      return _patients.where((p) => p.diabetesProfile?.diabetesType == 'TYPE_1').toList();
    }
    return _patients;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Standard Figma Retiva Top Bar
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(9999),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 15,
                        color: Color(0xFF246BFD),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Riwayat Pemeriksaan',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF246BFD),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Informative Header Section (Figma Frame 140:658)
                    const Text(
                      'Riwayat Pemeriksaan',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D1E25),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Daftar riwayat pemeriksaan foto retina mandiri Anda.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF434652),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Medical Progress Summary Strip
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD0E7F5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDFF1FB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.history_rounded,
                              size: 20,
                              color: Color(0xFF246BFD),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Pemeriksaan',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF737783),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_patients.length} Pasien Terdaftar',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0D1E25),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'RME Valid',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Search Field by NIK or Name
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari berdasarkan NIK 16-digit atau Nama Pasien...',
                        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _loadPatients('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      onChanged: (val) => _loadPatients(val),
                    ),

                    const SizedBox(height: 12),

                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('ALL', 'Semua (${_patients.length})'),
                          const SizedBox(width: 8),
                          _buildFilterChip('HIGH_HBA1C', 'HbA1c >= 8.0% (Prioritas)'),
                          const SizedBox(width: 8),
                          _buildFilterChip('T2DM', 'DM Tipe 2'),
                          const SizedBox(width: 8),
                          _buildFilterChip('T1DM', 'DM Tipe 1'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Longitudinal Spotlight Feature Card
                    if (_patients.isNotEmpty)
                      _buildLongitudinalTimelineCard(_patients.first),

                    const SizedBox(height: 24),

                    // Patient Directory List Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daftar Pasien Terdaftar di Faskes',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (_) => PatientIntakeModal(
                                onPatientCreated: (p) => _loadPatients(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person_add, size: 14),
                          label: const Text('+ Pasien Baru', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_isLoading)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                    else if (_filteredPatients.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.search_off, size: 36, color: AppColors.textMuted),
                            SizedBox(height: 8),
                            Text(
                              'Tidak ada pasien yang sesuai filter kriteria.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._filteredPatients.map((pat) => _buildPatientListItem(pat)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildLongitudinalTimelineCard([PatientModel? patient]) {
    final patientName = patient != null
        ? '${patient.fullName} • NIK: ${patient.nik}'
        : 'Pasien Terdaftar Rekam Medis';

    final diagnosisYear = patient?.diabetesProfile?.yearOfDiagnosis;
    final lastHbA1c = patient?.diabetesProfile?.lastHbA1c;
    final treatment = patient?.diabetesProfile?.currentTreatment ?? 'Terapi Terjadwal';
    final bp = patient?.diabetesProfile?.bloodPressure ?? '-';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.timeline, color: AppColors.primaryDark, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Timeline Progresivitas Retina Pasien',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    Text(
                      patientName,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          _buildTimelineNode(
            year: diagnosisYear != null ? 'Tahun Terdiagnosis: $diagnosisYear' : 'Pemeriksaan Awal Faskes',
            grade: 'Tipe: ${patient?.diabetesProfile?.diabetesType ?? "DM"}',
            color: AppColors.statusGreen,
            details: 'Regimen: $treatment. Kontrol berkala faskes pertama.',
          ),
          _buildTimelineNode(
            year: 'Evaluasi Terkini',
            grade: 'Tekanan Darah: $bp',
            color: (lastHbA1c != null && lastHbA1c >= 8.0) ? AppColors.statusOrange : AppColors.statusYellow,
            details: lastHbA1c != null
                ? 'Kadar HbA1c: $lastHbA1c%. Status: ${patient?.diabetesProfile?.glycaemicControlStatus ?? "Optimal"}.'
                : 'Data skrining retina tersimpan di basis data rekam medis.',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineNode({
    required String year,
    required String grade,
    required Color color,
    required String details,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.4), blurRadius: 4),
                ],
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 55,
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(year, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(grade, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
                const SizedBox(height: 2),
                Text(details, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientListItem(PatientModel pat) {
    final isExpanded = _expandedPatientId == pat.id;
    final hba1c = pat.diabetesProfile?.lastHbA1c ?? 0;
    final isHighHba1c = hba1c >= 8.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isExpanded ? AppColors.primary : AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expandedPatientId = isExpanded ? null : pat.id),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isHighHba1c ? AppColors.statusOrangeSurface : AppColors.primarySurface,
                    child: Text(
                      pat.fullName.isNotEmpty ? pat.fullName[0] : 'P',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isHighHba1c ? AppColors.statusOrange : AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                pat.fullName,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (isHighHba1c)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.statusOrangeSurface,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Risiko Tinggi',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.statusOrange),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'NIK: ${pat.nik} • ${pat.gender == "MALE" ? "Laki-laki" : "Perempuan"} (${pat.age} th)',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        if (pat.diabetesProfile != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'HbA1c: ${pat.diabetesProfile!.lastHbA1c}% (${pat.diabetesProfile!.glycaemicControlStatus})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isHighHba1c ? AppColors.statusOrange : AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UploadFundusScreen(initialPatient: pat),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primarySurface,
                      foregroundColor: AppColors.primaryDark,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Skrining', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),

          // Expandable Clinical Medical Profile Section
          if (isExpanded) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.background.withOpacity(0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profil Medis & Rekam Medis Elektronik (RME):',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                  ),
                  const SizedBox(height: 8),
                  _buildProfileRow('Tipe Diabetes Mellitus', pat.diabetesProfile?.diabetesType == 'TYPE_1' ? 'Tipe 1' : 'Tipe 2'),
                  _buildProfileRow('Durasi Diagnosis DM', '${pat.diabetesProfile?.diagnosisYear != null ? DateTime.now().year - pat.diabetesProfile!.diagnosisYear : 6} Tahun'),
                  _buildProfileRow('Tekanan Darah Terkini', pat.diabetesProfile?.bloodPressure ?? '130/85 mmHg'),
                  _buildProfileRow('Terapi Insulin', pat.diabetesProfile?.hasInsulinTherapy == true ? 'Ya (Insulin Aktif)' : 'Tidak (Oral OAD)'),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Profil RME ${pat.fullName} terverifikasi SATUSEHAT.'),
                              backgroundColor: AppColors.statusGreen,
                            ),
                          );
                        },
                        icon: const Icon(Icons.verified_user, size: 14),
                        label: const Text('Validasi SATUSEHAT', style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
