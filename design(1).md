# RETIVA --- Product & UX Design Specification

## 1. Design Direction

RETIVA is a healthcare product for diabetic retinopathy screening. The
interface should communicate:

-   trust;
-   calmness;
-   clarity;
-   clinical seriousness;
-   accessibility;
-   transparency.

Avoid: - excessive futuristic AI visuals; - decorative dashboards with
no clinical purpose; - aggressive red/green "diagnosis" language; - raw
model jargon on patient screens; - chatbot-first interaction.

The product should feel like a healthcare workflow product, not an AI
demo.

## 2. Design Principles

### 2.1 Explain the next action

Every important state should answer:

> What happened, and what should I do next?

### 2.2 Reliability before prediction

The UI must make quality and reliability visible before celebrating the
AI result.

### 2.3 Progressive disclosure

Patient: - simple language; - clear next action.

Healthcare worker: - technical evidence; - confidence/reliability; -
Grad-CAM; - history.

### 2.4 No false certainty

Never use language such as: - "You definitely have DR." - "AI
diagnosis." - "100% safe."

Prefer: - "Hasil skrining menunjukkan..." - "Citra perlu ditinjau tenaga
kesehatan." - "Hasil ini bukan diagnosis."

### 2.5 Accessibility

Use: - readable typography; - sufficient contrast; - large touch
targets; - clear status labels; - icon + text, not color alone; - Bahasa
Indonesia as default.

## 3. Information Architecture

``` text
PATIENT APP

Home
├── Diabetes Profile
├── Start Screening
├── Screening History
├── Follow-up
└── Profile


HEALTHCARE WEB

Dashboard
├── Screening Queue
├── Patients
├── Human Review
├── Follow-ups
├── Referrals
├── Facilities
└── Audit / Settings
```

## 4. Patient Experience

### 4.1 Home

Primary card:

``` text
Retina Screening

Last screening
[date]

Status
[status]

[Mulai Screening]
```

Secondary: - follow-up status; - recent screening; - reminders.

Do not overload the home screen with analytics.

### 4.2 Diabetes Profile

Show: - diabetes type; - diabetes duration; - relevant screening
history; - last retinal screening; - care/facility information.

Only collect data needed for the workflow.

### 4.3 Screening Introduction

Explain:

1.  Why retinal screening matters.
2.  What image is needed.
3.  What happens after upload.
4.  That RETIVA supports screening and does not provide a final
    diagnosis.

Primary CTA:

`Mulai Screening`

### 4.4 Image Capture / Upload

UI:

``` text
┌──────────────────────────┐
│      Fundus Image        │
│                          │
│    [ image preview ]     │
│                          │
│  Pastikan retina terlihat│
│                          │
└──────────────────────────┘

[Ambil Foto] [Pilih Foto]
```

Show basic capture guidance: - center the fundus; - avoid blur; -
adequate lighting; - follow the approved imaging device/workflow.

### 4.5 Quality Gate

Do not immediately show a technical score.

Good:

``` text
Citra sedang diperiksa…

✓ Ketajaman
✓ Pencahayaan
✓ Cakupan retina
```

If failed:

``` text
Citra belum dapat digunakan

Alasan:
Gambar terlalu buram.

Silakan ambil gambar ulang.

[Ambil Ulang]
```

### 4.6 Screening Processing

Show an understandable progress state:

``` text
Memeriksa kualitas citra     ✓
Menganalisis citra            ✓
Menilai keandalan hasil       …
Menyiapkan hasil              …
```

Avoid fake progress percentages.

### 4.7 Reliable Result

Patient view:

``` text
Hasil Skrining

Status:
Hasil skrining dapat ditampilkan

Temuan:
[patient-friendly summary]

Langkah berikutnya:
[clear action]

Catatan:
Hasil skrining bukan diagnosis.
Keputusan pemeriksaan lanjutan dilakukan oleh tenaga kesehatan.

[Lihat Detail]
```

Do not expose raw confidence as the main patient message.

### 4.8 Human Review

If uncertain:

``` text
Hasil membutuhkan peninjauan

RETIVA belum cukup yakin untuk
menampilkan hasil sebagai screening support.

Citra akan ditinjau oleh tenaga kesehatan.

Status:
Menunggu review
```

This is a feature, not an error.

### 4.9 Screening History

Timeline:

``` text
24 Sep 2026
Screening
      ↓
Quality PASS
      ↓
AI Screening
      ↓
Human Review
      ↓
Follow-up
```

Each event can be expanded.

### 4.10 Follow-up

Use a simple status card:

``` text
Tindak lanjut

Status:
Perlu pemeriksaan lanjutan

[ Lihat Fasilitas ]
[ Lihat Detail ]
```

### 4.11 Facility / Referral

Facility card:

``` text
Rumah Sakit / Klinik
Nama fasilitas

Layanan:
Pemeriksaan mata / retina

JKN:
Menerima JKN
atau
Status perlu dikonfirmasi

Lokasi:
...

[Detail]
[Navigasi]
```

Do not display unsupported insurance claims.

## 5. Healthcare Worker Experience

### 5.1 Dashboard

Prioritize workflow:

``` text
Today

Screened          42
Retake             7
Human Review       5
Follow-up         12
```

Then:

``` text
Review Queue
--------------------------------
Patient     Reliability   Status
A           Low           Review
B           Low           Review
C           Medium        Review
```

Avoid vanity metrics.

### 5.2 Screening Detail

Structure:

``` text
Patient
↓
Image
↓
Quality
↓
AI Result
↓
Reliability
↓
Grad-CAM
↓
History
↓
Review Action
```

### 5.3 Human Review

Show:

``` text
Patient Information

Fundus Image
[image]

Image Quality
PASS

AI Screening
Moderate DR

Probability
87%

Reliability
Needs Review

Model
EfficientNet-B3 v1

Grad-CAM
[visualization]

[Record Review]
```

Important: Grad-CAM must be labeled as model explanation/context, not a
clinical proof.

### 5.4 Review Action

Provide explicit actions appropriate to the workflow:

``` text
Review Status
○ Reviewed
○ Needs further assessment
○ Additional image required

Notes
[........................]

[Save Review]
```

Clinical decisions beyond the defined product workflow remain with the
authorized professional.

## 6. Visual Language

### Color semantics

Use color as a secondary signal.

Suggested semantic palette:

-   Neutral: information/default
-   Blue/teal: primary healthcare interaction
-   Green: completed/success
-   Amber: attention/review
-   Red: critical action/error

Do not use red automatically to mean "disease."

For example: - red image-quality error = retake required; - amber =
human review; - green = workflow completed.

## 7. Typography

Use a highly legible sans-serif.

Hierarchy:

``` text
Page title
Section heading
Card heading
Body
Supporting text
Metadata
```

Avoid very small text for clinical information.

## 8. Components

Create reusable components:

``` text
AppShell
BottomNavigation
TopBar
PatientCard
ScreeningCard
ScreeningStatus
QualityStatus
ReliabilityBadge
ResultCard
ReviewCard
Timeline
FacilityCard
FollowUpCard
EmptyState
ErrorState
LoadingState
ConsentDialog
```

## 9. Status System

Use both text and visual indicators.

``` text
QUALITY_PASS
" Citra layak "

QUALITY_FAIL
" Perlu diambil ulang "

RELIABILITY_HIGH
" Hasil dapat ditampilkan "

RELIABILITY_LOW
" Perlu review "

FOLLOW_UP_REQUIRED
" Perlu tindak lanjut "

FOLLOW_UP_COMPLETED
" Tindak lanjut selesai "
```

Avoid status labels that imply diagnosis.

## 10. Error Handling UX

Every error should have:

1.  What happened.
2.  Why it matters.
3.  What the user can do.

Example:

``` text
Citra belum dapat diproses.

Gambar terlalu gelap sehingga area retina
belum terlihat dengan cukup baik.

Silakan ambil gambar ulang.

[Ambil Ulang]
```

## 11. Empty States

Example screening history:

``` text
Belum ada riwayat screening

Mulai screening retina untuk diabetes
untuk membuat catatan pertama Anda.

[Mulai Screening]
```

## 12. Consent & Privacy

Before first screening, show concise consent information: - purpose of
image collection; - use within screening workflow; - access by
authorized users; - storage/security notice; - ability to review
applicable privacy information.

Do not bury important privacy information in a long paragraph.

## 13. Responsive Web

Healthcare dashboard should support: - desktop first; - tablet; -
smaller laptop screens.

Important review screen should keep image and result visible without
excessive scrolling.

Suggested desktop layout:

``` text
┌──────────────────────────────────────────────┐
│ Patient / Screening Header                  │
├─────────────────────┬────────────────────────┤
│                     │ Quality                 │
│   Fundus Image      │ AI Result               │
│                     │ Reliability              │
│                     │ Model Version            │
├─────────────────────┴────────────────────────┤
│ Grad-CAM / Explanation                         │
├──────────────────────────────────────────────┤
│ History                                       │
├──────────────────────────────────────────────┤
│ Review Action                                 │
└──────────────────────────────────────────────┘
```

## 14. Mobile Navigation

Recommended patient navigation:

``` text
Home
Screening
History
Follow-up
Profile
```

The screening CTA should be easy to reach from Home.

## 15. Design Safety Rules

Never: - present an AI score as diagnosis; - hide uncertainty; - make a
failed quality check look like a disease result; - make the user think a
recommendation is a prescription; - show unverified JKN/BPJS
availability as guaranteed; - allow AI-generated text to override
deterministic workflow rules.

## 16. Design Goal

The final product should feel like:

> **A trustworthy diabetes screening workflow that happens to use AI.**

Not:

> **An AI model wrapped in a healthcare UI.**

The most important visual hierarchy is:

``` text
What happened?
      ↓
How reliable is the result?
      ↓
Who needs to review it?
      ↓
What should happen next?
```
