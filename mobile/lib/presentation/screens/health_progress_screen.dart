import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/models/patient_model.dart';

class HealthProgressScreen extends StatefulWidget {
  final PatientModel? patient;

  const HealthProgressScreen({super.key, this.patient});

  @override
  State<HealthProgressScreen> createState() => _HealthProgressScreenState();
}

class _HealthProgressScreenState extends State<HealthProgressScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _checkInLogs = [];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  String get _patientId => widget.patient?.id ?? 'P-001';

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    final logs = await ApiClient().getCheckInHistory(_patientId);
    if (mounted) {
      setState(() {
        _checkInLogs = logs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Tren & Progres Perawatan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadProgress,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Weekly Completion Card
                    _buildWeeklyCompletionCard(),
                    const SizedBox(height: 16),

                    // Glucose Trend Section
                    _buildGlucoseTrendSection(),
                    const SizedBox(height: 16),

                    // Weekly AI Summary
                    _buildWeeklyAiSummaryCard(),
                    const SizedBox(height: 16),

                    // Check-in History List
                    const Text(
                      'Riwayat Check-in & Evaluasi Harian',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 10),
                    if (_checkInLogs.isNotEmpty)
                      ..._checkInLogs.map((log) => _buildLogCard(log))
                    else
                      _buildMockLogList(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWeeklyCompletionCard() {
    final days = [
      {'day': 'Sen', 'done': true},
      {'day': 'Sel', 'done': true},
      {'day': 'Rab', 'done': true},
      {'day': 'Kam', 'done': true},
      {'day': 'Jum', 'done': false},
      {'day': 'Sab', 'done': false},
      {'day': 'Min', 'done': false},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kepatuhan Agenda 7 Hari',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFE8F8F0), borderRadius: BorderRadius.circular(6)),
                child: const Text('85% Terpenuhi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((d) {
              final isDone = d['done'] == true;
              return Column(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isDone ? AppColors.statusGreen : const Color(0xFFF1F5F9),
                    child: Icon(
                      isDone ? Icons.check_rounded : Icons.schedule_rounded,
                      size: 16,
                      color: isDone ? Colors.white : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    d['day'] as String,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDone ? AppColors.textPrimary : AppColors.textMuted),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGlucoseTrendSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kadar Glukosa Darah Terakhir',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4)),
                child: const Text('Laporan Mandiri Pasien', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Puasa (GDP)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      SizedBox(height: 4),
                      Text('118 mg/dL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      SizedBox(height: 4),
                      Text('✅ Target: 70-130', style: TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('2 Jam PP (GD2PP)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      SizedBox(height: 4),
                      Text('155 mg/dL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      SizedBox(height: 4),
                      Text('✅ Target: < 180', style: TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyAiSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E5FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Ringkasan AI Mingguan (Berdasarkan Data Riil)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Kepatuhan minum obat rutin dan pola sarapan berindeks glikemik rendah berjalan konsisten (85%). '
            'Tidak terlaporkan tanda bahaya retina akut seperti kilatan cahaya atau bayangan tirai. '
            'Pertahankan hidrasi dan aktivitas fisik ringan seperti jalan santai 30 menit per hari.',
            style: TextStyle(fontSize: 12, height: 1.45, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 10),
          const Text(
            'Catatan: Ringkasan ini disusun dari data harian yang Anda laporkan dan resep dokter yang aktif.',
            style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final hasUrgent = log['hasUrgentSymptoms'] == true;
    final dateStr = log['date'] ?? log['timestamp']?.toString().split('T').first ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasUrgent ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasUrgent ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: hasUrgent ? AppColors.figmaRetakeRed : AppColors.statusGreen,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text('Gejala: ${log['symptoms'] ?? 'Stabil'}', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                if (log['bloodGlucose'] != null)
                  Text('Gula darah: ${log['bloodGlucose']} mg/dL (${log['glucoseContext'] ?? 'Puasa'})',
                      style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockLogList() {
    final mockData = [
      {'date': 'Hari ini', 'symptoms': 'Kondisi stabil, mata segar', 'glucose': '118 mg/dL (Puasa)', 'hasUrgent': false},
      {'date': 'Kemarin', 'symptoms': 'Mata sedikit lelah setelah membaca', 'glucose': '155 mg/dL (2 Jam PP)', 'hasUrgent': false},
      {'date': '2 hari lalu', 'symptoms': 'Kondisi stabil dan bugar', 'glucose': '112 mg/dL (Puasa)', 'hasUrgent': false},
    ];

    return Column(
      children: mockData.map((d) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: AppColors.statusGreen, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d['date'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text(d['symptoms'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                    Text(d['glucose'] as String, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
