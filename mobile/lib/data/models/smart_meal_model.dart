class MealIngredient {
  final String name;
  final String quantity;
  final double estCostIdr;

  MealIngredient({
    required this.name,
    required this.quantity,
    required this.estCostIdr,
  });

  factory MealIngredient.fromJson(Map<String, dynamic> json) {
    return MealIngredient(
      name: json['name']?.toString() ?? '',
      quantity: json['quantity']?.toString() ?? '',
      estCostIdr: (json['est_cost_idr'] ?? json['estCostIdr'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'est_cost_idr': estCostIdr,
  };
}

class MealAlternative {
  final String title;
  final double savingsIdr;
  final String description;
  final String substitutionType;

  MealAlternative({
    required this.title,
    required this.savingsIdr,
    required this.description,
    required this.substitutionType,
  });

  factory MealAlternative.fromJson(Map<String, dynamic> json) {
    return MealAlternative(
      title: json['title']?.toString() ?? '',
      savingsIdr: (json['savings_idr'] ?? json['savingsIdr'] ?? 0).toDouble(),
      description: json['description']?.toString() ?? '',
      substitutionType: json['substitution_type'] ?? json['substitutionType'] ?? 'GENERAL',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'savings_idr': savingsIdr,
    'description': description,
    'substitution_type': substitutionType,
  };
}

class MealNutrition {
  final double caloriesKcal;
  final double carbsGrams;
  final double fiberGrams;
  final double proteinGrams;
  final String glycemicIndex;
  final double sodiumMg;

  MealNutrition({
    required this.caloriesKcal,
    required this.carbsGrams,
    required this.fiberGrams,
    required this.proteinGrams,
    required this.glycemicIndex,
    this.sodiumMg = 0,
  });

  factory MealNutrition.fromJson(Map<String, dynamic> json) {
    return MealNutrition(
      caloriesKcal: (json['calories_kcal'] ?? json['caloriesKcal'] ?? 0).toDouble(),
      carbsGrams: (json['carbs_grams'] ?? json['carbsGrams'] ?? 0).toDouble(),
      fiberGrams: (json['fiber_grams'] ?? json['fiberGrams'] ?? 0).toDouble(),
      proteinGrams: (json['protein_grams'] ?? json['proteinGrams'] ?? 0).toDouble(),
      glycemicIndex: json['glycemic_index']?.toString() ?? json['glycemicIndex']?.toString() ?? 'RENDAH',
      sodiumMg: (json['sodium_mg'] ?? json['sodiumMg'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'calories_kcal': caloriesKcal,
    'carbs_grams': carbsGrams,
    'fiber_grams': fiberGrams,
    'protein_grams': proteinGrams,
    'glycemic_index': glycemicIndex,
    'sodium_mg': sodiumMg,
  };
}

class SmartMealItem {
  final String id;
  final String category;
  final String timeRecommendation;
  final String name;
  final String mainDish;
  final List<String> complementaryFoods;
  final String suggestedPortion;
  final List<MealIngredient> ingredients;
  final double estimatedCostIdr;
  final List<MealAlternative> affordableAlternatives;
  final MealNutrition nutrition;
  final Map<String, String> nutritionalImpactExplanation;
  final List<String> personalizationTags;
  bool isEaten;
  String? eatenAt;
  double? postMealGlucoseMgDl;
  Map<String, dynamic>? glucoseEvaluation;

  SmartMealItem({
    required this.id,
    required this.category,
    required this.timeRecommendation,
    required this.name,
    required this.mainDish,
    required this.complementaryFoods,
    required this.suggestedPortion,
    required this.ingredients,
    required this.estimatedCostIdr,
    required this.affordableAlternatives,
    required this.nutrition,
    required this.nutritionalImpactExplanation,
    this.personalizationTags = const [],
    this.isEaten = false,
    this.eatenAt,
    this.postMealGlucoseMgDl,
    this.glucoseEvaluation,
  });

  factory SmartMealItem.fromJson(Map<String, dynamic> json) {
    final compFoods = <String>[];
    if (json['complementary_foods'] is List) {
      for (final item in json['complementary_foods']) {
        compFoods.add(item.toString());
      }
    } else if (json['complementaryFoods'] is List) {
      for (final item in json['complementaryFoods']) {
        compFoods.add(item.toString());
      }
    }

    final ingredientsList = <MealIngredient>[];
    final rawIngredients = json['ingredients'];
    if (rawIngredients is List) {
      for (final item in rawIngredients) {
        if (item is Map<String, dynamic>) {
          ingredientsList.add(MealIngredient.fromJson(item));
        } else if (item is String) {
          ingredientsList.add(MealIngredient(name: item, quantity: 'Secukupnya', estCostIdr: 2000));
        }
      }
    }

    final alternativesList = <MealAlternative>[];
    final rawAlternatives = json['affordable_alternatives'] ?? json['affordableAlternatives'];
    if (rawAlternatives is List) {
      for (final item in rawAlternatives) {
        if (item is Map<String, dynamic>) {
          alternativesList.add(MealAlternative.fromJson(item));
        }
      }
    }

    final explanationMap = <String, String>{};
    final rawExplanation = json['nutritional_impact_explanation'] ?? json['nutritionalImpactExplanation'];
    if (rawExplanation is Map) {
      rawExplanation.forEach((k, v) {
        explanationMap[k.toString()] = v.toString();
      });
    }

    final tags = <String>[];
    final rawTags = json['personalization_tags'] ?? json['personalizationTags'];
    if (rawTags is List) {
      for (final item in rawTags) {
        tags.add(item.toString());
      }
    }

    return SmartMealItem(
      id: json['id']?.toString() ?? 'meal-default',
      category: json['category']?.toString() ?? 'MAKAN_SIANG',
      timeRecommendation: json['time_recommendation']?.toString() ?? json['timeRecommendation']?.toString() ?? '12.30',
      name: json['name']?.toString() ?? 'Menu Sehat Diabetes',
      mainDish: json['main_dish']?.toString() ?? json['mainDish']?.toString() ?? 'Lauk Utama Sehat',
      complementaryFoods: compFoods,
      suggestedPortion: json['suggested_portion']?.toString() ?? json['suggestedPortion']?.toString() ?? 'Piring Model T',
      ingredients: ingredientsList,
      estimatedCostIdr: (json['estimated_cost_idr'] ?? json['estimatedCostIdr'] ?? 10000).toDouble(),
      affordableAlternatives: alternativesList,
      nutrition: json['nutrition'] is Map<String, dynamic>
          ? MealNutrition.fromJson(json['nutrition'])
          : MealNutrition(
              caloriesKcal: 350,
              carbsGrams: 30,
              fiberGrams: 7,
              proteinGrams: 20,
              glycemicIndex: 'RENDAH',
            ),
      nutritionalImpactExplanation: explanationMap,
      personalizationTags: tags,
      isEaten: json['is_eaten'] ?? json['isEaten'] ?? false,
      eatenAt: json['eaten_at']?.toString() ?? json['eatenAt']?.toString(),
      postMealGlucoseMgDl: json['post_meal_glucose_mg_dl'] != null
          ? (json['post_meal_glucose_mg_dl'] as num).toDouble()
          : (json['postMealGlucoseMgDl'] as num?)?.toDouble(),
      glucoseEvaluation: json['glucoseEvaluation'] is Map<String, dynamic> ? json['glucoseEvaluation'] : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'time_recommendation': timeRecommendation,
    'name': name,
    'main_dish': mainDish,
    'complementary_foods': complementaryFoods,
    'suggested_portion': suggestedPortion,
    'ingredients': ingredients.map((i) => i.toJson()).toList(),
    'estimated_cost_idr': estimatedCostIdr,
    'affordable_alternatives': affordableAlternatives.map((a) => a.toJson()).toList(),
    'nutrition': nutrition.toJson(),
    'nutritional_impact_explanation': nutritionalImpactExplanation,
    'personalization_tags': personalizationTags,
    'is_eaten': isEaten,
    'eaten_at': eatenAt,
    'post_meal_glucose_mg_dl': postMealGlucoseMgDl,
  };
}

class PersonalizationFilter {
  double dailyBudget;
  String mealCategory;
  List<String> allergies;
  List<String> dietaryRestrictions;
  List<String> preferredProteins;
  List<String> availableIngredients;
  double? lastGlucoseMgDl;
  String lastGlucoseContext;
  String? clinicianNotes;

  PersonalizationFilter({
    this.dailyBudget = 35000,
    this.mealCategory = 'LUNCH',
    this.allergies = const [],
    this.dietaryRestrictions = const [],
    this.preferredProteins = const ['tempe', 'tahu', 'ikan'],
    this.availableIngredients = const [],
    this.lastGlucoseMgDl,
    this.lastGlucoseContext = 'FASTING',
    this.clinicianNotes,
  });

  Map<String, dynamic> toJson() => {
    'dailyBudget': dailyBudget,
    'mealCategory': mealCategory,
    'allergies': allergies,
    'dietaryRestrictions': dietaryRestrictions,
    'preferredProteins': preferredProteins,
    'availableIngredients': availableIngredients,
    'lastGlucoseMgDl': lastGlucoseMgDl,
    'lastGlucoseContext': lastGlucoseContext,
    'clinicianNotes': clinicianNotes,
  };
}
