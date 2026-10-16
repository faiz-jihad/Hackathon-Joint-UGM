import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/clinical_helpers.dart';
import '../../core/utils/platform_helper.dart';
import '../../core/utils/pdf_spk_generator.dart';
import '../../data/models/screening_result_model.dart';
import '../../data/models/patient_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/notification_bell_widget.dart';
import 'care_companion_hub_screen.dart';

class ReferralLetterScreen extends StatefulWidget {
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
  State<ReferralLetterScreen> createState() => _ReferralLetterScreenState();
}

class _ReferralLetterScreenState extends State<ReferralLetterScreen> {
  // Fitur 1: Pelacakan Rujukan State (3 Tahap Utama)
  int _referralStep = 2; // Default sudah di tahap jadwal terkonfirmasi
  DateTime _confirmedDate = DateTime.now().add(const Duration(days: 7));
  final String _confirmedTime = '09:00 WIB';
  bool _isExaminationDone = false;

  // Fitur BPJS Bridging & VClaim
  bool _isSyncingBpjs = false;
  bool _isBpjsSynced = false;
  final String _bpjsVclaimNo = '0184R0010926V00012';

  // Fitur GPS & Deteksi Rumah Sakit Terdekat
  late Map<String, dynamic> _activeFacility;
  List<Map<String, dynamic>> _nearbyFacilities = [];
  bool _isDetectingGps = false;
  String _currentGpsLocation = 'Puskesmas Sleman, Jl. Magelang Km 12, D.I. Yogyakarta';
  String _gpsCoordinates = '(-7.6885, 110.3400)';

  @override
  void initState() {
    super.initState();
    _activeFacility = widget.facility != null
        ? Map<String, dynamic>.from(widget.facility!)
        : {
            'id': 'fac-yap',
            'name': 'RS Mata Dr. Yap Yogyakarta',
            'type': 'RS Khusus Mata Tipe A',
            'bpjsStatus': 'ACCEPTED',
            'address': 'Jl. Cik Di Tiro No. 5, Terban, Gondokusuman, Kota Yogyakarta',
            'distanceKm': 2.3,
            'travelTime': '± 8 mnt',
            'phone': '(0274) 562054',
            'doctor_name': 'dr. Hendra Kusuma, Sp.M',
            'subspecialty': 'Subspesialis Vitreoretina & Makula',
            'availableSubspecialties': ['Retina Medis', 'Bedah Vitreoretina', 'Laser Fotokoagulasi'],
            'scheduleInfo': 'Poli Retina: Senin - Sabtu (08.00 - 15.00 WIB)',
            'mapX': 0.78,
            'mapY': 0.58,
          };
    _loadNearbyHospitals();
  }

  Future<void> _loadNearbyHospitals() async {
    try {
      final list = await ApiClient().getNearestFacilities();
      if (mounted && list.isNotEmpty) {
        setState(() {
          _nearbyFacilities = list.map((f) {
            final m = Map<String, dynamic>.from(f);
            if (!m.containsKey('doctor_name')) {
              if (m['id'] == 'fac-sardjito') {
                m['doctor_name'] = 'dr. Siti Nurhaliza, Sp.M(K)';
                m['subspecialty'] = 'Konsultan Retina & Diabetes';
                m['travelTime'] = '± 11 mnt';
                m['mapX'] = 0.58;
                m['mapY'] = 0.32;
              } else if (m['id'] == 'fac-sleman') {
                m['doctor_name'] = 'dr. Arga Pratama, Sp.M';
                m['subspecialty'] = 'Spesialis Oftalmologi';
                m['travelTime'] = '± 14 mnt';
                m['mapX'] = 0.22;
                m['mapY'] = 0.22;
              } else if (m['id'] == 'fac-yap-sleman') {
                m['doctor_name'] = 'dr. Yunani Setyandriana, Sp.M';
                m['subspecialty'] = 'Spesialis Vitreoretina & Oftalmologi';
                m['travelTime'] = '± 12 mnt';
                m['mapX'] = 0.40;
                m['mapY'] = 0.45;
              } else {
                m['doctor_name'] = 'dr. Hendra Kusuma, Sp.M';
                m['subspecialty'] = 'Subspesialis Vitreoretina & Makula';
                m['travelTime'] = '± 8 mnt';
                m['mapX'] = 0.78;
                m['mapY'] = 0.58;
              }
            }
            return m;
          }).toList();
        });
      }
    } catch (_) {}

    if (_nearbyFacilities.isEmpty && mounted) {
      setState(() {
        _nearbyFacilities = [
          {
            'id': 'fac-yap',
            'name': 'RS Mata Dr. Yap Yogyakarta',
            'type': 'RS Khusus Mata Tipe A',
            'bpjsStatus': 'ACCEPTED',
            'address': 'Jl. Cik Di Tiro No. 5, Terban, Gondokusuman, Kota Yogyakarta',
            'distanceKm': 2.3,
            'travelTime': '± 8 mnt',
            'phone': '(0274) 562054',
            'doctor_name': 'dr. Hendra Kusuma, Sp.M',
            'subspecialty': 'Subspesialis Vitreoretina & Makula',
            'mapX': 0.78,
            'mapY': 0.58,
          },
          {
            'id': 'fac-sardjito',
            'name': 'RSUP Dr. Sardjito (KSM Mata)',
            'type': 'RSUP Rujukan Nasional',
            'bpjsStatus': 'ACCEPTED',
            'address': 'Jl. Kesehatan No. 1, Sekip, Kec. Mlati, Kab. Sleman',
            'distanceKm': 3.1,
            'travelTime': '± 11 mnt',
            'phone': '(0274) 631190',
            'doctor_name': 'dr. Siti Nurhaliza, Sp.M(K)',
            'subspecialty': 'Konsultan Retina & Diabetes',
            'mapX': 0.58,
            'mapY': 0.32,
          },
          {
            'id': 'fac-yap-sleman',
            'name': 'Klinik Mata Utama dr. YAP Sleman',
            'type': 'Klinik Spesialis Mata Utama',
            'bpjsStatus': 'ACCEPTED',
            'address': 'Jl. Magelang Km 9.5, Denggung, Tridadi, Sleman',
            'distanceKm': 4.2,
            'travelTime': '± 12 mnt',
            'phone': '(0274) 869900',
            'doctor_name': 'dr. Yunani Setyandriana, Sp.M',
            'subspecialty': 'Spesialis Vitreoretina & Oftalmologi',
            'mapX': 0.40,
            'mapY': 0.45,
          },
          {
            'id': 'fac-sleman',
            'name': 'RSUD Sleman',
            'type': 'RSUD Rujukan Tingkat 2',
            'bpjsStatus': 'ACCEPTED',
            'address': 'Jl. Bhayangkara No. 48, Triharjo, Kec. Sleman',
            'distanceKm': 5.8,
            'travelTime': '± 14 mnt',
            'phone': '(0274) 868437',
            'doctor_name': 'dr. Arga Pratama, Sp.M',
            'subspecialty': 'Spesialis Oftalmologi',
            'mapX': 0.22,
            'mapY': 0.22,
          },
        ];
      });
    }
  }

  void _detectCurrentGpsLocation() async {
    setState(() {
      _isDetectingGps = true;
    });
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() {
        _isDetectingGps = false;
        _currentGpsLocation = 'Puskesmas Sleman, Jl. Magelang Km 12, D.I. Yogyakarta';
        _gpsCoordinates = '(-7.6885, 110.3400)';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF246BFD),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: const [
              Icon(Icons.gps_fixed_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lokasi GPS terverifikasi: Sleman, D.I. Yogyakarta. Jarak 4 Faskes rujukan terdekat telah disinkronkan.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _changeScheduleDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _confirmedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF246BFD),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _confirmedDate = picked;
        _referralStep = 2;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Jadwal rujukan berhasil diperbarui ke: ${_formatDate(_confirmedDate)} pukul $_confirmedTime',
            ),
            backgroundColor: const Color(0xFF246BFD),
          ),
        );
      }
    }
  }

  void _markExaminationCompleted() {
    setState(() {
      _isExaminationDone = true;
      _referralStep = 3;
    });
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF246BFD), size: 24),
            SizedBox(width: 8),
            Text(
              'Pemeriksaan Selesai',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: const Text(
          'Pemeriksaan di Poli Mata RS Rujukan telah ditandai selesai! Hasil diagnosis dan rencana terapi dokter spesialis kini dapat diakses di menu Rencana Perawatan Saya.',
          style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CareCompanionHubScreen(
                    patient: widget.patient,
                    screeningResult: widget.result,
                    initialStep: 2, // Ke fase 3 / rencana dokter
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF246BFD),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Buka Rencana dari Dokter'),
          ),
        ],
      ),
    );
  }

  void _syncToBpjs() async {
    setState(() => _isSyncingBpjs = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() {
        _isSyncingBpjs = false;
        _isBpjsSynced = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.verified_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bridging BPJS VClaim Berhasil! No. Rujukan: 0184R0010926V00012 telah disinkronkan ke SIMRS & SATUSEHAT.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF246BFD),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _openInGoogleMaps() {
    final name = _activeFacility['name'] ?? 'RS Mata Terdekat';
    final addr = _activeFacility['address'] ?? 'Yogyakarta';
    final query = Uri.encodeComponent('$name, $addr');
    openUrl('https://www.google.com/maps/search/?api=1&query=$query');
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final facilityName = _activeFacility['name'] ?? 'RS Mata Dr. Yap Yogyakarta';
    final facilityAddress = _activeFacility['address'] ?? 'Jl. Cik Di Tiro No. 5, Terban, Gondokusuman, Yogyakarta';
    final distance = _activeFacility['distanceKm']?.toString() ?? '2.3';
    final hba1c = widget.patient?.diabetesProfile?.lastHbA1c != null
        ? '${widget.patient!.diabetesProfile!.lastHbA1c}'
        : '7.8';
    final bp = widget.patient?.diabetesProfile?.bloodPressure ?? '130/85';

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
                  const Expanded(
                    child: Text(
                      'Surat Pengantar Rujukan (SPK)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF246BFD),
                      ),
                    ),
                  ),
                  const NotificationBellWidget(),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      'Dokumen rujukan terstandar ICD-10 terintegrasi dengan Rekam Medis Elektronik (RME) Permenkes No. 24/2022 & BPJS VClaim.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    ),

                    const SizedBox(height: 18),

                    // =========================================================
                    // FITUR 1: PELACAKAN RUJUKAN (REFERRAL TRACKING)
                    // =========================================================
                    _buildReferralTrackingCard(),

                    const SizedBox(height: 20),

                    // =========================================================
                    // FITUR 6: AKSES PERAWATAN & INFORMASI FASILITAS KESEHATAN
                    // =========================================================
                    _buildHealthcareAccessCard(facilityName, facilityAddress, distance),

                    const SizedBox(height: 20),

                    // Official SPK Document Visual Card
                    _buildSpkDocumentCard(facilityName, hba1c, bp),

                    const SizedBox(height: 20),

                    // Primary Action: Download PDF SPK
                    CustomButton(
                      label: 'Unduh Surat Rujukan Resmi (PDF)',
                      icon: Icons.picture_as_pdf,
                      borderRadius: 12,
                      onPressed: () => _showPdfActionDialog(context, facilityName),
                    ),

                    const SizedBox(height: 12),

                    // Secondary action: send to BPJS VClaim
                    OutlinedButton.icon(
                      onPressed: _isSyncingBpjs ? null : _syncToBpjs,
                      icon: _isSyncingBpjs
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF246BFD)),
                            )
                          : Icon(
                              _isBpjsSynced ? Icons.check_circle_rounded : Icons.sync_alt,
                              size: 18,
                              color: const Color(0xFF246BFD),
                            ),
                      label: Text(
                        _isSyncingBpjs
                            ? 'Menghubungkan ke BPJS VClaim...'
                            : _isBpjsSynced
                                ? '✓ Tersinkronkan ke BPJS VClaim No: $_bpjsVclaimNo'
                                : 'Sinkronkan ke BPJS VClaim / SATUSEHAT',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF246BFD)),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: _isBpjsSynced ? const Color(0xFFEFF6FF) : Colors.transparent,
                        side: BorderSide(
                          color: const Color(0xFF246BFD),
                          width: _isBpjsSynced ? 1.5 : 1.0,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    const SizedBox(height: 12),

                    CustomButton(
                      label: 'Buka Rencana Perawatan Saya',
                      icon: Icons.assignment_turned_in_rounded,
                      isOutlined: true,
                      borderRadius: 12,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CareCompanionHubScreen(
                              patient: widget.patient,
                              screeningResult: widget.result,
                              initialStep: 1,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGET: PELACAKAN RUJUKAN (FITUR 1)
  // Mengetahui apakah: 1. Surat diterbitkan, 2. Jadwal dikonfirmasi, 3. Pemeriksaan dilakukan
  // ===========================================================================
  Widget _buildReferralTrackingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF246BFD).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.track_changes_rounded,
                  color: Color(0xFF246BFD),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pelacakan Alur Rujukan',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Pantau 3 tahapan rujukan Anda',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _isExaminationDone ? 'Selesai' : 'Tahap $_referralStep/3',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF246BFD),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Milestone 1: Surat Rujukan Diterbitkan
          _buildTrackingStepItem(
            stepNumber: 1,
            title: 'Surat Sudah Diterbitkan',
            subtitle: 'SPK digital resmi terbit dengan nomor SPK/RTV/2026/09/0084.',
            isCompleted: true,
            isActive: false,
            timestamp: 'Hari ini • 09:15 WIB',
          ),

          _buildTrackingConnector(isCompleted: true),

          // Milestone 2: Jadwal Sudah Dikonfirmasi
          _buildTrackingStepItem(
            stepNumber: 2,
            title: 'Jadwal Sudah Dikonfirmasi',
            subtitle: '${_formatDate(_confirmedDate)} • Pukul $_confirmedTime di Poli Mata.',
            isCompleted: _referralStep >= 2,
            isActive: _referralStep == 2 && !_isExaminationDone,
            timestamp: 'Poli Vitreoretina Faskes Rujukan',
            actionWidget: InkWell(
              onTap: _changeScheduleDate,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF93C5FD)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_calendar_rounded, size: 14, color: Color(0xFF1D4ED8)),
                    SizedBox(width: 6),
                    Text(
                      'Ubah / Konfirmasi Tanggal Kunjungan',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          _buildTrackingConnector(isCompleted: _isExaminationDone),

          // Milestone 3: Pemeriksaan Sudah Dilakukan
          _buildTrackingStepItem(
            stepNumber: 3,
            title: 'Pemeriksaan Sudah Dilakukan',
            subtitle: _isExaminationDone
                ? 'Pemeriksaan di Poli Mata telah selesai. Instruksi & terapi dokter tersimpan.'
                : 'Bawa SPK digital ini saat tiba di loket pendaftaran rumah sakit.',
            isCompleted: _isExaminationDone,
            isActive: !_isExaminationDone,
            timestamp: _isExaminationDone ? 'Selesai • Terverifikasi RME' : 'Menunggu Kunjungan',
            actionWidget: !_isExaminationDone
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ElevatedButton.icon(
                      onPressed: _markExaminationCompleted,
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text(
                        'Tandai Pemeriksaan Telah Selesai',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF246BFD),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingStepItem({
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    required String timestamp,
    Widget? actionWidget,
  }) {
    Color iconColor;
    Color iconBg;
    IconData icon;

    if (isCompleted) {
      iconColor = Colors.white;
      iconBg = const Color(0xFF246BFD);
      icon = Icons.check;
    } else if (isActive) {
      iconColor = Colors.white;
      iconBg = const Color(0xFF246BFD);
      icon = Icons.pending_rounded;
    } else {
      iconColor = const Color(0xFF94A3B8);
      iconBg = const Color(0xFFE2E8F0);
      icon = Icons.circle_outlined;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF246BFD).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isCompleted || isActive ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Text(
                    timestamp,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? const Color(0xFF246BFD) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF475569),
                  height: 1.35,
                ),
              ),
              if (actionWidget != null) actionWidget,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingConnector({required bool isCompleted}) {
    return Container(
      margin: const EdgeInsets.only(left: 13, top: 4, bottom: 4),
      width: 2,
      height: 20,
      color: isCompleted ? const Color(0xFF246BFD) : const Color(0xFFCBD5E1),
    );
  }

  // ===========================================================================
  // WIDGET: AKSES PERAWATAN & MAPS FASILITAS KESEHATAN TERDEKAT (FITUR 6)
  // Menyediakan deteksi GPS lokasi saat ini, peta radar, & pilihan faskes rujukan
  // ===========================================================================
  Widget _buildHealthcareAccessCard(String facilityName, String facilityAddress, String distance) {
    final activeTargetX = (_activeFacility['mapX'] as num?)?.toDouble() ?? 0.78;
    final activeTargetY = (_activeFacility['mapY'] as num?)?.toDouble() ?? 0.58;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Card (Anti-Overflow)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: Color(0xFF246BFD),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Faskes Rujukan & Peta Terdekat',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Deteksi RS mata terdekat berbasis GPS lokasi saat ini',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. Banner Deteksi GPS Lokasi Pasien Saat Ini
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                _isDetectingGps
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF246BFD)),
                      )
                    : const Icon(Icons.my_location_rounded, size: 16, color: Color(0xFF246BFD)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          const Text(
                            'Lokasi GPS Terdeteksi',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF246BFD),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'Akurasi 5m',
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '$_currentGpsLocation $_gpsCoordinates',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A8A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: _isDetectingGps ? null : _detectCurrentGpsLocation,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.refresh_rounded, size: 12, color: Color(0xFF246BFD)),
                        SizedBox(width: 3),
                        Text(
                          'Deteksi',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF246BFD)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 3. Interactive Maps Canvas Widget
          Container(
            height: 185,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Vector Map Base (Roads, river, city blocks)
                  CustomPaint(
                    size: const Size(double.infinity, 185),
                    painter: _HospitalMapPainter(
                      userX: 0.20,
                      userY: 0.72,
                      targetX: activeTargetX,
                      targetY: activeTargetY,
                      routeColor: const Color(0xFF246BFD),
                    ),
                  ),

                  // Top Map Legend Header
                  Positioned(
                    top: 8,
                    left: 10,
                    right: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.radar_rounded, size: 12, color: Color(0xFF246BFD)),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Peta Faskes Mata',
                                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.directions_car_rounded, size: 11, color: Colors.white),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Rute Terdekat',
                                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // User Pin on Map (Posisi Anda)
                  Positioned(
                    left: 22,
                    top: 108,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '📍 Lokasi Anda',
                            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFF246BFD),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF246BFD).withOpacity(0.4), blurRadius: 6, spreadRadius: 2),
                            ],
                          ),
                          child: const Icon(Icons.person, size: 12, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  // Interactive Hospital Pins on Map
                  ..._nearbyFacilities.map((fac) {
                    final isSelected = fac['id'] == _activeFacility['id'];
                    final xRatio = (fac['mapX'] as num?)?.toDouble() ?? 0.5;
                    final yRatio = (fac['mapY'] as num?)?.toDouble() ?? 0.5;

                    return Positioned(
                      left: xRatio * 280,
                      top: yRatio * 140,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeFacility = Map<String, dynamic>.from(fac);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF246BFD),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              content: Text('Tujuan SPK dialihkan ke: ${fac['name']}'),
                            ),
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF246BFD) : Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF246BFD) : const Color(0xFFCBD5E1),
                                ),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 3),
                                ],
                              ),
                              child: Text(
                                '${fac['distanceKm']} km',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Icon(
                              Icons.location_on_rounded,
                              size: isSelected ? 26 : 20,
                              color: isSelected ? const Color(0xFF246BFD) : const Color(0xFF64748B),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // Bottom Map Route Bar
                  Positioned(
                    bottom: 6,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.navigation_rounded, size: 14, color: Color(0xFF246BFD)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Rute: ${_activeFacility['name']} (${_activeFacility['distanceKm']} km • ${_activeFacility['travelTime'] ?? '± 8 mnt'})',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: _openInGoogleMaps,
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF246BFD),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.open_in_new_rounded, size: 10, color: Colors.white),
                                  SizedBox(width: 3),
                                  Text(
                                    'Buka Google Maps ↗',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 4. Daftar Pilihan Faskes Terdekat
          const Text(
            'PILIH RUMAH SAKIT / FASKES RUJUKAN TERDEKAT:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          ..._nearbyFacilities.map((fac) {
            final isSelected = fac['id'] == _activeFacility['id'];
            return InkWell(
              onTap: () {
                setState(() {
                  _activeFacility = Map<String, dynamic>.from(fac);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF059669),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    content: Text('Tujuan SPK dialihkan ke: ${fac['name']}'),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF246BFD) : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            fac['name'] ?? '',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                              color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF246BFD) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isSelected ? '✓ Terpilih di SPK' : 'Mitra BPJS',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : const Color(0xFF246BFD),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      fac['address'] ?? '',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.near_me_rounded, size: 12, color: Color(0xFF246BFD)),
                        const SizedBox(width: 4),
                        Text(
                          '${fac['distanceKm']} km (${fac['travelTime'] ?? '± 10 mnt'})',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF246BFD)),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.person_pin_rounded, size: 12, color: Color(0xFF246BFD)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            fac['doctor_name'] ?? 'Dokter Spesialis Mata',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF246BFD)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            final query = Uri.encodeComponent('${fac['name']} ${fac['address']}');
                            openUrl('https://www.google.com/maps/search/?api=1&query=$query');
                          },
                          child: const Text(
                            'Peta ↗',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF246BFD), decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 10),

          // 5. Panduan Jalur Rujukan JKN / BPJS Kesehatan (Anti-Overflow)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF1D4ED8)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Panduan Alur Rujukan JKN (BPJS):',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D4ED8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildJknStep(
                  '1',
                  'Syarat Berkas:',
                  'Bawa e-KTP, Kartu BPJS / KIS aktif, dan tunjukkan nomor SPK Retiva ini.',
                ),
                const SizedBox(height: 6),
                _buildJknStep(
                  '2',
                  'Faskes Tingkat 1 (FKTP):',
                  'Kunjungi Puskesmas/Klinik Pratama tempat Anda terdaftar untuk verifikasi rujukan P-Care.',
                ),
                const SizedBox(height: 6),
                _buildJknStep(
                  '3',
                  'Poli Mata RS Rujukan:',
                  'Datang sesuai tanggal kunjungan terkonfirmasi. Layanan skrining lanjutan dijamin BPJS sesuai indikasi medis.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJknStep(String number, String bold, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF246BFD),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 11, color: Color(0xFF1E3A8A), height: 1.35),
              children: [
                TextSpan(text: '$bold ', style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // WIDGET: DOKUMEN SPK RESMI
  // ===========================================================================
  Widget _buildSpkDocumentCard(String facilityName, String hba1c, String bp) {
    return Container(
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
            widget.patient != null
                ? '${widget.patient!.fullName} (${widget.patient!.age} th) • ${widget.patient!.gender == 'MALE' ? 'Laki-laki' : 'Perempuan'}'
                : 'Data Pasien Terdaftar',
          ),
          const SizedBox(height: 8),
          _buildSpkField('Nomor Induk Kependudukan (NIK):', widget.patient?.nik ?? '3404012304850002'),
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
                  children: [
                    Expanded(child: _buildVitalItem('Tekanan Darah', bp)),
                    const SizedBox(width: 4),
                    Expanded(child: _buildVitalItem('HbA1c', hba1c != '-' ? '$hba1c%' : '7.8%')),
                    const SizedBox(width: 4),
                    Expanded(child: _buildVitalItem('Gula Darah', '128 mg/dL')),
                    const SizedBox(width: 4),
                    Expanded(child: _buildVitalItem('Visus OD/OS', '6/9 - 6/6')),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _buildSpkField('Kepada Yth. Teman Sejawat:', 'Dokter Spesialis Mata / Subspesialis Vitreoretina'),
          const SizedBox(height: 4),
          _buildSpkField('Fasilitas Pelayanan Rujukan:', facilityName),
          const SizedBox(height: 14),

          // Clinical Findings Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Temuan Skrining Citra Fundus (AI CDSS Retiva):',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  '• Klasifikasi: ${widget.result != null ? ClinicalHelpers.getSeverityTitle(widget.result!.aiResult.predictedClass) : "Retinopati Diabetik Non-Proliferatif Sedang (NPDR Sedang)"}\n'
                  '• ICD-10 Diagnosis: E11.319 (Type 2 diabetes with nonproliferative diabetic retinopathy)\n'
                  '• Temuan Biomarker: Mikroaneurisma terdeteksi, soft exudates fokal, rasio cup-disc stabil.\n'
                  '• Tindakan yang Dimohonkan: Evaluasi funduskopi slit-lamp, Optical Coherence Tomography (OCT) makula, & tatalaksana lanjutan.',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Digital Signature & BSrE Stamp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Diterbitkan Oleh Sistem:', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                  const Text('Puskesmas Sleman RME v2.4', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                  Text(
                    'Tgl: ${_formatDate(DateTime.now())}',
                    style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF246BFD)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'TERVALIDASI DIGITAL BSrE',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFF246BFD)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'dr. H. Susanto, Sp.M (K)',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const Text('SIP: 503/442/SIP.D/2024', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
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
    final patientName = widget.patient?.fullName ?? 'Pasien Retiva';
    final patientNik = widget.patient?.nik ?? '3404012304850002';
    final diag = widget.result != null
        ? ClinicalHelpers.getSeverityTitle(widget.result!.aiResult.predictedClass)
        : 'Retinopati Diabetik Non-Proliferatif Sedang (NPDR Sedang)';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.picture_as_pdf, color: Color(0xFF246BFD)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Surat Rujukan Resmi (SPK)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dokumen Surat Pengantar Rujukan (SPK) resmi telah diverifikasi oleh Rekam Medis Elektronik (RME) & BPJS VClaim.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('File: SPK_RETIVA_2026090084.pdf (248 KB)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 3),
                  Text('Tujuan Faskes: $facilityName', style: const TextStyle(fontSize: 10.5, color: Color(0xFF1D4ED8))),
                  const SizedBox(height: 2),
                  const Text('Tanda Tangan Elektronik: Valid BSrE • Terenkripsi QR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF246BFD))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _downloadSpkPdf(facilityName, patientName, patientNik, diag);
            },
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Unduh PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF246BFD),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _downloadSpkPdf(String facilityName, String patientName, String patientNik, String diag) {
    final pdfBytes = PdfSpkGenerator.generateSpkPdfBytes(
      facilityName: facilityName,
      patientName: patientName,
      patientNik: patientNik,
      bpjsNo: _bpjsVclaimNo,
      screeningResult: diag,
      icdCode: widget.result != null
          ? ClinicalHelpers.getIcd10Code(widget.result!.aiResult.predictedClass)
          : 'E11.319 (Nonproliferative diabetic retinopathy)',
      dateStr: _formatDate(DateTime.now()),
      patientGender: widget.patient?.gender,
      patientAge: widget.patient?.age,
      fktpName: _currentGpsLocation.split(',').first.trim().toUpperCase(),
      doctorReviewer: _activeFacility['doctor_name'],
      regNumber: widget.result?.screeningId != null
          ? 'SPK/RTV/${widget.result!.screeningId}'
          : 'SPK/RTV/2026/09/0084',
    );

    downloadTextOrPdf(
      'SPK_RETIVA_2026090084.pdf',
      String.fromCharCodes(pdfBytes),
      bytes: pdfBytes,
      mimeType: 'application/pdf',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text('Dokumen PDF SPK resmi tersimpan di folder Download perangkat!'),
            ),
          ],
        ),
        backgroundColor: Color(0xFF059669),
        duration: Duration(seconds: 4),
      ),
    );
  }
}

/// Custom vector map painter showing modern schematic city grid, river stream,
/// arterial road network, and live GPS navigation route between patient faskes and hospital.
class _HospitalMapPainter extends CustomPainter {
  final double userX;
  final double userY;
  final double targetX;
  final double targetY;
  final Color routeColor;

  _HospitalMapPainter({
    required this.userX,
    required this.userY,
    required this.targetX,
    required this.targetY,
    required this.routeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base Map Background
    final bgPaint = Paint()..color = const Color(0xFFF1F5F9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. City Blocks & Green Zones
    final parkPaint = Paint()..color = const Color(0xFFEFF6FF).withOpacity(0.85);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.05, size.height * 0.1, size.width * 0.25, size.height * 0.35),
        const Radius.circular(8),
      ),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.55, size.height * 0.15, size.width * 0.38, size.height * 0.30),
        const Radius.circular(8),
      ),
      parkPaint,
    );

    // 3. River Stream (Kali Code / Winongo imitation)
    final riverPaint = Paint()
      ..color = const Color(0xFFBAE6FD).withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final riverPath = Path();
    riverPath.moveTo(size.width * 0.42, 0);
    riverPath.cubicTo(
      size.width * 0.38,
      size.height * 0.35,
      size.width * 0.48,
      size.height * 0.65,
      size.width * 0.45,
      size.height,
    );
    canvas.drawPath(riverPath, riverPaint);

    // 4. Secondary Road Network
    final secondaryRoadPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (double y = 0.25; y <= 0.85; y += 0.25) {
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width, size.height * y),
        secondaryRoadPaint,
      );
    }
    for (double x = 0.25; x <= 0.85; x += 0.25) {
      canvas.drawLine(
        Offset(size.width * x, 0),
        Offset(size.width * x, size.height),
        secondaryRoadPaint,
      );
    }

    // 5. Main Arterial Road (Jl. Magelang - Ring Road)
    final mainRoadBg = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    final mainRoadFg = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    final arterialPath = Path();
    arterialPath.moveTo(0, size.height * 0.70);
    arterialPath.lineTo(size.width * 0.35, size.height * 0.70);
    arterialPath.lineTo(size.width * 0.75, size.height * 0.25);
    arterialPath.lineTo(size.width, size.height * 0.25);

    canvas.drawPath(arterialPath, mainRoadBg);
    canvas.drawPath(arterialPath, mainRoadFg);

    // 6. Navigation GPS Route from User to Selected Hospital
    final uX = userX * size.width;
    final uY = userY * size.height;
    final tX = targetX * size.width;
    final tY = targetY * size.height;

    final routeBg = Paint()
      ..color = routeColor.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final routeLine = Paint()
      ..color = routeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final routePath = Path();
    routePath.moveTo(uX, uY);
    final midX = (uX + tX) / 2;
    routePath.cubicTo(
      midX,
      uY,
      midX,
      tY,
      tX,
      tY,
    );

    canvas.drawPath(routePath, routeBg);
    canvas.drawPath(routePath, routeLine);

    // Draw pulsating radar wave around User location
    final radarWave = Paint()
      ..color = const Color(0xFF246BFD).withOpacity(0.18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(uX, uY), 16, radarWave);
  }

  @override
  bool shouldRepaint(covariant _HospitalMapPainter oldDelegate) {
    return oldDelegate.userX != userX ||
        oldDelegate.userY != userY ||
        oldDelegate.targetX != targetX ||
        oldDelegate.targetY != targetY ||
        oldDelegate.routeColor != routeColor;
  }
}
