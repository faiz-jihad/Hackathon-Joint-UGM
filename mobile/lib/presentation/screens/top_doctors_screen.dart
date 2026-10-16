import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import 'referral_letter_screen.dart';
import '../widgets/notification_bell_widget.dart';

class TopDoctorsScreen extends StatefulWidget {
  final String? initialQuery;
  const TopDoctorsScreen({super.key, this.initialQuery});

  @override
  State<TopDoctorsScreen> createState() => _TopDoctorsScreenState();
}

class _TopDoctorsScreenState extends State<TopDoctorsScreen> {
  final ApiClient _apiClient = ApiClient();
  String _selectedCategory = 'Semua';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _doctors = [];

  final List<Map<String, dynamic>> _categories = [
    {'title': 'Semua', 'icon': Icons.medical_services_outlined},
    {'title': 'Vitreoretina', 'icon': Icons.remove_red_eye_outlined},
    {'title': 'Endokrin', 'icon': Icons.bloodtype_outlined},
    {'title': 'Glaukoma', 'icon': Icons.visibility_outlined},
    {'title': 'Umum', 'icon': Icons.local_hospital_outlined},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }
    _fetchDoctorsFromDb();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctorsFromDb() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dbDoctors = await _apiClient.getTopDoctors();
      if (mounted) {
        setState(() {
          _doctors = dbDoctors;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat dokter dari database: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredDoctors {
    return _doctors.where((doc) {
      final cat = doc['category']?.toString().toLowerCase() ?? '';
      final matchesCategory = _selectedCategory == 'Semua' || cat == _selectedCategory.toLowerCase();
      final query = _searchController.text.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          (doc['name']?.toString().toLowerCase().contains(query) ?? false) ||
          (doc['specialty']?.toString().toLowerCase().contains(query) ?? false) ||
          (doc['hospital']?.toString().toLowerCase().contains(query) ?? false);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _showAppointmentDialog(Map<String, dynamic> doctor) {
    int selectedDateSlot = 0; // 0: Hari ini, 1: Besok, 2: Lusa
    int selectedTimeSlot = 0; // 0: Pagi, 1: Siang, 2: Sore
    bool attachRetinaReport = true;
    bool attachGlucoseData = true;
    final notesController = TextEditingController();

    final dateOptions = [
      {'day': 'Hari Ini', 'date': '16 Okt'},
      {'day': 'Besok', 'date': '17 Okt'},
      {'day': 'Lusa', 'date': '18 Okt'},
    ];

    final timeSlots = [
      '09:00 - 11:30 WIB (Pagi)',
      '13:00 - 15:30 WIB (Siang)',
      '16:00 - 18:00 WIB (Sore)',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Doctor Profile Header
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                          ),
                          child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctor['name'] ?? 'dr. Spesialis',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                doctor['specialty'] ?? 'Spesialis Mata',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFDBEAFE)),
                                ),
                                child: Text(
                                  doctor['hospital'] ?? 'RS Mata Rujukan Nasional',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(color: Color(0xFFF1F5F9), height: 1),
                    const SizedBox(height: 16),

                    // 1. Jenis Layanan Konsultasi: Hanya Tatap Muka di RS
                    const Text(
                      'Jenis Layanan Konsultasi',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x08000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_hospital_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Tatap Muka di Poliklinik RS',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
                                  ],
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Pemeriksaan slit-lamp & funduskopi langsung di poliklinik mata',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Pilih Hari & Sesi Waktu
                    const Text(
                      'Pilih Hari & Waktu Konsultasi',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(dateOptions.length, (idx) {
                        final isSelected = selectedDateSlot == idx;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: idx < 2 ? 8 : 0),
                            child: InkWell(
                              onTap: () => setModalState(() => selectedDateSlot = idx),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      dateOptions[idx]['day']!,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      dateOptions[idx]['date']!,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isSelected ? Colors.white.withOpacity(0.9) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    // Sesi Jam Dropdown / Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(timeSlots.length, (idx) {
                        final isSelected = selectedTimeSlot == idx;
                        return InkWell(
                          onTap: () => setModalState(() => selectedTimeSlot = idx),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              timeSlots[idx],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.primary : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // 3. Lampiran Medis Otomatis
                    const Text(
                      'Sinkronisasi Rekam Medis Otomatis',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => setModalState(() => attachRetinaReport = !attachRetinaReport),
                            child: Row(
                              children: [
                                Icon(
                                  attachRetinaReport ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                  color: attachRetinaReport ? AppColors.primary : const Color(0xFF94A3B8),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Lampirkan Hasil Skrining Retina AI & Grad-CAM Terakhir',
                                    style: TextStyle(fontSize: 11.5, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 14, color: Color(0xFFE2E8F0)),
                          InkWell(
                            onTap: () => setModalState(() => attachGlucoseData = !attachGlucoseData),
                            child: Row(
                              children: [
                                Icon(
                                  attachGlucoseData ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                  color: attachGlucoseData ? AppColors.primary : const Color(0xFF94A3B8),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Sertakan Catatan Gula Darah Terakhir (90 mg/dL Normal Puasa)',
                                    style: TextStyle(fontSize: 11.5, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4. Catatan Keluhan Pasien
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Tuliskan keluhan penglihatan (contoh: mata kabur, ada bintik melayang)...',
                        hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ReferralLetterScreen()),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Rujukan BPJS', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showBookingConfirmedDialog(
                                doctor: doctor,
                                serviceName: 'Tatap Muka di Poliklinik RS',
                                scheduleInfo: '${dateOptions[selectedDateSlot]['day']}, ${dateOptions[selectedDateSlot]['date']} • ${timeSlots[selectedTimeSlot]}',
                                patientNotes: notesController.text.trim(),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Konfirmasi Reservasi',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showBookingConfirmedDialog({
    required Map<String, dynamic> doctor,
    required String serviceName,
    required String scheduleInfo,
    required String patientNotes,
  }) {
    showDialog(
      context: context,
      builder: (dlgCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: 14),
              const Text(
                'Reservasi Berhasil Terjadwal!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Nomor antrean resmi telah diterbitkan & data terhubung ke Rekam Medis SatuSehat Kemenkes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Nomor Antrean', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: const Text(
                            'NO. A-04',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      doctor['name'] ?? 'dr. Spesialis Mata',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      doctor['hospital'] ?? 'RS Mata Rujukan',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(scheduleInfo, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.medical_information_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(serviceName, style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Interactive Consultation Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(dlgCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF059669),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 4),
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Antrean ${doctor['name']} berhasil dikonfirmasi ke SatuSehat!',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.confirmation_number_rounded, size: 16, color: Colors.white),
                  label: const Text('Simpan Nomor Antrean Faskes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dlgCtx),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  child: const Text('Selesai', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Appointment',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        actions: const [
          Center(child: NotificationBellWidget()),
          SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDoctorsFromDb,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CareSync Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search for doctors and specialists...',
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                    prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                    suffixIcon: Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Circular Category Avatars (CareSync style)
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (ctx, idx) {
                    final cat = _categories[idx];
                    final isSelected = cat['title'] == _selectedCategory;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat['title']),
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? AppColors.primary : Colors.white,
                              border: Border.all(
                                color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? AppColors.primary.withOpacity(0.3)
                                      : const Color(0x06000000),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              cat['icon'] as IconData,
                              color: isSelected ? Colors.white : AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat['title'] as String,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.primary : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // Section: Top Doctors
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Top Doctors',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    '${_filteredDoctors.length} Spesialis',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Doctors List (Dynamic from Database)
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_filteredDoctors.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(Icons.person_search_rounded, size: 48, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage ??
                            'Tidak ada dokter spesialis untuk kategori "$_selectedCategory" di database.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _fetchDoctorsFromDb,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Muat Ulang Database'),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredDoctors.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final doc = _filteredDoctors[idx];
                    return _buildDoctorCard(doc);
                  },
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Doctor Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD6E4FF), width: 1.2),
            ),
            child: const Center(
              child: Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
            ),
          ),
          const SizedBox(width: 10),

          // Doctor Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  doc['name'] ?? 'dr. Spesialis',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  doc['specialty'] ?? 'Spesialis Mata',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        doc['status'] ?? 'Tersedia Hari Ini',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Reservasi Button (CareSync blue pill)
          ElevatedButton(
            onPressed: () => _showAppointmentDialog(doc),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Reservasi',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
