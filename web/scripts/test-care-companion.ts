/**
 * Test Suite: Agentic AI Pre-Consultation & Post-Consultation Care Companion
 * Validates:
 * 1. Urgent Symptom Safety Evaluator (Red-flag eye emergency triggers vs safe symptoms)
 * 2. State Machine Transitions & Invariants (Guard against post-consultation plan without confirmed doctor summary)
 * 3. Budget-Aware Nutrition Engine (Indonesian low-GI recipes, IDR pricing, budget bounds)
 * 4. Meal Replacement & Dynamic Budget Recalculation
 * 5. Care Companion Orchestrator Action Execution & Audit Trail
 * 6. Verification Status & Source Labeling
 */

import { UrgentSymptomChecker } from "../domain/care-companion/urgent-symptom-checker";
import { CareStateMachine, CareStateContext } from "../domain/care-companion/care-state-machine";
import { BudgetNutritionEngine } from "../domain/care-companion/budget-nutrition-engine";
import { CareCompanionOrchestrator } from "../application/care-companion/care-companion-orchestrator";

async function runCareCompanionTests() {
  console.log("================================================================================");
  console.log("🧪 RETIVA CARE COMPANION: AUTOMATED VERIFICATION SUITE");
  console.log("================================================================================");

  let passedTests = 0;
  let totalTests = 0;

  function assert(condition: boolean, testName: string, detail?: string) {
    totalTests++;
    if (condition) {
      passedTests++;
      console.log(`  ✅ [PASS] ${testName}`);
    } else {
      console.error(`  ❌ [FAIL] ${testName}`);
      if (detail) console.error(`     Detail: ${detail}`);
    }
  }

  // ---------------------------------------------------------------------------
  // TEST GROUP 1: Urgent Symptom Safety Evaluator
  // ---------------------------------------------------------------------------
  console.log("\n[Group 1] Testing Urgent Symptom Safety Evaluator...");

  // Test 1.1: Flash of light & curtain shadow
  const criticalEval1 = UrgentSymptomChecker.evaluate(
    "Saya melihat kilatan cahaya terang dan ada bayangan seperti tirai menutup pandangan mata kanan."
  );
  assert(
    criticalEval1.isEmergency === true &&
    criticalEval1.severity === "CRITICAL_EMERGENCY" &&
    criticalEval1.canProceedWithRoutineCare === false &&
    criticalEval1.recommendedAction === "SEGERA_KE_IGD_RS_MATA",
    "Triggers emergency alert on flashes of light and curtain shadow",
    JSON.stringify(criticalEval1)
  );

  // Test 1.2: Sudden severe vision loss
  const criticalEval2 = UrgentSymptomChecker.evaluate(
    "Tiba-tiba penglihatan buram mendadak dan bintik hitam bertambah banyak sekali."
  );
  assert(
    criticalEval2.isEmergency === true &&
    criticalEval2.matchedTriggers.length >= 2,
    "Triggers emergency alert on sudden vision loss and sudden floaters",
    JSON.stringify(criticalEval2.matchedTriggers)
  );

  // Test 1.3: Normal non-urgent diabetes symptom
  const safeEval = UrgentSymptomChecker.evaluate(
    "Mata terasa sedikit kering setelah membaca dan saya ingin mengatur menu makan siang."
  );
  assert(
    safeEval.isEmergency === false &&
    safeEval.canProceedWithRoutineCare === true,
    "Correctly identifies non-urgent symptom and allows routine care to proceed"
  );

  // ---------------------------------------------------------------------------
  // TEST GROUP 2: State Machine Transitions & Invariants
  // ---------------------------------------------------------------------------
  console.log("\n[Group 2] Testing Care State Machine Transitions & Invariants...");

  // Test 2.1: Screening completed -> Awaiting consultation
  const ctxAwaiting: CareStateContext = {
    hasCompletedScreening: true,
    hasRecordedConsultation: false,
    isConsultationConfirmed: false,
    hasActiveCarePlan: false,
  };
  const stateAwaiting = CareStateMachine.resolveState(ctxAwaiting);
  assert(
    stateAwaiting === "AWAITING_CONSULTATION",
    "Resolves to AWAITING_CONSULTATION when screening completed without consultation"
  );

  // Test 2.2: Cannot activate CARE_PLAN_READY without confirmed consultation
  const transitionCheck = CareStateMachine.canTransition("AWAITING_CONSULTATION", "CARE_PLAN_READY", ctxAwaiting);
  assert(
    transitionCheck.allowed === false &&
    transitionCheck.reason?.includes("konfirmasi ringkasan konsultasi dokter") === true,
    "Guard prevents activating post-consultation plan without confirmed doctor summary"
  );

  // Test 2.3: Consultation confirmed -> CARE_PLAN_READY
  const ctxConfirmed: CareStateContext = {
    hasCompletedScreening: true,
    hasRecordedConsultation: true,
    isConsultationConfirmed: true,
    hasActiveCarePlan: false,
  };
  const stateReady = CareStateMachine.resolveState(ctxConfirmed);
  assert(
    stateReady === "CARE_PLAN_READY",
    "Transitions to CARE_PLAN_READY once consultation is confirmed by patient"
  );

  // Test 2.4: Follow-up due within 3 days
  const futureDueDate = new Date(Date.now() + 2 * 24 * 3600 * 1000); // 2 days ahead
  const ctxFollowUp: CareStateContext = {
    hasCompletedScreening: true,
    hasRecordedConsultation: true,
    isConsultationConfirmed: true,
    hasActiveCarePlan: true,
    followUpDate: futureDueDate,
  };
  const stateFollowUp = CareStateMachine.resolveState(ctxFollowUp, "CARE_PLAN_ACTIVE");
  assert(
    stateFollowUp === "FOLLOW_UP_DUE",
    "Transitions to FOLLOW_UP_DUE when follow-up date is near (<= 3 days)"
  );

  // ---------------------------------------------------------------------------
  // TEST GROUP 3: Budget-Aware Nutrition Planner
  // ---------------------------------------------------------------------------
  console.log("\n[Group 3] Testing Budget-Aware Nutrition Engine...");

  // Test 3.1: Generate standard meal plan with IDR budget
  const budgetStandard = 35000;
  const planStandard = BudgetNutritionEngine.generatePlan({
    dailyBudgetIdr: budgetStandard,
    cityRegion: "D.I. Yogyakarta",
  });
  assert(
    planStandard.dailyBudgetIdr === budgetStandard &&
    planStandard.estimatedTotalCostIdr > 0 &&
    planStandard.meals.breakfast != null &&
    planStandard.meals.lunch != null &&
    planStandard.meals.dinner != null &&
    planStandard.meals.snack != null &&
    planStandard.shoppingList.length > 0,
    "Generates complete daily meal plan with 4 meals and shopping list"
  );

  // Test 3.2: Verify ingredients are realistic Indonesian staples with Low GI
  const hasIndonesianStaples =
    planStandard.meals.breakfast.ingredients.some((i) => i.name.toLowerCase().includes("bayam") || i.name.toLowerCase().includes("beras") || i.name.toLowerCase().includes("ubi")) &&
    planStandard.meals.lunch.ingredients.some((i) => i.name.toLowerCase().includes("ikan") || i.name.toLowerCase().includes("tempe") || i.name.toLowerCase().includes("ayam"));
  assert(
    hasIndonesianStaples && planStandard.meals.breakfast.glycemicIndex === "RENDAH",
    "Menu uses accessible Indonesian low-GI ingredients (bayam, ikan kembung, tempe, beras merah)"
  );

  // Test 3.3: Low budget adaptation (Rp 25.000)
  const planLowBudget = BudgetNutritionEngine.generatePlan({
    dailyBudgetIdr: 25000,
    cityRegion: "Sleman",
  });
  assert(
    planLowBudget.estimatedTotalCostIdr <= 30000,
    "Adapts recipe selection for lower budget (prioritizing tempe, tahu, ubi)"
  );

  // ---------------------------------------------------------------------------
  // TEST GROUP 4: Meal Replacement & Budget Recalculation
  // ---------------------------------------------------------------------------
  console.log("\n[Group 4] Testing Meal Replacement & Dynamic Recalculation...");

  const initialTotal = planStandard.estimatedTotalCostIdr;
  const replacedPlan = BudgetNutritionEngine.replaceMeal(planStandard, "SARAPAN");
  assert(
    replacedPlan.meals.breakfast.id !== planStandard.meals.breakfast.id &&
    typeof replacedPlan.estimatedTotalCostIdr === "number" &&
    replacedPlan.remainingBudgetIdr === replacedPlan.dailyBudgetIdr - replacedPlan.estimatedTotalCostIdr,
    "Successfully replaces breakfast and dynamically updates remaining budget"
  );

  // ---------------------------------------------------------------------------
  // TEST GROUP 5: Care Companion Orchestrator Action Execution
  // ---------------------------------------------------------------------------
  console.log("\n[Group 5] Testing Care Companion Orchestrator Tool Execution...");

  // Test 5.1: Search eye care facilities
  const facilityAction = await CareCompanionOrchestrator.executeAction(
    { action: "search_eye_care_facilities", parameters: { bpjsOnly: true } },
    { patientId: "P-001" }
  );
  assert(
    facilityAction.success === true &&
    Array.isArray(facilityAction.data.facilities) &&
    facilityAction.data.facilities.length > 0 &&
    facilityAction.data.facilities.every((f: any) => f.bpjsStatus === "ACCEPTED"),
    "search_eye_care_facilities returns verified BPJS facilities"
  );

  // Test 5.2: Urgent symptoms evaluation via orchestrator
  const urgentAction = await CareCompanionOrchestrator.executeAction(
    { action: "check_urgent_symptoms", parameters: { symptomsText: "Mata tiba-tiba gelap mendadak dan ada kilat" } },
    { patientId: "P-001" }
  );
  assert(
    urgentAction.success === true &&
    urgentAction.isEmergencyAlert === true,
    "check_urgent_symptoms tool flags emergency alert via orchestrator"
  );

  // Test 5.3: Save care plan requires patient confirmation
  const unconfirmedSave = await CareCompanionOrchestrator.executeAction(
    { action: "save_patient_care_plan", parameters: { title: "Rencana Harian" }, patientConfirmed: false },
    { patientId: "P-001" }
  );
  assert(
    unconfirmedSave.success === true &&
    unconfirmedSave.requiresPatientConfirmation === true,
    "save_patient_care_plan enforces explicit patient confirmation requirement"
  );

  // Test 5.4: Save care plan with patient confirmation succeeds
  const confirmedSave = await CareCompanionOrchestrator.executeAction(
    { action: "save_patient_care_plan", parameters: { title: "Rencana Harian Terkonfirmasi" }, patientConfirmed: true },
    { patientId: "P-001", patientConfirmed: true }
  );
  assert(
    confirmedSave.success === true &&
    confirmedSave.data.status === "SAVED_AND_ACTIVE",
    "save_patient_care_plan successfully activates plan when confirmed by patient"
  );

  // ---------------------------------------------------------------------------
  // TEST GROUP 6: Master Data CRUD & Dynamic Engine Verification
  // ---------------------------------------------------------------------------
  console.log("\n[Group 6] Testing Care Companion Master Data CRUD & Dynamic Integration...");

  const { CareCompanionMasterStore } = await import("../infrastructure/database/care-companion-master-store");

  // Test 6.1: Create Master Meal
  const newMeal = await CareCompanionMasterStore.createMeal({
    name: "Nasi Merah Ikan Kakap Kukus Kemangi",
    category: "LUNCH",
    portion: "1 Porsi (Nasi Merah 100g, Kakap 80g)",
    estimatedCostIdr: 15000,
    glycemicIndex: "LOW",
    carbsGrams: 28,
    proteinGrams: 25,
    ingredients: ["Beras Merah (75g)", "Kakap Segar (80g)", "Kemangi"],
    preparationNotes: "Kukus kakap dengan bumbu kemangi tanpa minyak jelantah.",
    isActive: true,
  });
  assert(
    Boolean(newMeal.id) && newMeal.name === "Nasi Merah Ikan Kakap Kukus Kemangi",
    "CareCompanionMasterStore successfully creates new master meal"
  );

  // Test 6.2: Read & Update Master Meal
  const updatedMeal = await CareCompanionMasterStore.updateMeal(newMeal.id, {
    estimatedCostIdr: 16000,
  });
  assert(
    updatedMeal?.estimatedCostIdr === 16000,
    "CareCompanionMasterStore successfully updates master meal attributes"
  );

  // Test 6.3: Create & List Master Doctor Questions
  const newQuestion = await CareCompanionMasterStore.createQuestion({
    questionText: "Apakah saya perlu pemeriksaan lanjutan Optical Coherence Tomography (OCT)?",
    category: "Pemeriksaan Retina",
    orderIndex: 99,
    isActive: true,
  });
  const allQuestions = await CareCompanionMasterStore.getAllQuestions();
  assert(
    allQuestions.some((q) => q.id === newQuestion.id),
    "CareCompanionMasterStore creates and lists active master doctor questions"
  );

  // Test 6.4: Dynamic Meal Plan Async from Database Master
  const dynamicPlan = await BudgetNutritionEngine.generatePlanAsync({
    dailyBudgetIdr: 35000,
    cityRegion: "D.I. Yogyakarta",
  });
  assert(
    dynamicPlan.meals.breakfast !== undefined &&
    dynamicPlan.meals.lunch !== undefined &&
    dynamicPlan.meals.dinner !== undefined &&
    dynamicPlan.meals.snack !== undefined &&
    dynamicPlan.estimatedTotalCostIdr > 0,
    "BudgetNutritionEngine.generatePlanAsync dynamically generates plan from Master database"
  );

  // Test 6.5: Dynamic Meal Replacement from Master Database
  const replacedPlanMaster = await BudgetNutritionEngine.replaceMealAsync(dynamicPlan, "SARAPAN");
  assert(
    replacedPlanMaster.meals.breakfast !== undefined &&
    replacedPlanMaster.remainingBudgetIdr !== undefined,
    "BudgetNutritionEngine.replaceMealAsync dynamically swaps meal options using Master database"
  );

  // Clean up test items
  await CareCompanionMasterStore.deleteMeal(newMeal.id);
  await CareCompanionMasterStore.deleteQuestion(newQuestion.id);
  const questionsAfterDelete = await CareCompanionMasterStore.getAllQuestions();
  assert(
    !questionsAfterDelete.some((q) => q.id === newQuestion.id),
    "CareCompanionMasterStore successfully deletes master doctor question"
  );
  console.log("\n================================================================================");
  console.log(`📊 TEST RESULTS: ${passedTests}/${totalTests} TESTS PASSED (${Math.round((passedTests / totalTests) * 100)}%)`);
  console.log("================================================================================");

  if (passedTests === totalTests) {
    console.log("🎉 ALL CARE COMPANION VERIFICATION TESTS PASSED SUCCESSFULLY!\n");
  } else {
    console.error("⚠️ SOME TESTS FAILED. PLEASE REVIEW THE DETAILS ABOVE.\n");
    process.exit(1);
  }
}

runCareCompanionTests().catch((err) => {
  console.error("Fatal test runner error:", err);
  process.exit(1);
});
