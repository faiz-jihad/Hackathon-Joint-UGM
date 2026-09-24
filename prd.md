# RETIVA --- Product Requirements Document (PRD)

## 1. Product Overview

**Product:** RETIVA\
**Positioning:** Reliability-First AI-Assisted Diabetic Retinopathy
Screening\
**Primary domain:** Diabetes eye screening\
**Product type:** Healthcare screening-support platform

RETIVA helps organize diabetic retinopathy screening from retinal image
intake through quality validation, AI-assisted screening, human review,
follow-up, and referral workflow.

RETIVA is not an autonomous diagnostic system. It provides screening
support and keeps clinical decisions with authorized healthcare
professionals.

## 2. Problem

Diabetic retinopathy screening is affected by: - increasing diabetes
burden; - limited specialist resources; - inconsistent retinal image
quality; - model uncertainty; - performance changes across datasets and
imaging environments; - fragmented follow-up after screening.

A classifier that always returns a label does not adequately represent
these operational risks.

RETIVA therefore treats uncertainty as a workflow state.

## 3. Product Vision

> Help transform diabetic retinopathy screening from a one-time AI
> prediction into a reliable, traceable, and actionable care workflow.

Core journey:

``` text
Screen → Verify → Review → Recommend → Refer → Follow
```

## 4. Target Users

### Patient with diabetes

Needs: - easy screening flow; - understandable result; - clear next
step; - screening history; - follow-up information; - facility/referral
information when appropriate.

### Healthcare worker / reviewer

Needs: - image quality assessment; - AI screening result; - reliability
information; - Grad-CAM context; - human review workflow; - patient
history; - follow-up tracking.

### Healthcare facility administrator

Needs: - screening activity overview; - retake and human-review
counts; - follow-up status; - auditable workflow.

## 5. Goals

### Primary goals

1.  Prevent poor-quality images from entering the classification
    workflow.
2.  Avoid presenting unreliable AI predictions as definitive screening
    outputs.
3.  Route uncertain cases to human review.
4.  Provide a structured screening record.
5.  Connect screening outcomes to follow-up/referral workflows.
6.  Maintain traceability of AI model versions and workflow events.
7.  Build an architecture that can evolve into a healthcare product
    without provider lock-in.

### Secondary goals

-   Improve screening workflow usability.
-   Support facility-level monitoring.
-   Prepare for future healthcare interoperability.

## 6. Non-Goals

For the initial product, RETIVA will not: - diagnose independently; -
prescribe medication; - provide treatment plans; - replace clinical
review; - autonomously select referral hospitals; - provide a
general-purpose medical chatbot; - cover unrelated eye diseases; - claim
production integration with BPJS/JKN/SATUSEHAT without authorization.

## 7. Core Features

### P0 --- Patient Profile

Data: - basic identity; - diabetes profile; - screening history; -
relevant screening metadata.

Requirement: Patients can view only their own authorized data.

### P0 --- Retinal Screening

Flow: 1. Start screening. 2. Upload/capture fundus image. 3. Run image
quality check. 4. If failed, show retake guidance. 5. If passed, run AI
screening. 6. Evaluate reliability. 7. Display appropriate workflow
state.

### P0 --- Image Quality Gate

Checks may include: - blur; - exposure; - fundus coverage; - crop/FOV; -
image validity.

Output:

``` text
PASS
FAIL
```

A failed image must not be treated as a valid DR classification.

### P0 --- AI DR Screening

Model: - EfficientNet-B3.

Classes: - No DR - Mild - Moderate - Severe - Proliferative DR

The result is screening support, not diagnosis.

### P0 --- Reliability Gate

Possible outcomes:

``` text
RETAKE
HUMAN REVIEW
ANALYZE
```

Reliability thresholds must be configurable and versioned.

### P0 --- Human Review

Reviewer can inspect: - fundus image; - AI classification; -
confidence/reliability; - quality result; - Grad-CAM; - screening
history.

The reviewer is the authorized decision-maker within the clinical
workflow.

### P0 --- Patient-Friendly Result

Result should explain: - screening status; - whether the image was
usable; - whether review is required; - next action; - non-diagnostic
disclaimer.

Avoid presenting raw probability as if it were a medical certainty.

### P0 --- Screening History

Display: - screening date; - eye/image metadata; - workflow state; -
reviewed status; - follow-up status.

### P0 --- Follow-up

Track:

``` text
SCREENING
→ REVIEW
→ FOLLOW-UP REQUIRED
→ REFERRAL RECOMMENDED
→ FOLLOW-UP COMPLETED
```

### P1 --- Facility Matching

Facility data: - facility name; - location; - eye/retina services; -
insurance/JKN information; - verification status.

JKN/BPJS status must be explicitly labeled as verified, unavailable, or
requiring confirmation. No unsupported live integration claims.

### P1 --- Reminder

Reminder for: - scheduled follow-up; - screening activity; - review
completion.

Clinical intervals should come from authorized healthcare workflow
rather than an arbitrary AI rule.

### P1 --- Healthcare Dashboard

Metrics: - screenings; - retakes; - human reviews; - completed
reviews; - follow-up pending; - follow-up completed.

## 8. User Stories

### Patient

-   As a patient, I want to start retinal screening so that I can
    participate in a structured DR screening process.
-   As a patient, I want to know when my image is not suitable so I can
    retake it.
-   As a patient, I want understandable screening information.
-   As a patient, I want to know what action comes next.
-   As a patient, I want to see my previous screening records.
-   As a patient, I want facility information when follow-up is needed.

### Healthcare worker

-   As a reviewer, I want to see cases that require human review.
-   As a reviewer, I want to see image quality and AI reliability
    information.
-   As a reviewer, I want Grad-CAM as contextual information.
-   As a reviewer, I want patient screening history.
-   As a reviewer, I want to record review and follow-up status.

### Administrator

-   As a facility administrator, I want to monitor screening workflow.
-   As an administrator, I want an audit trail for important actions.

## 9. Functional Requirements

### FR-01 Authentication

The system must authenticate users and enforce role-based access.

### FR-02 Authorization

The system must enforce resource-level authorization.

### FR-03 Screening Creation

The system must create a screening record before image processing.

### FR-04 Image Upload

The system must store retinal images in private object storage and
retain metadata in PostgreSQL.

### FR-05 Quality Gate

The system must evaluate image quality before DR classification.

### FR-06 Retake

If quality fails, the system must produce a retake state and reason.

### FR-07 AI Inference

The backend must call the AI service through an internal AI client
abstraction.

### FR-08 Reliability

The backend must classify AI output into an appropriate reliability
workflow.

### FR-09 Human Review

Uncertain cases must be available to authorized reviewers.

### FR-10 Explainability

Grad-CAM may be shown as contextual information and must not be
represented as proof of diagnosis.

### FR-11 Recommendation

Recommendations must describe workflow next steps, not autonomous
medical treatment.

### FR-12 Referral

The system may present facility/referral options based on verified
facility data and authorized workflow.

### FR-13 Follow-up

The system must track follow-up status.

### FR-14 Audit

Important workflow actions must create audit records.

### FR-15 Model Versioning

Every AI result must identify the model/pipeline version.

## 10. Safety Requirements

1.  AI must not be presented as a diagnosis.
2.  Low-reliability results must not bypass human review.
3.  Quality failures must not be silently classified.
4.  AI must not change safety thresholds dynamically.
5.  Agentic components must not override deterministic safety policy.
6.  AI must not prescribe medication.
7.  AI must not independently determine clinical referral.
8.  Patient-facing copy must clearly communicate screening limitations.

## 11. Success Metrics

### Model

-   QWK
-   Macro-F1
-   recall for severe/proliferative grades
-   calibration error
-   cross-dataset performance

### Workflow

-   quality-gate accuracy;
-   retake rate;
-   abstention/human-review rate;
-   screening completion time;
-   reviewer task completion;
-   usability.

These metrics are product-development evidence and should not be
presented as clinical outcome claims without appropriate validation.

## 12. MVP Scope

### Must have

-   Patient profile
-   Retinal screening
-   Image Quality Gate
-   EfficientNet-B3
-   Reliability Gate
-   Retake workflow
-   Human Review
-   Patient-friendly result
-   Screening history
-   Follow-up status

### Should have

-   Healthcare dashboard
-   Facility information
-   Referral workflow
-   Reminder
-   Audit log
-   Model versioning

### Later

-   External healthcare interoperability
-   Production JKN/SATUSEHAT integration where authorized
-   Site-specific validation
-   Larger clinical validation
-   Enterprise deployment

## 13. Acceptance Criteria

### Good image

``` text
Image uploaded
→ Quality PASS
→ AI inference
→ Reliability sufficient
→ Screening result
→ Explainability available
```

### Bad image

``` text
Image uploaded
→ Quality FAIL
→ Reason displayed
→ RETAKE_REQUIRED
```

### Uncertain case

``` text
Image uploaded
→ Quality PASS
→ AI inference
→ Reliability LOW
→ HUMAN_REVIEW
→ Reviewer records outcome
```

### Follow-up

``` text
Screening completed
→ Follow-up required
→ Facility information
→ Referral workflow
→ Follow-up status updated
```

## 14. Product Risks

  -----------------------------------------------------------------------
  Risk                                Mitigation
  ----------------------------------- -----------------------------------
  Poor image quality                  Image Quality Gate + retake

  Overconfident AI                    Calibration + Reliability Gate +
                                      abstention

  Domain shift                        Cross-dataset evaluation + future
                                      local validation

  AI dependency                       Human review

  Privacy                             Access control + private storage +
                                      audit trail

  Agent error                         Allowlisted tools + deterministic
                                      safety policy

  Provider lock-in                    Repository and adapter interfaces

  Unsupported healthcare integration  Integration abstraction + explicit
  claims                              verification status
  -----------------------------------------------------------------------

## 15. Future Product Direction

RETIVA may evolve from an AI screening prototype into a broader diabetes
eye-screening workflow platform while keeping the same core principle:

> The system should not only produce a prediction; it should help ensure
> that every screening result enters an appropriate, traceable next
> step.
