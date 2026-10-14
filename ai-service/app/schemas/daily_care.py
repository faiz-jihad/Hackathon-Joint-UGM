from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field

class DailyCheckInRequest(BaseModel):
    patient_id: Optional[str] = Field(None, description="Identifier of the patient")
    physical_condition: Optional[str] = Field("NORMAL", description="FIT, NORMAL, LEMAS, LELAH_PUSING")
    visual_symptoms: Optional[str] = Field("", description="Patient description of eye symptoms")
    visual_flags: Optional[Dict[str, bool]] = Field(default_factory=dict, description="Boolean flags for sudden vision drop, flashes, floaters, curtain shadow")
    blood_glucose: Optional[float] = Field(None, description="Blood glucose reading in mg/dL")
    glucose_context: Optional[str] = Field("FASTING", description="FASTING, POST_PRANDIAL, or RANDOM")
    medications_completed: Optional[bool] = Field(True, description="Whether prescribed medications were taken")
    activity_completed: Optional[bool] = Field(True, description="Whether safe daily physical activity was done")
    patient_notes: Optional[str] = Field(None, description="Additional notes reported by patient")

class DailyCheckInResponse(BaseModel):
    status: str = "success"
    is_emergency: bool = False
    severity: str = Field("ROUTINE", description="ROUTINE, ATTENTION, WARNING, CRITICAL_EMERGENCY")
    matched_triggers: List[str] = Field(default_factory=list)
    summary: str
    explanation: str
    next_step: str
    actionable_guidance: List[str] = Field(default_factory=list)
    clinical_safety_notice: str

class SmartMealRecommendationRequest(BaseModel):
    patient_id: Optional[str] = Field(None, description="Identifier of the patient")
    meal_category: Optional[str] = Field("LUNCH", description="BREAKFAST, LUNCH, DINNER, SNACK")
    daily_budget: Optional[float] = Field(35000, description="Daily or per-meal target budget in IDR")
    allergies: Optional[List[str]] = Field(default_factory=list, description="Allergens such as udang, seafood, kacang, telur")
    dietary_restrictions: Optional[List[str]] = Field(default_factory=list, description="Restrictions such as ginjal, nefropati, hipertensi, rendah_garam")
    preferred_proteins: Optional[List[str]] = Field(default_factory=list, description="Preferred proteins: tempe, tahu, ikan, telur, ayam")
    available_ingredients: Optional[List[str]] = Field(default_factory=list, description="Ingredients readily available in kitchen")
    last_glucose_mg_dl: Optional[float] = Field(None, description="Recent blood glucose reading in mg/dL")
    last_glucose_context: Optional[str] = Field("FASTING", description="FASTING or POST_PRANDIAL")
    clinician_notes: Optional[str] = Field(None, description="Doctor instructions from consultation summary")

class SmartMealItemSchema(BaseModel):
    id: str
    category: str
    time_recommendation: str
    name: str
    main_dish: str
    complementary_foods: List[str]
    suggested_portion: str
    ingredients: List[Dict[str, Any]]
    estimated_cost_idr: float
    affordable_alternatives: List[Dict[str, Any]]
    nutrition: Dict[str, Any]
    nutritional_impact_explanation: Dict[str, str]
    is_eaten: bool = False
    eaten_at: Optional[str] = None
    post_meal_glucose_mg_dl: Optional[float] = None

class SmartMealRecommendationResponse(BaseModel):
    success: bool = True
    meal: SmartMealItemSchema
    clinical_safety_validation: Dict[str, Any]
    disclaimer: str

