import { EmergencyStore } from "../infrastructure/database/emergency-store";

async function runSosTests() {
  console.log("==================================================");
  console.log("🧪 RETIVA SOS — AGENTIC EMERGENCY SYSTEM TEST SUITE");
  console.log("==================================================\n");

  let passed = 0;
  let failed = 0;

  function assert(condition: boolean, desc: string) {
    if (condition) {
      console.log(`✅ PASS: ${desc}`);
      passed++;
    } else {
      console.error(`❌ FAIL: ${desc}`);
      failed++;
    }
  }

  try {
    // 1. Test Seed Incidents
    console.log("--- 1. Testing Initial Seed Incidents & Stats ---");
    const initialIncidents = await EmergencyStore.getIncidents();
    assert(initialIncidents.length >= 2, `Retrieved ${initialIncidents.length} initial incidents`);
    const initialStats = await EmergencyStore.getStats();
    assert(initialStats.total >= 2, `Initial stats has ${initialStats.total} total cases`);
    assert(initialStats.active >= 1, `Initial stats has ${initialStats.active} active cases`);

    // 2. Test Clinical Safety Rule: Unconscious Patient (STRICT: NO ORAL FOOD/DRINK)
    console.log("\n--- 2. Testing Clinical Safety Rule: Unconscious Patient ---");
    const unconsciousIncident = await EmergencyStore.createIncident({
      patientId: "patient-test-unconscious",
      patientName: "Bpk. Haryanto (Simulasi Tidak Sadar)",
      patientNik: "3471011122330001",
      patientPhone: "081999888777",
      symptoms: ["Pingsan", "Tidak merespon panggilan", "Napas dangkal"],
      reportedContext: {
        conscious: false,
        canSwallow: false,
        bloodGlucose: 45,
      },
      latitude: -7.7850,
      longitude: 110.3700,
      accuracyMeters: 9.0,
      locationStatus: "ACCURATE",
    });

    assert(unconsciousIncident.urgencyLevel === "CRITICAL", "Unconscious patient classified as CRITICAL");
    assert(unconsciousIncident.triageAssessment?.oralFoodAllowed === false, "CRITICAL RULE: Oral food/drink strictly FORBIDDEN (Aspiration Hazard)");
    assert(unconsciousIncident.triageAssessment?.requiresAmbulance === true, "CRITICAL RULE: Requires urgent Ambulance 119 dispatch");
    assert(unconsciousIncident.triageAssessment?.warningFlags.some(f => f.includes("BAHAYA ASPIRASI")) === true, "Warning flag includes Aspiration Hazard");

    // 3. Test Clinical Safety Rule: Conscious Hypoglycemia (Rule 15-15)
    console.log("\n--- 3. Testing Clinical Safety Rule: Conscious Hypoglycemia ---");
    const hypoIncident = await EmergencyStore.createIncident({
      patientId: "patient-test-hypo",
      patientName: "Ibu Hartini (Simulasi Hipoglikemia Sadar)",
      symptoms: ["Keringat dingin", "Gemetar", "Glukosa 58 mg/dL"],
      reportedContext: {
        conscious: true,
        canSwallow: true,
        bloodGlucose: 58,
      },
    });

    assert(hypoIncident.urgencyLevel === "HIGH" || hypoIncident.urgencyLevel === "CRITICAL", "Hypo classified as HIGH or CRITICAL");
    assert(hypoIncident.triageAssessment?.oralFoodAllowed === true, "Conscious patient CAN safely take oral carbohydrate");
    assert(hypoIncident.triageAssessment?.immediateAction.includes("15") === true, "Immediate action specifies Rule 15-15 protocol");

    // 4. Test Clinical Safety Rule: Acute Retinal Emergency (Curtain Shadow / Vitreous Hemorrhage)
    console.log("\n--- 4. Testing Clinical Safety Rule: Acute Retinal Emergency ---");
    const retinalIncident = await EmergencyStore.createIncident({
      patientId: "patient-test-retina",
      patientName: "Bpk. Gunawan (Simulasi Ablasio Retina)",
      symptoms: ["Pandangan mendadak gelap seperti tirai", "Kilatan cahaya (fotopsia)"],
      reportedContext: {
        conscious: true,
        canSwallow: true,
        visionChanges: true,
      },
    });

    assert(retinalIncident.triageAssessment?.requiresEyeSpecialist === true, "Retinal incident requires Eye Specialist (<24h)");
    assert(retinalIncident.triageAssessment?.clinicalRisk.toLowerCase().includes("retinopati") === true, "Risk identified as Retinopati / Ablasio Retina");

    // 5. Test Responder Workflow: Acknowledge, Add Follow-up Note, Resolve
    console.log("\n--- 5. Testing Responder Workflow (Acknowledge -> Note -> Resolve) ---");
    const acked = await EmergencyStore.updateIncidentStatus(
      unconsciousIncident.id,
      "ACKNOWLEDGED",
      "usr-doctor-01",
      "dr. Nurul Aini (Dokter Puskesmas)",
      "Tim ambulans 119 SPGDT telah dikerahkan ke lokasi."
    );
    assert(acked?.status === "ACKNOWLEDGED", "Incident status successfully transitioned to ACKNOWLEDGED");
    assert(acked?.acknowledgedAt !== null, "acknowledgedAt timestamp recorded");

    const note = await EmergencyStore.addFollowUp(
      unconsciousIncident.id,
      "usr-doctor-01",
      "dr. Nurul Aini",
      "Ambulans tiba di lokasi pasien. Pasien diposisikan miring mantap dan diberikan dekstrosa intravena.",
      "Pemasangan Infus D40% IV & Oksigenasi"
    );
    assert(note.notes.includes("Ambulans tiba"), "Follow-up note recorded successfully");

    const resolved = await EmergencyStore.updateIncidentStatus(
      unconsciousIncident.id,
      "RESOLVED",
      "usr-doctor-01",
      "dr. Nurul Aini",
      "Pasien telah tiba di IGD RS Sardjito dalam kondisi sadar (GCS 15). Masalah teratasi."
    );
    assert(resolved?.status === "RESOLVED", "Incident successfully transitioned to RESOLVED");
    assert(resolved?.resolvedAt !== null, "resolvedAt timestamp recorded");

    // 6. Test Emergency Contacts Management
    console.log("\n--- 6. Testing Emergency Contacts ---");
    const contacts = await EmergencyStore.getContactsByPatientId("patient-test-contacts");
    assert(contacts.length >= 1, "Default fallback contacts provided if none registered");

    const newContact = await EmergencyStore.createContact({
      patientId: "patient-test-contacts",
      name: "Budi Santoso",
      relationship: "Kakak Kandung",
      phoneNumber: "081299988877",
      isPrimary: true,
      isVerified: true,
      preferredChannel: "WHATSAPP",
    });
    assert(newContact.name === "Budi Santoso", "New emergency contact created");

    const updatedContacts = await EmergencyStore.getContactsByPatientId("patient-test-contacts");
    assert(updatedContacts.some(c => c.id === newContact.id), "Contact retrieved for patient");

    await EmergencyStore.deleteContact(newContact.id);
    const afterDelete = await EmergencyStore.getContactsByPatientId("patient-test-contacts");
    assert(!afterDelete.some(c => c.id === newContact.id), "Contact deleted successfully");

    // 7. Test Real-time Broadcast Event Bus
    console.log("\n--- 7. Testing Real-time Event Bus ---");
    let receivedBroadcast: any = false;
    const unsubscribe = EmergencyStore.subscribe((inc) => {
      if (inc.id === "sos-broadcast-test") {
        receivedBroadcast = true;
      }
    });

    await EmergencyStore.createIncident({
      patientId: "patient-broadcast",
      patientName: "Tes Realtime",
      symptoms: ["Pusing"],
    });
    EmergencyStore.broadcast({
      ...unconsciousIncident,
      id: "sos-broadcast-test",
    });

    assert(receivedBroadcast === true, "Realtime subscriber received event broadcast");
    unsubscribe();

  } catch (err: any) {
    console.error("Test execution threw error:", err);
    failed++;
  }

  console.log("\n==================================================");
  console.log(`TEST RESULTS: ${passed} PASSED, ${failed} FAILED`);
  console.log("==================================================");

  if (failed > 0) {
    process.exit(1);
  }
}

runSosTests();
