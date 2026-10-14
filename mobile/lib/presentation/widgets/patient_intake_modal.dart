import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/models/patient_model.dart';

class PatientIntakeModal extends StatefulWidget {
  final Function(PatientModel) onPatientCreated;

  const PatientIntakeModal({super.key, required this.onPatientCreated});

  static Future<void> show(BuildContext context, {required Function(PatientModel) onPatientCreated}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PatientIntakeModal(onPatientCreated: onPatientCreated),
    );
  }

  @override
  State<PatientIntakeModal> createState() => _PatientIntakeModalState();
}

class _PatientIntakeModalState extends State<PatientIntakeModal> {
  final _formKey = GlobalKey<FormState>();

  final _nikController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _hba1cController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();

  DateTime _birthDate = DateTime(1980, 1, 1);
  String _gender = 'MALE';
  String _diabetesType = 'TYPE_2';
  final int _yearOfDiagnosis = DateTime.now().year - 3;
  String _currentTreatment = 'ORAL_MEDICATION';
  bool _isSubmitting = false;

  Future<void> _submitPatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final newPatient = await ApiClient().createPatient(
        nik: _nikController.text.trim(),
        fullName: _nameController.text.trim(),
        birthDate: _birthDate.toIso8601String().split('T').first,
        gender: _gender,
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        diabetesType: _diabetesType,
        yearOfDiagnosis: _yearOfDiagnosis,
        currentTreatment: _currentTreatment,
        lastHbA1c: double.tryParse(_hba1cController.text) ?? 8.0,
        systolicBp: int.tryParse(_systolicController.text) ?? 120,
        diastolicBp: int.tryParse(_diastolicController.text) ?? 80,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (newPatient != null) {
          widget.onPatientCreated(newPatient);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pasien ${newPatient.fullName} (NIK: ${newPatient.nik}) berhasil didaftarkan ke basis data!'),
              backgroundColor: AppColors.statusGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Galat: $e'), backgroundColor: AppColors.statusRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_add_alt_1, color: AppColors.primaryDark, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pendaftaran Pasien DM Baru',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Intake Rekam Medis Elektronik FKTP (Permenkes No. 24/2022)',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 24),

          // Form Body
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NIK Field
                    const Text('Nomor Induk Kependudukan (NIK 16 Digit) *',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nikController,
                      keyboardType: TextInputType.number,
                      maxLength: 16,
                      decoration: InputDecoration(
                        hintText: 'Contoh: 3404015508750001',
                        prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        counterText: '',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().length != 16) {
                          return 'NIK harus tepat 16 digit angka sesuai KTP.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Full Name
                    const Text('Nama Lengkap Pasien *',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Bapak Hendro Prasetyo',
                        prefixIcon: const Icon(Icons.person_outline, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nama lengkap wajib diisi.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Gender & Birth Date
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Jenis Kelamin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _gender,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'MALE', child: Text('Laki-laki', style: TextStyle(fontSize: 13))),
                                  DropdownMenuItem(value: 'FEMALE', child: Text('Perempuan', style: TextStyle(fontSize: 13))),
                                ],
                                onChanged: (v) => setState(() => _gender = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tahun Lahir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _birthDate,
                                    firstDate: DateTime(1930),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) setState(() => _birthDate = picked);
                                },
                                icon: const Icon(Icons.calendar_today, size: 16),
                                label: Text('${_birthDate.year} (${DateTime.now().year - _birthDate.year} th)'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Diabetes Metabolic Section Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.biotech, size: 16, color: AppColors.secondary),
                          SizedBox(width: 8),
                          Text(
                            'Profil Metabolik Diabetes Melitus (DM)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // DM Type & Treatment
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tipe Diabetes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _diabetesType,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'TYPE_2', child: Text('DM Tipe 2', style: TextStyle(fontSize: 13))),
                                  DropdownMenuItem(value: 'TYPE_1', child: Text('DM Tipe 1', style: TextStyle(fontSize: 13))),
                                  DropdownMenuItem(value: 'GESTATIONAL', child: Text('Gestasional', style: TextStyle(fontSize: 13))),
                                ],
                                onChanged: (v) => setState(() => _diabetesType = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Terapi Aktif', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _currentTreatment,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'ORAL_MEDICATION', child: Text('OHO / Metformin', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'INSULIN', child: Text('Insulin', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'COMBINATION', child: Text('Kombinasi OHO+Insulin', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'DIET_AND_LIFESTYLE', child: Text('Gaya Hidup', style: TextStyle(fontSize: 12))),
                                ],
                                onChanged: (v) => setState(() => _currentTreatment = v!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // HbA1c & Blood Pressure
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Nilai HbA1c (%) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _hba1cController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: '8.2',
                                  suffixText: '%',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tensi Sistolik', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _systolicController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '130',
                                  suffixText: 'mmHg',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Diastolik', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _diastolicController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '85',
                                  suffixText: 'mmHg',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Submit Button (Medica Capsule Style)
                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: _isSubmitting ? null : AppColors.primaryButtonShadow,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitPatient,
                        icon: _isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                            : const Icon(Icons.check_circle_outline, size: 20),
                        label: Text(
                          _isSubmitting ? 'Menyimpan ke Basis Data...' : 'Simpan Rekam Medis Pasien',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'Inter'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
