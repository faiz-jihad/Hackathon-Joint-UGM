import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/models/screening_result_model.dart';
import '../../data/models/patient_model.dart';
import '../widgets/brand_header.dart';
import '../widgets/custom_button.dart';
import 'referral_letter_screen.dart';

class ClinicalRecommendationScreen extends StatefulWidget {
  final CompleteScreeningResult result;
  final String eyePosition;
  final PatientModel? patient;

  const ClinicalRecommendationScreen({
    super.key,
    required this.result,
    required this.eyePosition,
    this.patient,
  });

  @override
  State<ClinicalRecommendationScreen> createState() => _ClinicalRecommendationScreenState();
}

class _ClinicalRecommendationScreenState extends State<ClinicalRecommendationScreen> {
  List<Map<String, dynamic>> _facilities = [];
  bool _isLoadingFacilities = true;
  String _selectedFacilityId = 'fac-001';

  @override
  void initState() {
    super.initState();
    _loadFacilities();
  }

  Future<void> _loadFacilities() async {
    final list = await ApiClient().getNearestFacilities();
    if (mounted) {
      setState(() {
        _facilities = list;
        _isLoadingFacilities = false;
        if (list.isNotEmpty) {
          _selectedFacilityId = list.first['id'] ?? 'fac-001';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const BrandHeader(showBack: true),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: const Text(
                        '14. TINDAKAN LANJUTAN & RUJUKAN FASKES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Rekomendasi Tindakan Klinis Deterministik',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Dieksekusi berdasarkan konsensus nasional Perdami 2024 dan standar ADA 2024 (bukan inferensi bebas AI).',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    ),

                    const SizedBox(height: 20),

                    // Guideline Action Card (Figma 43:2725)
                    _buildGuidelineActionCard(),

                    const SizedBox(height: 24),

                    // Nearest Referral Facilities (Geodesic Haversine & BPJS)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pilihan Fasilitas Rujukan Terdekat',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondarySurface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'BPJS-Ready',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_isLoadingFacilities)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                    else
                      ..._facilities.map((fac) => _buildFacilityCard(fac)),

                    const SizedBox(height: 24),

                    // Issue Referral Button
                    CustomButton(
                      label: 'Terbitkan Surat Pengantar Rujukan (SPK)',
                      icon: Icons.description_outlined,
                      onPressed: () {
                        final selectedFac = _facilities.firstWhere(
                          (f) => f['id'] == _selectedFacilityId,
                          orElse: () => _facilities.first,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReferralLetterScreen(
                              facility: selectedFac,
                              result: widget.result,
                              patient: widget.patient,
                            ),
                          ),
                        );
                      },
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

  Widget _buildGuidelineActionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified, color: AppColors.statusGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Pedoman Klinis Perdami & ADA 2024',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ],
          ),
          const Divider(height: 20),
          _buildItem('Rekomendasi Tindakan:', 'Rujukan ke Dokter Spesialis Mata (Sp.M) di FKRTL'),
          const SizedBox(height: 8),
          _buildItem('Interval Batas Waktu:', '3 – 6 Bulan dari Tanggal Skrining'),
          const SizedBox(height: 8),
          _buildItem('Optimalisasi Metabolik:', 'Target kendali HbA1c < 7.0% & tekanan darah < 130/80 mmHg'),
          const SizedBox(height: 8),
          _buildItem('Kode Diagnostik ICD-10:', 'E11.319 (Type 2 DM with nonproliferative DR)'),
        ],
      ),
    );
  }

  Widget _buildItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildFacilityCard(Map<String, dynamic> fac) {
    final isSelected = fac['id'] == _selectedFacilityId;

    return GestureDetector(
      onTap: () => setState(() => _selectedFacilityId = fac['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: fac['id'],
              groupValue: _selectedFacilityId,
              onChanged: (val) => setState(() => _selectedFacilityId = val!),
              activeColor: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fac['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fac['address'] ?? '',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.statusGreenSurface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'BPJS: ${fac['bpjsStatus']}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.statusGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${fac['distanceKm']} km (Haversine)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
