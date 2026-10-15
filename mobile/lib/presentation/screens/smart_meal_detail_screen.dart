import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/services/widget_service.dart';
import '../../data/models/smart_meal_model.dart';

class SmartMealDetailScreen extends StatefulWidget {
  final String initialCategory;

  const SmartMealDetailScreen({
    super.key,
    this.initialCategory = 'LUNCH',
  });

  @override
  State<SmartMealDetailScreen> createState() => _SmartMealDetailScreenState();
}

class _SmartMealDetailScreenState extends State<SmartMealDetailScreen> {
  final ApiClient _apiClient = ApiClient();

  late String _selectedCategory;
  bool _isLoading = true;
  String? _errorMessage;
  SmartMealItem? _currentMeal;

  // Personalization State
  double _budget = 35000;
  final List<String> _selectedAllergies = [];
  final List<String> _selectedRestrictions = [];
  final List<String> _selectedProteins = ['tempe', 'tahu', 'ikan'];
  final TextEditingController _ingredientsController = TextEditingController();

  // Post-meal glucose recording
  final TextEditingController _glucoseController = TextEditingController();
  bool _isSavingGlucose = false;
  Map<String, dynamic>? _lastGlucoseEvaluation;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _loadMealRecommendation();
  }

  @override
  void dispose() {
    _ingredientsController.dispose();
    _glucoseController.dispose();
    super.dispose();
  }

  Future<void> _loadMealRecommendation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final meal = await _apiClient.getSmartMealRecommendation('P-001', category: _selectedCategory);
      setState(() {
        _currentMeal = meal;
        _isLoading = false;
      });

      // Synchronize recommendation to native Android widget
      await WidgetService.updateNextMealData(meal);
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat rekomendasi menu: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _markMealAsEaten() async {
    if (_currentMeal == null) return;

    setState(() {
      _currentMeal!.isEaten = true;
      _currentMeal!.eatenAt = DateTime.now().toIso8601String();
    });

    try {
      final res = await _apiClient.markSmartMealAsEaten(
        'P-001',
        _currentMeal!.id,
        _currentMeal!.name,
        category: _currentMeal!.category,
      );

      await WidgetService.updateNextMealData(_currentMeal!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    res['mascotFeedback']?.toString() ?? 'Menu berhasil dicatat sebagai sudah dikonsumsi ✓',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _recordPostMealGlucose() async {
    final valText = _glucoseController.text.trim();
    final bgVal = double.tryParse(valText);
    if (bgVal == null || bgVal <= 30 || bgVal >= 600) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nilai glukosa yang valid (misal: 135 mg/dL)'),
          backgroundColor: AppColors.statusRed,
        ),
      );
      return;
    }

    setState(() => _isSavingGlucose = true);

    try {
      final res = await _apiClient.markSmartMealAsEaten(
        'P-001',
        _currentMeal?.id ?? 'meal-curr',
        _currentMeal?.name ?? 'Menu',
        category: _currentMeal?.category ?? _selectedCategory,
        postMealGlucoseMgDl: bgVal,
      );

      setState(() {
        _isSavingGlucose = false;
        _currentMeal?.postMealGlucoseMgDl = bgVal;
        _currentMeal?.isEaten = true;
        _lastGlucoseEvaluation = res['glucoseEvaluation'] is Map<String, dynamic>
            ? res['glucoseEvaluation']
            : null;
      });

      if (_currentMeal != null) {
        await WidgetService.updateNextMealData(_currentMeal!);
      }

      _glucoseController.clear();
      if (mounted) Navigator.pop(context); // close sheet

      // Show result dialog
      _showGlucoseEvaluationDialog(bgVal);
    } catch (_) {
      setState(() => _isSavingGlucose = false);
    }
  }

  void _showGlucoseEvaluationDialog(double bgVal) {
    String title = 'Evaluasi Gula Darah 2 Jam Pasca Makan';
    String message = '';
    Color color = AppColors.statusGreen;
    IconData icon = Icons.check_circle;

    if (bgVal < 70) {
      title = '⚠️ Tanda Hipoglikemia (Gula Darah Rendah)';
      message = 'Kadar gula darah $bgVal mg/dL berada di bawah batas aman. Segera konsumsi 15-20g karbohidrat cepat serap (seperti 1 sdm madu atau 1/2 gelas teh manis) dan ukur ulang 15 menit lagi.';
      color = AppColors.statusRed;
      icon = Icons.warning_amber_rounded;
    } else if (bgVal > 200) {
      title = '⚠️ Glukosa Pasca Makan Tinggi';
      message = 'Kadar glukosa $bgVal mg/dL di atas target kendali (< 180 mg/dL). Perbanyak minum air putih dan konsultasikan dengan dokter jika tetap tinggi.';
      color = AppColors.statusRed;
      icon = Icons.info_outline;
    } else if (bgVal >= 180) {
      title = 'Sedikit di Atas Target Klinis';
      message = 'Kadar glukosa $bgVal mg/dL sedikit di atas anjuran (< 180 mg/dL). Perhatikan porsi nasi/karbohidrat pada jam makan berikutnya.';
      color = AppColors.statusOrange;
      icon = Icons.info_outline;
    } else {
      title = 'Target Glukosa Tercapai! 🎉';
      message = 'Kadar glukosa $bgVal mg/dL terpantau stabil dalam rentang target optimal pasca makan (< 180 mg/dL). Komposisi serat dan protein terbukti bekerja baik.';
      color = AppColors.statusGreen;
      icon = Icons.verified;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _applyAlternative(MealAlternative alt) async {
    setState(() => _isLoading = true);
    try {
      final swapped = await _apiClient.swapSmartMealAlternative(
        _currentMeal?.id ?? 'meal-curr',
        alt.substitutionType,
        category: _selectedCategory,
      );

      setState(() {
        _currentMeal = swapped;
        _isLoading = false;
      });

      await WidgetService.updateNextMealData(swapped);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.secondary,
            content: Text('Alternatif berhasil diterapkan: ${alt.title} (Hemat Rp ${alt.savingsIdr.toInt()})'),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showPersonalizationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(Icons.tune, color: AppColors.primary, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Personalisasi Menu Sehat',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sesuaikan rekomendasi dengan anggaran, bahan yang tersedia, dan alergi Anda.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 18),

                    // Budget Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Target Anggaran Harian:',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Text(
                          'Rp ${_budget.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ],
                    ),
                    Slider(
                      value: _budget,
                      min: 15000,
                      max: 60000,
                      divisions: 9,
                      activeColor: AppColors.primary,
                      label: 'Rp ${_budget.toInt()}',
                      onChanged: (val) {
                        setSheetState(() => _budget = val);
                        setState(() => _budget = val);
                      },
                    ),

                    const SizedBox(height: 12),
                    const Text(
                      'Alergi & Pantangan Bahan:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Seafood / Ikan', 'Udang', 'Telur', 'Kacang'].map((allergy) {
                        final key = allergy.toLowerCase().split(' ').first;
                        final isSelected = _selectedAllergies.contains(key);
                        return FilterChip(
                          label: Text(allergy, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.textPrimary)),
                          selected: isSelected,
                          selectedColor: AppColors.statusRed,
                          checkmarkColor: Colors.white,
                          onSelected: (val) {
                            setSheetState(() {
                              if (val) {
                                _selectedAllergies.add(key);
                              } else {
                                _selectedAllergies.remove(key);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 14),
                    const Text(
                      'Pembatasan Klinis Dokter:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        {'label': 'Nefropati (Batasi Protein Ginjal)', 'key': 'nefropati'},
                        {'label': 'Rendah Garam (Hipertensi)', 'key': 'rendah_garam'},
                      ].map((item) {
                        final key = item['key']!;
                        final isSelected = _selectedRestrictions.contains(key);
                        return FilterChip(
                          label: Text(item['label']!, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.textPrimary)),
                          selected: isSelected,
                          selectedColor: AppColors.secondary,
                          checkmarkColor: Colors.white,
                          onSelected: (val) {
                            setSheetState(() {
                              if (val) {
                                _selectedRestrictions.add(key);
                              } else {
                                _selectedRestrictions.remove(key);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 14),
                    const Text(
                      'Bahan yang Tersedia di Dapur (Opsional):',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _ingredientsController,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Ada tahu, bayam, telur di kulkas',
                        isDense: true,
                      ),
                    ),

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        setState(() => _isLoading = true);
                        try {
                          final filter = PersonalizationFilter(
                            dailyBudget: _budget,
                            mealCategory: _selectedCategory,
                            allergies: _selectedAllergies,
                            dietaryRestrictions: _selectedRestrictions,
                            availableIngredients: _ingredientsController.text
                                .split(',')
                                .map((s) => s.trim())
                                .where((s) => s.isNotEmpty)
                                .toList(),
                          );
                          final personalized = await _apiClient.personalizeSmartMeal('P-001', filter);
                          setState(() {
                            _currentMeal = personalized;
                            _isLoading = false;
                          });
                          await WidgetService.updateNextMealData(personalized);
                        } catch (e) {
                          setState(() => _isLoading = false);
                        }
                      },
                      child: const Text('Terapkan & Perbarui Rekomendasi'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRecordGlucoseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Catat Gula Darah 2 Jam Pasca Makan',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Target klinis (ADA & PERDAMI): < 180 mg/dL setelah 2 jam makan.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _glucoseController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Kadar Glukosa (mg/dL)',
                  hintText: 'Misal: 138',
                  prefixIcon: Icon(Icons.water_drop, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSavingGlucose ? null : _recordPostMealGlucose,
                child: _isSavingGlucose
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Simpan & Analisis Respon'),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Rekomendasi Menu Cerdas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined, color: AppColors.primary),
            tooltip: 'Personalisasi Menu',
            onPressed: _showPersonalizationSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 12),
                  Text('Menyusun menu ramah glukosa...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off, size: 54, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadMealRecommendation,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final meal = _currentMeal!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Category Selector
          _buildCategoryTabs(),
          const SizedBox(height: 14),

          // 2. Mascot Guidance Banner
          _buildMascotBanner(),
          const SizedBox(height: 14),

          // 3. Main Dish Card
          _buildMainDishCard(meal),
          const SizedBox(height: 14),

          // 4. "Isi Piringku / Piring Model T" Balance Visualizer
          _buildPlateBreakdownCard(meal),
          const SizedBox(height: 14),

          // 5. Nutritional Impact Explanation Card
          _buildNutritionalImpactCard(meal),
          const SizedBox(height: 14),

          // 6. Ingredients & Estimated Cost List
          _buildIngredientsCard(meal),
          const SizedBox(height: 14),

          // 7. Affordable Alternatives Card
          if (meal.affordableAlternatives.isNotEmpty) ...[
            _buildAlternativesCard(meal),
            const SizedBox(height: 14),
          ],

          // 8. Action Buttons (Tandai Sudah Makan & Catat GD2PP)
          _buildActionSection(meal),
          const SizedBox(height: 16),

          // 9. Clinical Disclaimer
          _buildDisclaimerCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = [
      {'label': 'Sarapan', 'value': 'BREAKFAST'},
      {'label': 'Makan Siang', 'value': 'LUNCH'},
      {'label': 'Makan Malam', 'value': 'DINNER'},
      {'label': 'Camilan', 'value': 'SNACK'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                cat['label']!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
              ),
              onSelected: (val) {
                if (val) {
                  setState(() => _selectedCategory = cat['value']!);
                  _loadMealRecommendation();
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMascotBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo! Maskot Retiva Menemani Makan Sehat 💙',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Menu ini dirancang dengan Indeks Glikemik Rendah dan komposisi serat tinggi untuk menahan lonjakan glukosa darah pasca makan.',
                  style: TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF1E40AF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainDishCard(SmartMealItem meal) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${meal.category} · ${meal.timeRecommendation}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              if (meal.isEaten)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check, size: 14, color: Color(0xFF15803D)),
                      SizedBox(width: 4),
                      Text(
                        'Sudah Dikonsumsi',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            meal.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.payments_outlined, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                'Estimasi Biaya: Rp ${meal.estimatedCostIdr.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Pasar Lokal', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4 Nutrition Badges
          Row(
            children: [
              _buildNutrChip('Kalori', '${meal.nutrition.caloriesKcal.toInt()} kkal', const Color(0xFFEFF6FF), AppColors.primary),
              const SizedBox(width: 8),
              _buildNutrChip('Karbohidrat', '${meal.nutrition.carbsGrams.toInt()}g', const Color(0xFFF0FDF4), const Color(0xFF16A34A)),
              const SizedBox(width: 8),
              _buildNutrChip('Serat', '${meal.nutrition.fiberGrams}g', const Color(0xFFFEF3C7), const Color(0xFFD97706)),
              const SizedBox(width: 8),
              _buildNutrChip('Protein', '${meal.nutrition.proteinGrams.toInt()}g', const Color(0xFFF5F3FF), const Color(0xFF7C3AED)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrChip(String label, String value, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.85))),
          ],
        ),
      ),
    );
  }

  Widget _buildPlateBreakdownCard(SmartMealItem meal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_outline, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Komposisi "Piring Model T" (Kemenkes)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            meal.suggestedPortion,
            style: const TextStyle(fontSize: 13, height: 1.35, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          _buildPortionRow('Lauk Utama', meal.mainDish, Icons.lunch_dining, AppColors.primary),
          const SizedBox(height: 8),
          ...meal.complementaryFoods.map(
            (food) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _buildPortionRow('Lauk Pendamping / Sayur', food, Icons.eco, const Color(0xFF16A34A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortionRow(String type, String name, IconData icon, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontFamily: 'Inter'),
              children: [
                TextSpan(text: '$type: ', style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: name),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionalImpactCard(SmartMealItem meal) {
    final exp = meal.nutritionalImpactExplanation;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Penjelasan Dampak Nutrisi Bagi Glukosa',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (exp['carbohydrate_impact'] != null)
            _buildExplanationItem('🌾 Karbohidrat Terkontrol', exp['carbohydrate_impact']!),
          if (exp['fiber_impact'] != null)
            _buildExplanationItem('🥦 Peran Serat Pangan', exp['fiber_impact']!),
          if (exp['protein_vascular_impact'] != null)
            _buildExplanationItem('🛡️ Protein & Mikrovaskular Retina', exp['protein_vascular_impact']!),
          if (exp['glucose_stability_summary'] != null)
            _buildExplanationItem('⏱️ Kestabilan 2 Jam Pasca Makan', exp['glucose_stability_summary']!),
        ],
      ),
    );
  }

  Widget _buildExplanationItem(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 2),
          Text(body, style: const TextStyle(fontSize: 12, height: 1.35, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildIngredientsCard(SmartMealItem meal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shopping_basket_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Daftar Bahan & Estimasi Harga',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Estimasi harga bahan mentah di pasar tradisional lokal:',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          ...meal.ingredients.map(
            (ing) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ing.name,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ),
                  Text(
                    ing.quantity,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Rp ${ing.estCostIdr.toInt()}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativesCard(SmartMealItem meal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.swap_horiz, color: AppColors.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                'Alternatif Ekonomis & Substitusi Bahan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Dapat diganti tanpa mengurangi kualitas nutrisi dan kontrol gula darah:',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          ...meal.affordableAlternatives.map(
            (alt) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          alt.title,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ),
                      if (alt.savingsIdr > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Hemat Rp ${alt.savingsIdr.toInt()}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(alt.description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => _applyAlternative(alt),
                      icon: const Icon(Icons.check, size: 14),
                      label: const Text('Ganti ke Menu Ini', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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

  Widget _buildActionSection(SmartMealItem meal) {
    return Column(
      children: [
        // Button: Tandai Sudah Makan
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: meal.isEaten ? const Color(0xFF15803D) : AppColors.primary,
            minimumSize: const Size.fromHeight(50),
          ),
          onPressed: meal.isEaten ? null : _markMealAsEaten,
          icon: Icon(meal.isEaten ? Icons.check_circle : Icons.check, size: 18),
          label: Text(meal.isEaten ? 'Sudah Dikonsumsi ✓' : 'Tandai Sudah Makan'),
        ),
        const SizedBox(height: 10),

        // Button: Catat Gula Darah 2 Jam Pasca Makan (GD2PP)
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.4),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
          onPressed: _showRecordGlucoseSheet,
          icon: const Icon(Icons.bloodtype_outlined, size: 18),
          label: Text(
            meal.postMealGlucoseMgDl != null
                ? 'Gula Darah 2 Jam: ${meal.postMealGlucoseMgDl!.toInt()} mg/dL (Ubah)'
                : 'Catat Gula Darah 2 Jam Pasca Makan',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildDisclaimerCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 18, color: AppColors.textMuted),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Peringatan Keselamatan: Nilai gizi dan perkiraan harga bersifat estimasi. '
              'Makanan ramah diabetes membantu mengontrol kadar glukosa, namun tidak menyembuhkan retinopati diabetik dan '
              'tidak menggantikan petunjuk obat maupun resep insulin dari dokter Anda.',
              style: TextStyle(fontSize: 11, height: 1.35, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
