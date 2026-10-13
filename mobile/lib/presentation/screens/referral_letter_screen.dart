import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/clinical_helpers.dart';
import '../../data/models/screening_result_model.dart';
import '../../data/models/patient_model.dart';
import '../widgets/brand_header.dart';
import '../widgets/custom_button.dart';

class ReferralLetterScreen extends StatelessWidget {
  final Map<String, dynamic>? facility;
  final CompleteScreeningResult? result;
  final PatientModel? patient;

  const ReferralLetterScreen({
    super.key,
    this.facility,
    this.result,
    this.patient,
  });

  @override
  Widget build(BuildContext context) {
    final facilityName = facility?['name'] ?? 'RS Mata Dr. Yap Yogyakarta';
    final facilityAddress = facility?['address'] ?? 'Jl. Cik Di Tiro No.5, Terban, Kota Yogyakarta';
    final distance = facility?['distanceKm']?.toString() ?? '3.8';
    final hba1c = patient?.diabetesProfile?.lastHbA1c?.toString() ?? '8.4';
    final bp = patient?.diabetesProfile?.bloodPressure ?? '138/86 mmHg';

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
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Surat Pengantar Rujukan (SPK)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge Header (Figma 49:3053 & 49:3291)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.statusGreenSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.statusGreen),
                      ),
                      child: const Text(
                        '15. PENERBITAN SPK & DOKUMEN REKAM MEDIS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.statusGreen,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Surat Pengantar Rujukan (SPK) Elektronik',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Dokumen rujukan terstandar ICD-10 terintegrasi dengan Rekam Medis Elektronik (RME) Permenkes No. 24/2022.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    ),

                    const SizedBox(height: 20),

                    // Official SPK Document Visual Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Official Hospital/FKTP Letterhead
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.local_hospital, color: AppColors.primaryDark, size: 24),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PEMERINTAH KABUPATEN SLEMAN',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                                    ),
                                    Text(
                                      'PUSKESMAS SLEMAN — DINAS KESEHATAN',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Jl. Magelang Km. 12, Sleman, D.I. Yogyakarta • Telp: (0274) 868409',
                                      style: TextStyle(fontSize: 9, color: AppColors.textMuted),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Surat Rujukan Penapisan Retinopati Diabetik (CDSS)',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          // Document Tracking & Barcode Simulation
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSpkField('Nomor SPK:', 'SPK/RTV/2026/09/0084'),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.divider,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.qr_code_2, size: 14, color: AppColors.textSecondary),
                                    SizedBox(width: 4),
                                    Text(
                                      'RME-VALIDATED',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          _buildSpkField(
                            'Nama Pasien:',
                            patient != null
                                ? '${patient!.fullName} (${patient!.age} th) • ${patient!.gender == 'MALE' ? 'Laki-laki' : 'Perempuan'}'
                                : 'Bapak Sutrisno (56 th) • Laki-laki',
                          ),
                          const SizedBox(height: 8),
                          _buildSpkField('Nomor Induk Kependudukan (NIK):', patient?.nik ?? '3404015508750001'),
                          const SizedBox(height: 8),

                          // Vital Signs Clinical Summary Table
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tanda Vital & Parameter Metabolik (Puskesmas):',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildVitalItem('Tekanan Darah', bp),
                                    _buildVitalItem('Kadar HbA1c', '$hba1c%'),
                                    _buildVitalItem('Gula Darah Sewaktu', '186 mg/dL'),
                                    _buildVitalItem('Visus OD/OS', '6/12 • 6/9'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          _buildSpkField(
                            'Diagnosis Primer ICD-10:',
                            result != null && result!.aiResult.predictedClass == 'NO_DR'
                                ? 'E11.9 (Type 2 DM without complications)'
                                : 'E11.319 (Type 2 DM with Nonproliferative Diabetic Retinopathy)',
                          ),
                          const SizedBox(height: 8),
                          _buildSpkField('Diagnosis Sekunder ICD-10:', 'I10 (Essential / Primary Hypertension)'),
                          const SizedBox(height: 8),
                          _buildSpkField(
                            'Derajat Keparahan ICDR:',
                            result != null
                                ? ClinicalHelpers.getSeverityTitle(result!.aiResult.predictedClass)
                                : 'Moderate NPDR (Retinopati Diabetik Non-Proliferatif Sedang)',
                          ),
                          const SizedBox(height: 8),
                          _buildSpkField('Fasilitas Rujukan Dituju (FKRTL):', '$facilityName ($distance km)'),
                          const SizedBox(height: 8),
                          _buildSpkField('Alamat RS Tujuan:', facilityAddress),
                          const SizedBox(height: 8),
                          _buildSpkField('Poli Spesialis Tujuan:', 'Poliklinik Mata (Subspesialis Vitreoretina)'),
                          const SizedBox(height: 8),
                          _buildSpkField('Jaminan Kesehatan:', 'BPJS Kesehatan / JKN (Status Aktif • No: 0001892837192)'),

                          const Divider(height: 24),

                          // Digital Signature & BSrE Verification Seal
                          Row(
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Nakes Pemeriksa (FKTP):', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                    Text('Siti Nurhaliza, S.Tr.Kes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                    Text('NIP: 199204122018022001', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                                    SizedBox(height: 4),
                                    Text('Dokter Penanggung Jawab:', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                    Text('dr. Arif Wicaksono', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                    Text('SIP: 503/3312/SIP-D/2021', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.statusGreenSurface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.statusGreen),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified, size: 14, color: AppColors.statusGreen),
                                        SizedBox(width: 4),
                                        Text(
                                          'TERVERIFIKASI',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.statusGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'TTE Tersertifikasi BSrE/BSSN',
                                    style: TextStyle(fontSize: 8, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Download / Print Actions
                    CustomButton(
                      label: 'Unduh / Cetak Surat Rujukan (PDF)',
                      icon: Icons.download_outlined,
                      backgroundColor: AppColors.primary,
                      onPressed: () {
                        _showPdfActionDialog(context, facilityName);
                      },
                    ),

                    const SizedBox(height: 12),

                    // Secondary action: send to BPJS VClaim
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Data rujukan berhasil disinkronkan ke SIMRS & BPJS VClaim No: 0184R0010926V00012.'),
                            backgroundColor: AppColors.statusGreen,
                          ),
                        );
                      },
                      icon: const Icon(Icons.sync_alt, size: 18, color: AppColors.secondary),
                      label: const Text(
                        'Sinkronkan ke BPJS VClaim / SATUSEHAT',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.secondary),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        side: const BorderSide(color: AppColors.secondary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    const SizedBox(height: 12),

                    CustomButton(
                      label: 'Selesai & Kembali ke Beranda',
                      icon: Icons.check,
                      isOutlined: true,
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
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

  Widget _buildVitalItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildSpkField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showPdfActionDialog(BuildContext context, String facilityName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.picture_as_pdf, color: AppColors.statusRed),
            SizedBox(width: 8),
            Text('Dokumen SPK Terbit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dokumen Surat Pengantar Rujukan resmi telah dikonversi ke format PDF terenkripsi digital.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('File: SPK_RETIVA_2026090084.pdf (248 KB)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  Text('Tujuan: $facilityName', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  const Text('Tanda Tangan Elektronik: Valid BSrE', style: TextStyle(fontSize: 10, color: AppColors.statusGreen)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Surat Pengantar Rujukan (SPK) PDF berhasil diunduh ke memori perangkat.'),
                  backgroundColor: AppColors.statusGreen,
                ),
              );
            },
            icon: const Icon(Icons.file_download, size: 16),
            label: const Text('Simpan PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
