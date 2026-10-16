import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/services/emergency_location_service.dart';
import '../../data/models/sos_incident_model.dart';
import '../widgets/notification_bell_widget.dart';

enum SosStage {
  countingDown,
  preparingAlert,
  obtainingLocation,
  sendingNotification,
  delivered,
  failed,
  cancelled,
}

class SosActivationScreen extends StatefulWidget {
  final String? patientId;
  final String? patientName;
  final String? patientNik;
  final String? patientPhone;
  final List<String>? initialSymptoms;
  final bool skipCountdown;

  const SosActivationScreen({
    Key? key,
    this.patientId,
    this.patientName,
    this.patientNik,
    this.patientPhone,
    this.initialSymptoms,
    this.skipCountdown = false,
  }) : super(key: key);

  @override
  State<SosActivationScreen> createState() => _SosActivationScreenState();
}

class _SosActivationScreenState extends State<SosActivationScreen>
    with SingleTickerProviderStateMixin {
  SosStage _stage = SosStage.countingDown;
  int _countdownSeconds = 5;
  Timer? _countdownTimer;
  SosIncidentModel? _incident;
  EmergencyLocationResult? _location;
  String _statusMessage = 'Menyiapkan peringatan darurat...';
  List<String> _selectedSymptoms = [];
  bool _canSwallow = true;
  bool _isConscious = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _selectedSymptoms = widget.initialSymptoms != null && widget.initialSymptoms!.isNotEmpty
        ? List.from(widget.initialSymptoms!)
        : ['Hipoglikemia / Lemas Hebat', 'Keringat Dingin', 'Pandangan Kabur Mendadak'];

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.skipCountdown) {
      _executeSosActivation();
    } else {
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds <= 1) {
        timer.cancel();
        _executeSosActivation();
      } else {
        setState(() {
          _countdownSeconds--;
        });
        HapticFeedback.lightImpact();
      }
    });
  }

  void _cancelSosDuringCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _stage = SosStage.cancelled;
    });
    HapticFeedback.mediumImpact();
  }

  Future<void> _executeSosActivation() async {
    _countdownTimer?.cancel();
    HapticFeedback.heavyImpact();

    setState(() {
      _stage = SosStage.preparingAlert;
      _statusMessage = 'Menghubungkan ke pusat koordinasi Retiva SOS...';
    });

    // 1. Obtain GPS coordinates
    setState(() {
      _stage = SosStage.obtainingLocation;
      _statusMessage = 'Mengunci koordinat GPS dan akurasi lokasi...';
    });

    final locationResult = await EmergencyLocationService.getEmergencyLocation();
    _location = locationResult;

    // 2. Submit to backend API & dispatch contact notifications
    setState(() {
      _stage = SosStage.sendingNotification;
      _statusMessage = 'Mengirimkan notifikasi ke kontak darurat & Puskesmas...';
    });

    try {
      final incident = await ApiClient().activateSos(
        patientId: widget.patientId ?? 'patient-demo-01',
        patientName: widget.patientName ?? 'Bpk. Bambang Sutrisno',
        patientNik: widget.patientNik ?? '3471011204650001',
        patientPhone: widget.patientPhone ?? '081223344556',
        symptoms: _selectedSymptoms,
        reportedContext: {
          'conscious': _isConscious,
          'canSwallow': _canSwallow,
          'visionChanges': _selectedSymptoms.any((s) => s.contains('Pandangan') || s.contains('Mata')),
          'additionalNotes': 'Aktivasi tombol darurat mobile Retiva SOS.',
        },
        latitude: locationResult.latitude,
        longitude: locationResult.longitude,
        accuracyMeters: locationResult.accuracyMeters,
        locationStatus: locationResult.statusString,
        locationAddress: locationResult.locationAddress,
        initialTrigger: 'PATIENT_APP_BUTTON',
      );

      setState(() {
        _incident = incident;
        _stage = SosStage.delivered;
        _statusMessage = 'Peringatan Darurat Berhasil Dikirimkan & Terverifikasi!';
      });
      HapticFeedback.vibrate();
    } catch (e) {
      setState(() {
        _stage = SosStage.failed;
        _statusMessage = 'Koneksi terhambat. Silakan gunakan panggilan manual darurat di bawah ini.';
      });
    }
  }

  Future<void> _cancelActiveIncident() async {
    if (_incident != null) {
      await ApiClient().cancelSos(_incident!.id, reason: 'Dibatalkan oleh pasien');
    }
    setState(() {
      _stage = SosStage.cancelled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _stage == SosStage.countingDown
          ? const Color(0xFFFEF2F2)
          : AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Retiva SOS — Bantuan Darurat',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_stage == SosStage.countingDown) {
              _cancelSosDuringCountdown();
            }
            Navigator.of(context).pop();
          },
        ),
        actions: const [
          Center(child: NotificationBellWidget()),
          SizedBox(width: 14),
        ],
      ),
      body: SafeArea(
        child: _stage == SosStage.countingDown
            ? _buildCountdownView()
            : _stage == SosStage.cancelled
                ? _buildCancelledView()
                : _buildActiveSosView(),
      ),
    );
  }

  // View 1: 5-Second Countdown with Big Cancel Button
  Widget _buildCountdownView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: const Text(
              '⚠️ PANGGILAN DARURAT DIKONFIRMASI',
              style: TextStyle(
                color: Color(0xFFB91C1C),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Pulsing Countdown Circular Indicator
          ScaleTransition(
            scale: _pulseAnimation,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 170,
                  height: 170,
                  child: CircularProgressIndicator(
                    value: _countdownSeconds / 5.0,
                    strokeWidth: 10,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
                    backgroundColor: const Color(0xFFFEE2E2),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_countdownSeconds',
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFDC2626),
                        height: 1,
                      ),
                    ),
                    const Text(
                      'DETIK',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF991B1B),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          const Text(
            'Mengirimkan Sinyal SOS Darurat',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Lokasi GPS Anda akan dikirimkan otomatis ke keluarga dan tenaga medis Puskesmas pembina.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 36),

          // Send Now Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _executeSosActivation,
              icon: const Icon(Icons.flash_on, color: Colors.white),
              label: const Text(
                'KIRIM SEKARANG (LEWATI HITUNGAN)',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Cancel Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: _cancelSosDuringCountdown,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF475569),
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Batalkan Peringatan (Salah Tekan)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // View 2: Cancelled Confirmation
  Widget _buildCancelledView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 48, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aktivasi SOS Dibatalkan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tidak ada sinyal darurat yang disiarkan. Anda dapat mengaktifkannya kembali kapan saja jika membutuhkan bantuan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              child: const Text('Kembali ke Beranda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // View 3: Active Incident Telemetry, Stepper, and First Aid Guidance
  Widget _buildActiveSosView() {
    return ListView(
      padding: const EdgeInsets.all(18.0),
      children: [
        // Status Alert Header Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _stage == SosStage.delivered
                ? const Color(0xFFECFDF5)
                : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _stage == SosStage.delivered
                  ? const Color(0xFFA7F3D0)
                  : const Color(0xFFFCA5A5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _stage == SosStage.delivered
                      ? const Color(0xFF10B981)
                      : const Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _stage == SosStage.delivered ? Icons.check : Icons.emergency,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _stage == SosStage.delivered ? 'SOS TERKIRIM & DITERIMA' : 'MEMPROSES PERINGATAN',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _stage == SosStage.delivered ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        fontSize: 13,
                        color: _stage == SosStage.delivered ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Live Stepper Tracker
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tahapan Respon Darurat',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 14),
              _buildStepItem(
                title: '1. Membuat ID Insiden & Timestamp',
                subtitle: _incident != null ? 'ID: ${_incident!.id}' : 'Menghasilkan token terenkripsi...',
                isDone: _stage.index >= SosStage.preparingAlert.index,
                isLoading: _stage == SosStage.preparingAlert,
              ),
              _buildStepItem(
                title: '2. Mengunci Koordinat Lokasi GPS',
                subtitle: _location != null
                    ? '${_location!.locationAddress} (±${_location!.accuracyMeters?.toStringAsFixed(1)}m)'
                    : 'Mendeteksi satelit GPS...',
                isDone: _stage.index >= SosStage.obtainingLocation.index,
                isLoading: _stage == SosStage.obtainingLocation,
              ),
              _buildStepItem(
                title: '3. Transmisi ke Kontak Keluarga',
                subtitle: _incident != null && _incident!.notifications.isNotEmpty
                    ? '${_incident!.notifications.length} kontak terkirim via WhatsApp & SMS'
                    : 'Menyiapkan broadcast darurat...',
                isDone: _stage == SosStage.delivered,
                isLoading: _stage == SosStage.sendingNotification,
              ),
              _buildStepItem(
                title: '4. Dashboard Pemantauan Medis',
                subtitle: 'Sinyal terhubung ke Puskesmas & SPGDT 119.',
                isDone: _stage == SosStage.delivered,
                isLoading: false,
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Strict Safety & First Aid Protocol Guidance
        if (_incident != null && _incident!.triageSummary != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _incident!.oralFoodAllowed ? const Color(0xFFF0F9FF) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _incident!.oralFoodAllowed ? const Color(0xFFBAE6FD) : const Color(0xFFFCA5A5),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _incident!.oralFoodAllowed ? Icons.medical_services_outlined : Icons.warning_amber_rounded,
                      color: _incident!.oralFoodAllowed ? const Color(0xFF0369A1) : const Color(0xFFDC2626),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _incident!.oralFoodAllowed ? 'Panduan Pertolongan Pertama' : 'PERINGATAN KESELAMATAN KRITIS',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: _incident!.oralFoodAllowed ? const Color(0xFF0369A1) : const Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _incident!.triageSummary!,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A), height: 1.4),
                ),
                if (_incident!.recommendedAction != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Instruksi: ${_incident!.recommendedAction!}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.3),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Quick Manual Emergency Hotline Buttons (Fallback)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Layanan Panggilan Darurat Manual',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tekan tombol untuk menelepon langsung bila butuh respon segera:',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Action: trigger phone call 119
                      },
                      icon: const Icon(Icons.phone, size: 18, color: Colors.white),
                      label: const Text('Ambulans 119', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Action: call RS Mata Dr. YAP
                      },
                      icon: const Icon(Icons.local_hospital, size: 18, color: Color(0xFF0D47A1)),
                      label: const Text('RS Mata YAP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0D47A1))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF0D47A1)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Cancel Active Incident Button
        Center(
          child: TextButton.icon(
            onPressed: _cancelActiveIncident,
            icon: const Icon(Icons.cancel_outlined, size: 18, color: Color(0xFF64748B)),
            label: const Text(
              'Batalkan Insiden Darurat (Kondisi Sudah Stabil)',
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStepItem({
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isLoading,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDone
                    ? const Color(0xFF10B981)
                    : isLoading
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : isLoading
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          )
                        : const SizedBox(),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: isDone ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: isDone || isLoading ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
