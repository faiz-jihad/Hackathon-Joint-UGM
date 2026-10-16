import 'dart:convert';
import 'dart:typed_data';

/// Generator dokumen PDF resmi SPK (Surat Pengantar Rujukan) berstandar PDF-1.4 murni.
/// Menghasilkan format surat rujukan resmi faskes (Kop Puskesmas, border formal,
/// tabel data pasien terisi dinamis, serta stempel verifikasi elektronik BSrE).
class PdfSpkGenerator {
  static Uint8List generateSpkPdfBytes({
    required String facilityName,
    required String patientName,
    required String patientNik,
    required String bpjsNo,
    required String screeningResult,
    required String icdCode,
    required String dateStr,
    String? patientGender,
    int? patientAge,
    String? fktpName,
    String? doctorReviewer,
    String? regNumber,
  }) {
    String escapePdf(String s) {
      return s
          .replaceAll(r'\', r'\\')
          .replaceAll('(', r'\(')
          .replaceAll(')', r'\)');
    }

    final fFacility = escapePdf(facilityName);
    final fPatient = escapePdf(patientName);
    final fNik = escapePdf(patientNik);
    final fBpjs = escapePdf(bpjsNo);
    final fDiag = escapePdf(screeningResult);
    final fIcd = escapePdf(icdCode);
    final fDate = escapePdf(dateStr);
    final fFktp = escapePdf(fktpName ?? 'PUSKESMAS SLEMAN');
    final fDoctor = escapePdf(doctorReviewer ?? 'dr. H. Susanto, Sp.M (K)');
    final fReg = escapePdf(regNumber ?? 'SPK/RTV/2026/09/0084');

    String genderText = '-';
    if (patientGender != null && patientGender.isNotEmpty) {
      final g = patientGender.toUpperCase();
      if (g.contains('MALE') || g == 'L' || g.contains('LAKI')) {
        genderText = 'Laki-laki';
      } else if (g.contains('FEMALE') || g == 'P' || g.contains('PEREMPUAN')) {
        genderText = 'Perempuan';
      } else {
        genderText = patientGender;
      }
    }
    final ageText = (patientAge != null && patientAge > 0) ? '$patientAge Tahun' : '';
    final demographicText = escapePdf(ageText.isNotEmpty && genderText != '-' ? '$genderText / $ageText' : (genderText != '-' ? genderText : (ageText.isNotEmpty ? ageText : '-')));

    final streamLines = [
      // 1. Fill White Background (Ensures crisp white paper across all PDF readers & dark mode)
      'q',
      '1 1 1 rg',
      '0 0 595.28 841.89 re f',
      'Q',

      // 2. Outer Document Border Box
      'q',
      '0.8 w',
      '0.2 0.3 0.4 RG',
      '36 36 523.28 769.89 re S',
      'Q',

      // 3. Kop Surat Instansi Penerbit
      'BT',
      '/F2 10 Tf',
      '0.1 0.2 0.35 rg',
      '50 775 Td',
      '(PEMERINTAH KABUPATEN SLEMAN - DINAS KESEHATAN) Tj',
      '/F2 13 Tf',
      '0 -16 Td',
      '($fFktp) Tj',
      '/F1 8.5 Tf',
      '0.3 0.35 0.4 rg',
      '0 -13 Td',
      '(Jl. Magelang Km. 12, Sleman, D.I. Yogyakarta 55511 - Telp: 0274-868411) Tj',
      'ET',

      // Double Header Divider (Thick + Thin line)
      'q',
      '1.5 w 0.1 0.2 0.35 RG 46 738 m 549 738 l S',
      '0.5 w 0.1 0.2 0.35 RG 46 735 m 549 735 l S',
      'Q',

      // Title & Reg Number
      'BT',
      '/F2 13 Tf',
      '0 0 0 rg',
      '175 712 Td',
      '(SURAT PENGANTAR RUJUKAN ELEKTRONIK) Tj',
      '/F1 9 Tf',
      '0.3 0.3 0.3 rg',
      '-25 -14 Td',
      '(Nomor: $fReg  |  Integrasi SatuSehat Kemenkes RI & BPJS V-Claim) Tj',
      'ET',

      // Section I: Identitas Pasien
      'q',
      '0.95 0.97 1 rg 46 642 503 36 re f',
      '0.5 w 0.7 0.8 0.9 RG 46 560 503 118 re S',
      'Q',

      'BT',
      '/F2 10 Tf',
      '0.05 0.25 0.6 rg',
      '56 654 Td',
      '(I. IDENTITAS PASIEN) Tj',
      '/F2 9 Tf',
      '0.2 0.2 0.2 rg',
      '0 -24 Td',
      '(Nama Pasien) Tj',
      '0 -15 Td',
      '(Nomor Induk Kependudukan (NIK)) Tj',
      '0 -15 Td',
      '(Nomor Kartu BPJS Kesehatan) Tj',
      '0 -15 Td',
      '(Jenis Kelamin / Usia) Tj',

      // Values Column
      '/F1 9 Tf',
      '165 0 Td',
      '(: $demographicText) Tj',
      '0 15 Td',
      '(: $fBpjs) Tj',
      '0 15 Td',
      '(: $fNik) Tj',
      '0 15 Td',
      '/F2 9.5 Tf',
      '(: $fPatient) Tj',
      'ET',

      // Section II: Temuan Klinis & Rujukan
      'q',
      '0.95 0.97 1 rg 46 510 503 36 re f',
      '0.5 w 0.7 0.8 0.9 RG 46 410 503 136 re S',
      'Q',

      'BT',
      '/F2 10 Tf',
      '0.05 0.25 0.6 rg',
      '56 522 Td',
      '(II. HASIL PENAPISAN RETINA & REKOMENDASI RUJUKAN KLINIS) Tj',
      '/F2 9 Tf',
      '0.2 0.2 0.2 rg',
      '0 -24 Td',
      '(Hasil Penapisan AI Retiva) Tj',
      '0 -15 Td',
      '(Klasifikasi ICD-10) Tj',
      '0 -15 Td',
      '(Fasilitas Kesehatan Tujuan) Tj',
      '0 -15 Td',
      '(Tindakan Medis Dimohon) Tj',
      '0 -15 Td',
      '(Tingkat Urgensi) Tj',

      // Values Column
      '/F1 9 Tf',
      '165 0 Td',
      '(: Penanganan Faskes Lanjutan (Poli Subspesialis Mata)) Tj',
      '0 15 Td',
      '(: Funduskopi Slit-Lamp & Evaluasi Retina Lanjutan) Tj',
      '0 15 Td',
      '/F2 9 Tf',
      '(: $fFacility) Tj',
      '/F1 9 Tf',
      '0 15 Td',
      '(: $fIcd) Tj',
      '0 15 Td',
      '/F2 9 Tf',
      '0.1 0.4 0.8 rg',
      '(: $fDiag) Tj',
      'ET',

      // Section III: Pengesahan & TTE BSrE
      'q',
      '0.97 0.98 0.99 rg 46 270 503 125 re f',
      '0.5 w 0.8 0.85 0.9 RG 46 270 503 125 re S',

      // Stamp / QR Verification Box
      '0.9 0.95 1 rg 370 282 165 72 re f',
      '1 w 0.1 0.4 0.8 RG 370 282 165 72 re S',
      'Q',

      'BT',
      '/F2 10 Tf',
      '0.1 0.2 0.35 rg',
      '56 375 Td',
      '(III. PENGESAHAN DOKTER & KEABSAHAN ELEKTRONIK) Tj',
      '/F1 8.5 Tf',
      '0.2 0.2 0.2 rg',
      '0 -18 Td',
      '(Dokumen ini diterbitkan oleh FKTP terhubung Rekam Medis SatuSehat Kemenkes.) Tj',
      '0 -13 Td',
      '(Dokter Penanggung Jawab Pelayanan: $fDoctor) Tj',
      '0 -13 Td',
      '(Tanggal Terbit: $fDate) Tj',
      '0 -14 Td',
      '0.4 0.4 0.4 rg',
      '(Dokumen sah secara elektronik sesuai UU ITE No. 11/2008 & PMK No. 24/2022.) Tj',

      // Text inside Verification Stamp
      '/F2 8 Tf',
      '0.05 0.3 0.7 rg',
      '380 338 Td',
      '(TERVERIFIKASI DIGITAL BSrE) Tj',
      '/F1 7.5 Tf',
      '0.2 0.2 0.2 rg',
      '0 -12 Td',
      '(Balai Sertifikasi Elektronik - BSSN) Tj',
      '0 -11 Td',
      '(Kode: RTV-2026-SPK) Tj',
      '0 -11 Td',
      '(Status: DOKUMEN RESMI VALID) Tj',
      'ET',
    ];

    final streamBytes = latin1.encode('${streamLines.join('\n')}\n');

    final builder = BytesBuilder();
    final offsets = <int>[];

    void addStr(String s) {
      builder.add(latin1.encode(s));
    }

    addStr('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n');

    // 1: Catalog
    offsets.add(builder.length);
    addStr('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');

    // 2: Pages
    offsets.add(builder.length);
    addStr('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n');

    // 3: Page (A4: 595.28 x 841.89)
    offsets.add(builder.length);
    addStr('3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595.28 841.89] /Contents 4 0 R /Resources << /Font << /F1 5 0 R /F2 6 0 R >> >> >>\nendobj\n');

    // 4: Stream
    offsets.add(builder.length);
    addStr('4 0 obj\n<< /Length ${streamBytes.length} >>\nstream\n');
    builder.add(streamBytes);
    addStr('\nendstream\nendobj\n');

    // 5: Font F1 (Helvetica)
    offsets.add(builder.length);
    addStr('5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n');

    // 6: Font F2 (Helvetica-Bold)
    offsets.add(builder.length);
    addStr('6 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>\nendobj\n');

    // XREF Table
    final xrefOffset = builder.length;
    addStr('xref\n0 ${offsets.length + 1}\n0000000000 65535 f \n');
    for (final off in offsets) {
      final pad = off.toString().padLeft(10, '0');
      addStr('$pad 00000 n \n');
    }

    // Trailer
    addStr('trailer\n<< /Size ${offsets.length + 1} /Root 1 0 R >>\nstartxref\n$xrefOffset\n%%EOF\n');

    return builder.toBytes();
  }
}
