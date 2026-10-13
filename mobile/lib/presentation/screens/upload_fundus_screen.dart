import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/patient_model.dart';
import 'quality_scanning_screen.dart';

/// Screens 02 & 03: 02. Upload I & 03. Upload II (Figma Frames 28:189 & 28:375)
/// Authoritative 1:1 Implementation matching Figma source of truth.
class UploadFundusScreen extends StatefulWidget {
  final PatientModel? initialPatient;

  const UploadFundusScreen({super.key, this.initialPatient});

  @override
  State<UploadFundusScreen> createState() => _UploadFundusScreenState();
}

class _UploadFundusScreenState extends State<UploadFundusScreen> {
  final String _selectedEye = 'OD'; // OD (Mata Kanan)
  File? _imageFile;
  Uint8List? _imageBytes;
  String _fileName = 'fundus_024.jpg';
  String _fileSize = '2.4 MB';
  bool _hasSelectedImage = false;

  final ImagePicker _picker = ImagePicker();
  PatientModel? _selectedPatient;

  @override
  void initState() {
    super.initState();
    _selectedPatient = widget.initialPatient;
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
        final bytes = await picked.readAsBytes();
        final sizeKb = bytes.lengthInBytes / 1024;
        final sizeText = sizeKb > 1024
            ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
            : '${sizeKb.toStringAsFixed(0)} KB';

        setState(() {
          _imageBytes = bytes;
          _fileName = picked.name.isNotEmpty ? picked.name : 'fundus_${DateTime.now().millisecondsSinceEpoch % 1000}.jpg';
          _fileSize = sizeText;
          _hasSelectedImage = true;
          if (!kIsWeb) {
            _imageFile = File(picked.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e')),
      );
    }
  }

  void _useSampleFigmaImage() {
    setState(() {
      _hasSelectedImage = true;
      _fileName = 'fundus_024.jpg';
      _fileSize = '2.4 MB';
      _imageBytes = null;
      _imageFile = null;
    });
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pilih Sumber Foto Fundus',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.figmaBlue,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.figmaBlueSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.photo_library_outlined, color: AppColors.figmaBlue),
                  ),
                  title: const Text(
                    'Galeri Perangkat',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: const Text('Pilih foto fundus yang tersimpan di memori', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.figmaBlueSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: AppColors.figmaBlue),
                  ),
                  title: const Text(
                    'Kamera Fundus Portabel',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: const Text('Ambil foto langsung via lensa adapter fundus', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image_search, color: AppColors.figmaBlueDark),
                  ),
                  title: const Text(
                    'Gunakan Sampel Figma (fundus_024.jpg)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.figmaBlueDark),
                  ),
                  subtitle: const Text('Sampel citra retina terverifikasi standar Figma', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _useSampleFigmaImage();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _proceedToQualityScanning() {
    if (!_hasSelectedImage) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QualityScanningScreen(
          imageFile: _imageFile,
          imageBytes: _imageBytes,
          eyePosition: _selectedEye,
          demoBranch: 'NORMAL',
          patient: _selectedPatient,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Back Button (Figma Node 28:351 & 28:438)
            _buildTopBar(),

            // Main Scrollable Inner Page Content (Figma Node 28:190 & 28:376)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stepper Breadcrumb: Langkah 1 dari 4 (Figma Node 28:482 & 133:13)
                    _buildStepperBreadcrumb(),

                    const SizedBox(height: 16),

                    // Title & Description: Pilih Foto Retina (Figma Node 28:294 & 28:381)
                    _buildTitleSection(),

                    const SizedBox(height: 16),

                    // Upload Container (Toggled State: Dropzone vs Selected Preview)
                    if (!_hasSelectedImage)
                      _buildUploadDropzoneBox()
                    else
                      _buildSelectedPhotoPreviewBox(),

                    const SizedBox(height: 24),

                    // Quality Guidelines Section: PANDUAN KUALITAS RETIVA (Figma Node 79:542 & 79:623)
                    _buildQualityGuidanceSection(),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Persistent Bottom CTA Button (Figma Node 129:2 & 85:692)
            _buildBottomCtaArea(),
          ],
        ),
      ),
    );
  }

  /// Top Bar with Back Button (Figma Node 28:351 / 28:438)
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Circular Back Button (32x32 rounded 9999px)
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(9999),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 14,
                color: AppColors.figmaBlue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Heading 2: Upload Foto Retina
          const Text(
            'Upload Foto Retina',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.figmaBlue,
            ),
          ),
        ],
      ),
    );
  }

  /// Stepper Breadcrumb: Langkah 1 dari 4 (Figma Node 28:482 & 133:13)
  Widget _buildStepperBreadcrumb() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            // Circular Step 1 Badge (24x24 rounded 9999px, #0D47A1)
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.figmaBlue,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '1',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Langkah 1 dari 4: Unggah Berkas',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.figmaBlueDark,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),

        // 4 Step Pills (Active 24px, Inactive 8px each)
        Row(
          children: [
            Container(
              width: 24,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.figmaBlue,
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFD8E3FB),
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFD8E3FB),
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFD8E3FB),
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Title Section: Pilih Foto Retina (Figma Node 28:294 & 28:381)
  Widget _buildTitleSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Foto Retina',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.figmaBlue,
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Pilih foto fundus/retina untuk memulai pemeriksaan otomatis.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Color(0xFF475569),
            height: 1.33,
          ),
        ),
      ],
    );
  }

  /// State 1: Upload Interactive Dropzone Box (Figma Frame 28:189 / Node 28:299)
  Widget _buildUploadDropzoneBox() {
    return InkWell(
      onTap: _showImageSourcePicker,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2196F3), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000), // rgba(0,0,0,0.05)
              offset: Offset(0, 1),
              blurRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(2),
        child: Container(
          height: 265,
          decoration: BoxDecoration(
            color: const Color(0x4DD1E4FF), // rgba(209,228,255,0.3)
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Concentric Pulse Retinal Scanner Icon (64x64) (Figma Node 28:515)
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0D000000),
                      offset: Offset(0, 1),
                      blurRadius: 1,
                    ),
                    BoxShadow(
                      color: Color(0x3333A0FD),
                      offset: Offset(0, 0),
                      blurRadius: 12,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.center_focus_strong_outlined,
                    color: AppColors.figmaBlue,
                    size: 28,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Supported formats label (Figma Node 28:500)
              const Text(
                'Mendukung format JPG, JPEG, PNG (Maks 15MB)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.figmaTextBody,
                ),
              ),

              const SizedBox(height: 16),

              // Visual CTA Button: Pilih dari Galeri (Figma Node 28:501)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.figmaBlue,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      offset: Offset(0, 1),
                      blurRadius: 1,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Pilih dari Galeri',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// State 2: Selected Photo Preview Box (Figma Frame 28:375 / Node 28:386)
  Widget _buildSelectedPhotoPreviewBox() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2196F3), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000), // rgba(0,0,0,0.05)
            offset: Offset(0, 1),
            blurRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Foto Sudah Diupload + Filename badge (Figma Node 28:387)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Color(0xFF2196F3),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Foto Sudah Diupload',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.figmaBlueSurface,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  _fileName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Aspect Ratio 16:9 Preview Photo Box (Figma Node 28:394)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Actual Image Rendering
                  if (_imageBytes != null)
                    Image.memory(_imageBytes!, fit: BoxFit.cover)
                  else if (_imageFile != null && !kIsWeb)
                    Image.file(_imageFile!, fit: BoxFit.cover)
                  else
                    Image.asset('assets/images/upload_preview_sample.png', fit: BoxFit.cover),

                  // Bottom Gradient Overlay with File Size (Figma Node 28:396)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0x99000000), // rgba(0,0,0,0.6)
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.remove_red_eye_outlined,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Citra Siap Dianalisis',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _fileSize,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
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

          // Action Button: Ganti Foto Lain (Figma Node 28:405)
          InkWell(
            onTap: _showImageSourcePicker,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.refresh,
                    size: 15,
                    color: Color(0xFF475569),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Ganti Foto Lain',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Clinical Quality Guidelines Section: PANDUAN KUALITAS RETIVA (Figma Node 79:542 & 79:623)
  Widget _buildQualityGuidanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row (Figma Node 79:544)
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PANDUAN KUALITAS RETIVA',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF434652),
                letterSpacing: 0.55,
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 13,
                  color: AppColors.figmaBlueDark,
                ),
                SizedBox(width: 4),
                Text(
                  'Standar Klinis',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.figmaBlueDark,
                    letterSpacing: 0.44,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Quality Guide White Card with 3 Dividers (Figma Node 79:551)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000), // rgba(0,0,0,0.05)
                offset: Offset(0, 1),
                blurRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              // Item 1: Pencahayaan Retina Merata (Figma Node 79:552)
              _buildGuidelineRow(
                number: '1',
                title: 'Pencahayaan Retina Merata',
                description:
                    'Hindari pantulan silau (glare) putih berlebihan atau area gelap akibat pupil yang belum teriluminasi penuh.',
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Color(0xFFD9EBF5), height: 1),
              ),

              // Item 2: Fokus Tajam Diskus & Makula (Figma Node 79:562)
              _buildGuidelineRow(
                number: '2',
                title: 'Fokus Tajam Diskus & Makula',
                description:
                    'Pembuluh darah vaskular temporal dan batas diskus optikus harus terdefinisi jelas tanpa blur gerakan.',
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Color(0xFFD9EBF5), height: 1),
              ),

              // Item 3: Bebas Obstruksi Mata (Figma Node 79:572)
              _buildGuidelineRow(
                number: '3',
                title: 'Bebas Obstruksi Mata',
                description:
                    'Pastikan tidak ada artefak bulu mata, bayangan kelopak mata, atau kabut kelembapan pada lensa adapter.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuidelineRow({
    required String number,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Number Badge (32x32 rounded 9999px, #DFF1FB background, #003178 text)
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFFDFF1FB),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.figmaBlueDark,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Text Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.figmaTextHeading,
                  letterSpacing: 0.26,
                  height: 1.23,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.figmaTextBody,
                  height: 1.38,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Persistent Bottom CTA Button: Periksa Kualitas Foto (Figma Node 129:2 & 85:692)
  Widget _buildBottomCtaArea() {
    final isEnabled = _hasSelectedImage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: isEnabled ? _proceedToQualityScanning : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEnabled ? AppColors.figmaBlue : const Color(0xFF94A3B8),
            foregroundColor: Colors.white,
            elevation: isEnabled ? 2 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 18,
                color: isEnabled ? Colors.white : const Color(0xFF475569),
              ),
              const SizedBox(width: 8),
              Text(
                'Periksa Kualitas Foto',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isEnabled ? Colors.white : const Color(0xFF475569),
                  letterSpacing: 0.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
