import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/models/patient_model.dart';
import '../widgets/brand_header.dart';
import '../widgets/custom_button.dart';
import '../widgets/patient_intake_modal.dart';
import 'quality_scanning_screen.dart';

class UploadFundusScreen extends StatefulWidget {
  final PatientModel? initialPatient;

  const UploadFundusScreen({super.key, this.initialPatient});

  @override
  State<UploadFundusScreen> createState() => _UploadFundusScreenState();
}

class _UploadFundusScreenState extends State<UploadFundusScreen> {
  String _selectedEye = 'OD'; // OD (Mata Kanan) / OS (Mata Kiri)
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  PatientModel? _selectedPatient;
  List<PatientModel> _availablePatients = [];
  bool _isLoadingPatients = false;

  // Test mode switcher for demonstration of the 3 Figma branches
  String _demoBranch = 'NORMAL'; // NORMAL, RETAKE, HUMAN_REVIEW

  @override
  void initState() {
    super.initState();
    _selectedPatient = widget.initialPatient;
    _fetchPatientsFromDb();
  }

  Future<void> _fetchPatientsFromDb() async {
    setState(() => _isLoadingPatients = true);
    try {
      final list = await ApiClient().getPatients();
      if (mounted) {
        setState(() {
          _availablePatients = list;
          _isLoadingPatients = false;
          if (_selectedPatient == null && list.isNotEmpty) {
            _selectedPatient = list.first;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPatients = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e')),
      );
    }
  }

  void _showSelectPatientModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pilih Pasien dari Basis Data (DB)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Data pasien dimuat dinamis dari PostgreSQL.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      PatientIntakeModal.show(context, onPatientCreated: (p) {
                        setState(() {
                          _availablePatients.insert(0, p);
                          _selectedPatient = p;
                        });
                      });
                    },
                    icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                    label: const Text('Pasien Baru', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                ],
              ),
              const Divider(height: 16),
              if (_isLoadingPatients)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_availablePatients.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Tidak ada pasien ditemukan di DB')),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _availablePatients.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final p = _availablePatients[index];
                      final isSelected = p.id == _selectedPatient?.id;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? AppColors.primary : AppColors.primarySurface,
                          child: Icon(
                            Icons.person,
                            color: isSelected ? Colors.white : AppColors.primaryDark,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          p.fullName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'NIK: ${p.nik} • ${p.age} th • HbA1c ${p.diabetesProfile?.lastHbA1c ?? "-"}%',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                            : null,
                        onTap: () {
                          setState(() => _selectedPatient = p);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            BrandHeader(
              showBack: true,
              trailing: IconButton(
                icon: const Icon(Icons.help_outline, color: AppColors.textSecondary, size: 20),
                onPressed: _showQualityGuidanceDialog,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient Demographic Header Bar (Dynamic)
                    _buildPatientHeader(),

                    const SizedBox(height: 20),

                    // Bilateral Eye Selector Tabs (OD vs OS)
                    _buildEyeSelector(),

                    const SizedBox(height: 20),

                    // Fundus Viewfinder & Image Picker
                    _buildFundusViewfinder(),

                    const SizedBox(height: 20),

                    // Protocol Guidance Card
                    _buildProtocolNotice(),

                    const SizedBox(height: 20),

                    // Demo Branch Selector (Simulasi 3 Alur Desain Figma)
                    _buildBranchSelector(),

                    const SizedBox(height: 24),

                    // Proceed Button
                    CustomButton(
                      label: 'Uji Kendali Mutu Citra (Quality Gate)',
                      icon: Icons.biotech,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QualityScanningScreen(
                              imageFile: _imageFile,
                              eyePosition: _selectedEye,
                              demoBranch: _demoBranch,
                              patient: _selectedPatient,
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

  Widget _buildPatientHeader() {
    final patient = _selectedPatient;
    final patientName = patient != null ? '${patient.fullName} (${patient.age} th)' : 'Pilih Pasien Terdaftar...';
    final patientDetails = patient != null
        ? 'NIK: ${patient.nik} • ${patient.diabetesProfile?.diabetesType.replaceAll('_', ' ') ?? "DM"} (HbA1c ${patient.diabetesProfile?.lastHbA1c ?? "-"}%)'
        : 'Memuat data pasien dari basis data PostgreSQL...';

    return InkWell(
      onTap: _showSelectPatientModal,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primarySurface,
              child: Icon(Icons.person, color: AppColors.primaryDark),
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
                          patientName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    patientDetails,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.statusGreenSurface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Ganti',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.statusGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEyeSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedEye = 'OD'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _selectedEye == 'OD' ? AppColors.eyeOD : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedEye == 'OD' ? AppColors.eyeOD : AppColors.border,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'MATA KANAN (OD)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _selectedEye == 'OD' ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Oculus Dexter',
                    style: TextStyle(
                      fontSize: 10,
                      color: _selectedEye == 'OD' ? Colors.white.withOpacity(0.8) : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedEye = 'OS'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _selectedEye == 'OS' ? AppColors.eyeOS : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedEye == 'OS' ? AppColors.eyeOS : AppColors.border,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'MATA KIRI (OS)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _selectedEye == 'OS' ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Oculus Sinister',
                    style: TextStyle(
                      fontSize: 10,
                      color: _selectedEye == 'OS' ? Colors.white.withOpacity(0.8) : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFundusViewfinder() {
    return Container(
      width: double.infinity,
      height: 320,
      decoration: BoxDecoration(
        color: AppColors.cameraViewportBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Selected Image Preview or Viewfinder Placeholder
          if (_imageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                _imageFile!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.remove_red_eye_outlined,
                    size: 40,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Arahkan Kamera Fundus ke Makula',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pastikan bidang pandang FOV >= 45° mencakup diskus optikus',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                ),
              ],
            ),

          // 45-degree Optical Reticle Overlay
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.reticleBorder.withOpacity(0.6),
                width: 1.5,
              ),
            ),
          ),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.reticleBorder.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),

          // Camera / Gallery Action Buttons
          Positioned(
            bottom: 16,
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: const Text('Kamera Optik'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 16, color: Colors.white),
                  label: const Text('Pilih Berkas', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.primaryDark),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Standar Protokol: Citra harus memenuhi ketajaman Laplacian >= 0.40 dan pencahayaan kanal hijau seimbang.',
              style: TextStyle(fontSize: 11, color: AppColors.primaryDark, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchSelector() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text(
                'Simulasi Cabang Alur Figma (Evaluasi Medis):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildBranchChip('NORMAL', 'Lolos Mutu'),
              const SizedBox(width: 8),
              _buildBranchChip('RETAKE', 'Kualitas Buram'),
              const SizedBox(width: 8),
              _buildBranchChip('HUMAN_REVIEW', 'Telaah Dokter'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBranchChip(String branch, String label) {
    final isSelected = _demoBranch == branch;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _demoBranch = branch),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  void _showQualityGuidanceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Panduan Pemotretan Fundus', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: const Text(
          '1. Minta pasien memfokuskan pandangan pada lampu target.\n'
          '2. Pertahankan jarak lensa 1.5 - 2 cm dari kornea mata.\n'
          '3. Hindari getaran tangan saat menekan tombol rana.\n'
          '4. Pastikan makula berada di tengah lingkaran retikel optik.',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
