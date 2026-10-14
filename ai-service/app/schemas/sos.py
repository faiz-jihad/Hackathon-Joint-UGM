from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field

class SOSTriageRequest(BaseModel):
    patient_id: str = Field(..., description="Unique Patient Identifier")
    patient_name: Optional[str] = Field(None, description="Patient Full Name")
    symptoms: List[str] = Field(default_factory=list, description="Explicit reported symptoms")
    blood_glucose: Optional[float] = Field(None, description="Current blood glucose (mg/dL)")
    conscious: Optional[bool] = Field(True, description="Whether the patient is conscious")
    can_swallow: Optional[bool] = Field(True, description="Whether the patient can safely swallow")
    vision_changes: Optional[bool] = Field(False, description="Sudden vision loss, dark curtain, or flashes")
    seizure_occurred: Optional[bool] = Field(False, description="Whether convulsion or seizure occurred")
    free_text_notes: Optional[str] = Field(None, description="Additional context or caregiver notes")
    latitude: Optional[float] = Field(None, description="GPS Latitude")
    longitude: Optional[float] = Field(None, description="GPS Longitude")

class WorkflowStageSchema(BaseModel):
    assess: Dict[str, Any]
    triage: Dict[str, Any]
    plan: Dict[str, Any]
    act: Dict[str, Any]
    verify: Dict[str, Any]
    follow_up: Dict[str, Any]

class SOSTriageResponse(BaseModel):
    success: bool = True
    urgency_level: str = Field(..., description="CRITICAL, HIGH, MEDIUM, LOW")
    clinical_risk: str
    immediate_action: str
    warning_flags: List[str]
    safe_protocol: List[str]
    oral_food_allowed: bool = Field(..., description="STRICT SAFETY RULE: NEVER allow oral intake if unconscious/cannot swallow")
    requires_ambulance: bool
    requires_eye_specialist: bool
    ai_explanation: str
    workflow_stages: WorkflowStageSchema
