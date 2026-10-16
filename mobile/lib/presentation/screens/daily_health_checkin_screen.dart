import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/models/daily_check_in_model.dart';
import '../../data/models/patient_model.dart';
import '../../core/services/widget_service.dart';
import '../widgets/notification_bell_widget.dart';

class DailyHealthCheckinScreen extends StatefulWidget {
  final PatientModel? patient;

  const DailyHealthCheckinScreen({super.key, this.patient});

  static List<Map<String, dynamic>> get healthJournalHistory =>
      _DailyHealthCheckinScreenState.healthJournalHistory;

  @override
  State<DailyHealthCheckinScreen> createState() => _DailyHealthCheckinScreenState();
}

class _DailyHealthCheckinScreenState extends State<DailyHealthCheckinScreen> {
  // Form State
  String _physicalCondition = 'NORMAL'; // FIT, NORMAL, LEMAS, LELAH_PUSING
  final TextEditingController _glucoseController = TextEditingController();
  String _glucoseContext = 'FASTING'; // FASTING, POST_PRANDIAL, RANDOM
  final TextEditingController _systolicController = TextEditingController();
  final TextEditingController _diastolicController = TextEditingController();
  bool _medicationsTaken = true;
  bool _activityCompleted = true;
  final TextEditingController _notesController = TextEditingController();

  // Static Health Journal History (persisted during session)
  static final List<Map<String, dynamic>> healthJournalHistory = [
    {
      'date': '15 Okt 2026 • 07:15 WIB',
      'glucose': '118 mg/dL',
      'context': 'Puasa (GDP)',
      'bp': '120/80 mmHg',
      'status': 'Optimal',
      'notes': 'Kondisi fisik bugar, obat diminum teratur.',
    },
    {
      'date': '14 Okt 2026 • 19:30 WIB',
      'glucose': '142 mg/dL',
      'context': '2 Jam PP',
      'bp': '126/82 mmHg',
      'status': 'Terkontrol',
      'notes': 'Makan malam sayur bayam & ikan kembung.',
    },
    {
      'date': '13 Okt 2026 • 07:30 WIB',
      'glucose': '124 mg/dL',
      'context': 'Puasa (GDP)',
      'bp': '128/84 mmHg',
      'status': 'Terkontrol',
      'notes': 'Tidur nyenyak 7 jam, jalan pagi 25 menit.',
    },
  ];

  // Red-flag eye symptoms
  bool _flagSuddenBlur = false;
  bool _flagFlashes = false;
  bool _flagFloaters = false;
  bool _flagCurtainShadow = false;
  bool _flagSeverePain = false;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _glucoseController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _hasAnyEmergencyFlag =>
      _flagSuddenBlur || _flagFlashes || _flagFloaters || _flagCurtainShadow || _flagSeverePain;

  Future<void> _submitCheckIn() async {
    setState(() => _isSubmitting = true);

    final double? glucoseVal = double.tryParse(_glucoseController.text.trim());
    final String sys = _systolicController.text.trim();
    final String dia = _diastolicController.text.trim();
    final String bpVal = (sys.isNotEmpty && dia.isNotEmpty) ? '$sys/$dia mmHg' : '120/80 mmHg';

    // Simpan ke Jurnal Kesehatan (Fitur 3)
    if (_glucoseController.text.trim().isNotEmpty || (sys.isNotEmpty && dia.isNotEmpty)) {
      final now = DateTime.now();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      final dateStr = '${now.day} ${months[now.month - 1]} ${now.year} • ${now.hour.toString().padLeft(2, "0")}:${now.minute.toString().padLeft(2, "0")} WIB';

      healthJournalHistory.insert(0, {
        'date': dateStr,
        'glucose': glucoseVal != null ? '${glucoseVal.toStringAsFixed(0)} mg/dL' : '118 mg/dL',
        'context': _glucoseContext == 'FASTING' ? 'Puasa (GDP)' : _glucoseContext == 'POST_PRANDIAL' ? '2 Jam PP' : 'Sewaktu (GDS)',
        'bp': bpVal,
        'status': (glucoseVal != null && glucoseVal > 180) ? 'Perlu Waspada' : 'Optimal',
        'notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : 'Pencatatan check-in mandiri.',
      });
    }

    final submission = DailyCheckInSubmission(
      patientId: widget.patient?.id ?? 'P-001',
      physicalCondition: _physicalCondition,
      visualSymptoms: _hasAnyEmergencyFlag
          ? 'Terdeteksi gejala mata darurat: ${_buildSelectedFlagsString()}'
          : 'Gejala mata terpantau stabil/normal.',
      visualFlags: {
        'sudden_blur': _flagSuddenBlur,
        'flashes': _flagFlashes,
        'new_floaters': _flagFloaters,
        'curtain_shadow': _flagCurtainShadow,
        'severe_eye_pain': _flagSeverePain,
      },
      bloodGlucose: glucoseVal,
      glucoseContext: _glucoseContext,
      medicationsCompleted: _medicationsTaken,
      activityCompleted: _activityCompleted,
      patientNotes: _notesController.text.trim(),
    );

    final result = await ApiClient().submitDailyCheckIn(submission);

    // Synchronize latest agenda with Android Home Widget
    try {
      final freshAgenda = await ApiClient().getDailyAgenda(submission.patientId);
      await WidgetService.updateWidgetData(freshAgenda);
    } catch (_) {}

    if (mounted) {
      setState(() => _isSubmitting = false);
      _showResultDialog(result);
    }
  }

  String _buildSelectedFlagsString() {
    final list = <String>[];
    if (_flagSuddenBlur) list.add('Buram Mendadak');
    if (_flagFlashes) list.add('Kilatan Cahaya (Fotopsia)');
    if (_flagFloaters) list.add('Bintik Floaters Mendadak');
    if (_flagCurtainShadow) list.add('Bayangan Tirai');
    if (_flagSeverePain) list.add('Nyeri Mata Hebat');
    return list.join(', ');
  }

  void _showResultDialog(DailyCheckInResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: result.isEmergency ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FF),
                  child: Icon(
                    result.isEmergency ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                    color: result.isEmergency ? AppColors.figmaRetakeRed : const Color(0xFF246BFD),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result.summary,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: result.isEmergency ? AppColors.figmaRetakeRed : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              result.explanation,
              style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: result.isEmergency ? const Color(0xFFFFF1F2) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: result.isEmergency ? const Color(0xFFFECDD3) : const Color(0xFFBBF7D0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Langkah Berikutnya:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: result.isEmergency ? const Color(0xFF9F1239) : const Color(0xFF166534),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.nextStep,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: result.isEmergency ? const Color(0xFFBE123C) : const Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
            ),
            if (result.actionableGuidance.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...result.actionableGuidance.map(
                (g) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(g, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              result.clinicalSafetyNotice,
              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8)),
            ),
          ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: result.isEmergency ? AppColors.figmaRetakeRed : AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(result.isEmergency ? 'Saya Mengerti (Cari IGD)' : 'Tutup & Lanjutkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Check-in & Jurnal Sehat',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Center(child: NotificationBellWidget()),
          SizedBox(width: 14),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.timer_outlined, color: AppColors.primary, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Evaluasi mandiri harian membantu sistem memantau kestabilan mata Anda dan mendeteksi tanda bahaya retina sejak dini.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 1. Kondisi Fisik
            const Text('1. Bagaimana kondisi fisik Anda hari ini?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPhysicalChip('FIT', 'Segar & Bugar', Icons.sentiment_very_satisfied_rounded),
                _buildPhysicalChip('NORMAL', 'Normal / Biasa', Icons.sentiment_satisfied_rounded),
                _buildPhysicalChip('LEMAS', 'Cukup Lemas', Icons.sentiment_neutral_rounded),
                _buildPhysicalChip('LELAH_PUSING', 'Lelah / Pusing', Icons.sentiment_dissatisfied_rounded),
              ],
            ),
            const SizedBox(height: 24),

            // 2. Gejala Penglihatan (Safety Gate Red Flags)
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '2. Adakah keluhan pada penglihatan Anda?',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                ),
                if (_hasAnyEmergencyFlag) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                    child: const Text('DARURAT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFDC2626))),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            const Text('Pilih jika mengalami salah satu tanda berikut:',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 8),

            _buildEmergencyCheckbox(
              title: 'Penglihatan buram mendadak',
              subtitle: 'Penurunan ketajaman penglihatan drastis dalam beberapa jam/hari',
              value: _flagSuddenBlur,
              onChanged: (v) => setState(() => _flagSuddenBlur = v ?? false),
            ),
            _buildEmergencyCheckbox(
              title: 'Melihat kilatan cahaya (fotopsia)',
              subtitle: 'Sensasi kelap-kelip atau seperti kilat petir saat mata bergerak',
              value: _flagFlashes,
              onChanged: (v) => setState(() => _flagFlashes = v ?? false),
            ),
            _buildEmergencyCheckbox(
              title: 'Bintik hitam / floaters bertambah banyak mendadak',
              subtitle: 'Muncul seperti sarang laba-laba atau hujan bintik hitam',
              value: _flagFloaters,
              onChanged: (v) => setState(() => _flagFloaters = v ?? false),
            ),
            _buildEmergencyCheckbox(
              title: 'Bayangan seperti tirai menutup pandangan',
              subtitle: 'Ada bagian bidang pandang yang gelap atau terhalang bayangan',
              value: _flagCurtainShadow,
              onChanged: (v) => setState(() => _flagCurtainShadow = v ?? false),
            ),
            _buildEmergencyCheckbox(
              title: 'Nyeri hebat pada bola mata',
              subtitle: 'Sakit mata berat disertai mual atau pusing kepala',
              value: _flagSeverePain,
              onChanged: (v) => setState(() => _flagSeverePain = v ?? false),
            ),

            const SizedBox(height: 24),

            // =================================================================
            // FITUR 3: JURNAL KESEHATAN (GULA DARAH & TEKANAN DARAH)
            // =================================================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.monitor_heart_rounded, color: Color(0xFF246BFD), size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '3. Jurnal Kesehatan Pasien',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _showHealthJournalDialog(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF93C5FD)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history_rounded, size: 12, color: Color(0xFF1D4ED8)),
                              SizedBox(width: 4),
                              Text(
                                'Rekap Dokter',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Menyimpan hasil gula darah dan tekanan darah untuk dibawa saat konsultasi ke dokter.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),

                  // A. Kadar Gula Darah
                  const Text('A. Kadar Gula Darah:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _glucoseController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Contoh: 120',
                            suffixText: 'mg/dL',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 4,
                        child: DropdownButtonFormField<String>(
                          value: _glucoseContext,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'FASTING', child: Text('Puasa (GDP)', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'POST_PRANDIAL', child: Text('2 Jam PP', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'RANDOM', child: Text('Sewaktu (GDS)', style: TextStyle(fontSize: 12))),
                          ],
                          onChanged: (v) => setState(() => _glucoseContext = v ?? 'FASTING'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // B. Tekanan Darah
                  const Text('B. Tekanan Darah (Tensi):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _systolicController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Sistolik (120)',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('/', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _diastolicController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Diastolik (80)',
                            suffixText: 'mmHg',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Kepatuhan Hari Ini
            const Text('4. Kepatuhan Pengobatan & Gaya Hidup:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Obat resep dokter diminum sesuai jadwal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: const Text('Metformin atau obat yang diresepkan spesialis', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              value: _medicationsTaken,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _medicationsTaken = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aktivitas fisik ringan terlaksana', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: const Text('Jalan santai 30 menit atau senam kaki diabetes', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              value: _activityCompleted,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _activityCompleted = v),
            ),
            const SizedBox(height: 16),

            // 5. Catatan Tambahan
            const Text('Catatan Keluhan Lain (opsional):',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Tuliskan jika ada keluhan lain...',
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasAnyEmergencyFlag ? AppColors.figmaRetakeRed : AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _hasAnyEmergencyFlag ? 'Kirim & Dapatkan Arahan Darurat' : 'Simpan & Evaluasi AI',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPhysicalChip(String key, String label, IconData icon) {
    final isSelected = _physicalCondition == key;
    return ChoiceChip(
      showCheckmark: false,
      avatar: Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.primary),
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : const Color(0xFF334155),
      ),
      side: BorderSide(color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1)),
      onSelected: (_) => setState(() => _physicalCondition = key),
    );
  }

  Widget _buildEmergencyCheckbox({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: value ? const Color(0xFFFEF2F2) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: value ? const Color(0xFFF87171) : const Color(0xFFE2E8F0)),
      ),
      child: CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: value ? const Color(0xFFB91C1C) : const Color(0xFF0F172A))),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        value: value,
        activeColor: AppColors.figmaRetakeRed,
        onChanged: onChanged,
      ),
    );
  }

  void _showHealthJournalDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.monitor_heart_rounded, color: Color(0xFF246BFD), size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jurnal Kesehatan Pasien',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Rekap Gula Darah & Tekanan Darah untuk Konsultasi Dokter',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: healthJournalHistory.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final item = healthJournalHistory[idx];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['date'] ?? '-',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Text(
                                item['status'] ?? 'Optimal',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF246BFD),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Gula Darah', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                    const SizedBox(height: 2),
                                    Text(
                                      item['glucose'] ?? '-',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                    ),
                                    Text(
                                      item['context'] ?? '-',
                                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w500, color: Color(0xFF246BFD)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Tekanan Darah', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                    const SizedBox(height: 2),
                                    Text(
                                      item['bp'] ?? '-',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                    ),
                                    const Text('Optimal (< 130/80)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF246BFD))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (item['notes'] != null && item['notes'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Catatan: ${item["notes"]}',
                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF475569)),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final buffer = StringBuffer();
                      buffer.writeln('📋 *JURNAL KESEHATAN PASIEN (RETIVA)*');
                      buffer.writeln('Pasien: ${widget.patient?.fullName ?? "Pasien Binaan"} (NIK: ${widget.patient?.nik ?? "-"})');
                      buffer.writeln('Rekap Gula Darah & Tekanan Darah untuk Konsultasi Dokter:\n');
                      for (final item in healthJournalHistory) {
                        buffer.writeln('🗓️ ${item['date']} [${item['status']}]');
                        buffer.writeln('   • Gula Darah: ${item['glucose']} (${item['context']})');
                        buffer.writeln('   • Tekanan Darah: ${item['bp']}');
                        if (item['notes'] != null && item['notes'].toString().isNotEmpty) {
                          buffer.writeln('   • Catatan: ${item['notes']}');
                        }
                        buffer.writeln('');
                      }
                      buffer.writeln('Dokumen terintegrasi dengan Rekam Medis CDSS Retiva.');

                      await Clipboard.setData(ClipboardData(text: buffer.toString()));
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text('Ringkasan jurnal berhasil disalin! Siap dibagikan ke dokter spesialis.'),
                                ),
                              ],
                            ),
                            backgroundColor: Color(0xFF246BFD),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF246BFD)),
                    label: const Text('Salin untuk Dokter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF246BFD))),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      side: const BorderSide(color: Color(0xFF246BFD)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF246BFD),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Tutup', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
