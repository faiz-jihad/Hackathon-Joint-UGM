import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/models/daily_check_in_model.dart';
import '../../data/models/patient_model.dart';
import '../../core/services/widget_service.dart';

class DailyHealthCheckinScreen extends StatefulWidget {
  final PatientModel? patient;

  const DailyHealthCheckinScreen({super.key, this.patient});

  @override
  State<DailyHealthCheckinScreen> createState() => _DailyHealthCheckinScreenState();
}

class _DailyHealthCheckinScreenState extends State<DailyHealthCheckinScreen> {
  // Form State
  String _physicalCondition = 'NORMAL'; // FIT, NORMAL, LEMAS, LELAH_PUSING
  final TextEditingController _glucoseController = TextEditingController();
  String _glucoseContext = 'FASTING'; // FASTING, POST_PRANDIAL, RANDOM
  bool _medicationsTaken = true;
  bool _activityCompleted = true;
  final TextEditingController _notesController = TextEditingController();

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
    _notesController.dispose();
    super.dispose();
  }

  bool get _hasAnyEmergencyFlag =>
      _flagSuddenBlur || _flagFlashes || _flagFloaters || _flagCurtainShadow || _flagSeverePain;

  Future<void> _submitCheckIn() async {
    setState(() => _isSubmitting = true);

    final double? glucoseVal = double.tryParse(_glucoseController.text.trim());

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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: result.isEmergency ? const Color(0xFFFEE2E2) : const Color(0xFFE8F8F0),
                  child: Icon(
                    result.isEmergency ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                    color: result.isEmergency ? AppColors.figmaRetakeRed : AppColors.statusGreen,
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
          'Check-in Harian (30 Detik)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
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
                const Text('2. Adakah keluhan pada penglihatan Anda?',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                const SizedBox(width: 6),
                if (_hasAnyEmergencyFlag)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                    child: const Text('DARURAT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFDC2626))),
                  ),
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

            // 3. Kadar Gula Darah (Opsional)
            const Text('3. Hasil ukur gula darah hari ini (opsional):',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
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
                      fillColor: Colors.white,
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
                      fillColor: Colors.white,
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
              activeColor: AppColors.statusGreen,
              onChanged: (v) => setState(() => _medicationsTaken = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aktivitas fisik ringan terlaksana', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: const Text('Jalan santai 30 menit atau senam kaki diabetes', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              value: _activityCompleted,
              activeColor: AppColors.statusGreen,
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
                        _hasAnyEmergencyFlag ? 'Kirim & Dapatkan Arahan Darurat' : 'Simpan & Evaluasi AI (30 Detik)',
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
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.primary),
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
}
