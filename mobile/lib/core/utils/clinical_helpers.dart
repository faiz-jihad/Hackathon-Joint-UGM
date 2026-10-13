import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ClinicalHelpers {
  static String getSeverityTitle(String? classification) {
    switch (classification?.toUpperCase()) {
      case 'NO_DR':
        return 'Tidak Tampak DR (Derajat 0)';
      case 'MILD_DR':
      case 'MILD_NPDR':
        return 'NPDR Ringan (Derajat 1)';
      case 'MODERATE_DR':
      case 'MODERATE_NPDR':
        return 'NPDR Sedang (Derajat 2)';
      case 'SEVERE_DR':
      case 'SEVERE_NPDR':
        return 'NPDR Berat (Derajat 3)';
      case 'PROLIFERATIVE_DR':
      case 'PDR':
        return 'PDR Proliferatif (Derajat 4)';
      default:
        return 'Belum Terklasifikasi';
    }
  }

  static String getSeverityDescription(String? classification) {
    switch (classification?.toUpperCase()) {
      case 'NO_DR':
        return 'Tidak ditemukan tanda lesi mikrovaskular retina. Makula dan diskus optikus tampak tenang.';
      case 'MILD_DR':
      case 'MILD_NPDR':
        return 'Ditemukan mikroaneurisma fokal terisolasi tanpa eksudat atau perdarahan intraretina luas.';
      case 'MODERATE_DR':
      case 'MODERATE_NPDR':
        return 'Ditemukan mikroaneurisma multipel, perdarahan dot-blot, eksudat keras, atau cotton-wool spots.';
      case 'SEVERE_DR':
      case 'SEVERE_NPDR':
        return 'Memenuhi salah satu kriteria aturan 4-2-1 Perdami. Risiko konversi ke proliferatif tinggi dalam 1 tahun.';
      case 'PROLIFERATIVE_DR':
      case 'PDR':
        return 'Ditemukan neovaskularisasi retina/diskus (NVD/NVE), perdarahan vitreus, atau ablasio traksional.';
      default:
        return 'Menunggu evaluasi hasil inferensi.';
    }
  }

  static Color getSeverityColor(String? classification) {
    switch (classification?.toUpperCase()) {
      case 'NO_DR':
        return AppColors.statusGreen;
      case 'MILD_DR':
      case 'MILD_NPDR':
        return AppColors.statusYellow;
      case 'MODERATE_DR':
      case 'MODERATE_NPDR':
        return AppColors.statusOrange;
      case 'SEVERE_DR':
      case 'SEVERE_NPDR':
      case 'PROLIFERATIVE_DR':
      case 'PDR':
        return AppColors.statusRed;
      default:
        return AppColors.textMuted;
    }
  }

  static Color getSeveritySurfaceColor(String? classification) {
    switch (classification?.toUpperCase()) {
      case 'NO_DR':
        return AppColors.statusGreenSurface;
      case 'MILD_DR':
      case 'MILD_NPDR':
        return AppColors.statusYellowSurface;
      case 'MODERATE_DR':
      case 'MODERATE_NPDR':
        return AppColors.statusOrangeSurface;
      case 'SEVERE_DR':
      case 'SEVERE_NPDR':
      case 'PROLIFERATIVE_DR':
      case 'PDR':
        return AppColors.statusRedSurface;
      default:
        return AppColors.background;
    }
  }

  static String getPerdamiInterval(String? classification) {
    switch (classification?.toUpperCase()) {
      case 'NO_DR':
        return 'Kontrol Ulang 12 Bulan (FKTP)';
      case 'MILD_DR':
      case 'MILD_NPDR':
        return 'Kontrol Ulang 6–12 Bulan (FKTP)';
      case 'MODERATE_DR':
      case 'MODERATE_NPDR':
        return 'Rujukan Sp.M dalam 3–6 Bulan (FKRTL)';
      case 'SEVERE_DR':
      case 'SEVERE_NPDR':
        return 'Rujukan Cepat 2–4 Minggu (FKRTL / Laser PRP)';
      case 'PROLIFERATIVE_DR':
      case 'PDR':
        return 'Rujukan Darurat Segera (< 1–2 Minggu)';
      default:
        return 'Sesuai arahan klinisi';
    }
  }
}
