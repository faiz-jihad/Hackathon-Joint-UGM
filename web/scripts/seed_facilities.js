const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const facilitiesData = [
  {
    id: 'fac-sleman-01',
    name: 'Puskesmas Sleman (FKTP)',
    address: 'Jl. Bhayangkara No.27, Triharjo, Kec. Sleman, Kabupaten Sleman, D.I. Yogyakarta',
    latitude: -7.6894,
    longitude: 110.3444,
    bpjsStatus: 'ACCEPTED',
    isVerified: true,
    contactPhone: '(0274) 868351',
    services: ['PRIMARY_DIABETES_CARE', 'FUNDUS_CAMERA_SCREENING', 'CDSS_TRIAGE'],
    insurances: ['BPJS_KESEHATAN'],
  },
  {
    id: 'fac-mlati-02',
    name: 'Puskesmas Mlati II (FKTP)',
    address: 'Jl. Kebon Agung, Cabakan, Sumberadi, Kec. Mlati, Kabupaten Sleman, D.I. Yogyakarta',
    latitude: -7.7312,
    longitude: 110.3541,
    bpjsStatus: 'ACCEPTED',
    isVerified: true,
    contactPhone: '(0274) 869112',
    services: ['PRIMARY_DIABETES_CARE', 'CDSS_SCREENING'],
    insurances: ['BPJS_KESEHATAN'],
  },
  {
    id: 'fac-depok-01',
    name: 'Puskesmas Depok I (FKTP)',
    address: 'Jl. Babarsari No. 1, Caturtunggal, Kec. Depok, Kabupaten Sleman, D.I. Yogyakarta',
    latitude: -7.7812,
    longitude: 110.4124,
    bpjsStatus: 'ACCEPTED',
    isVerified: true,
    contactPhone: '(0274) 485123',
    services: ['PRIMARY_DIABETES_CARE', 'FUNDUS_CAMERA_SCREENING', 'KONSULTASI_RETINOPATI'],
    insurances: ['BPJS_KESEHATAN'],
  },
  {
    id: 'fac-gamping-01',
    name: 'Puskesmas Gamping I (FKTP)',
    address: 'Jl. Wates Km. 5, Ambarketawang, Kec. Gamping, Kabupaten Sleman, D.I. Yogyakarta',
    latitude: -7.7954,
    longitude: 110.3245,
    bpjsStatus: 'ACCEPTED',
    isVerified: true,
    contactPhone: '(0274) 381992',
    services: ['PRIMARY_DIABETES_CARE', 'PEMERIKSAAN_RETINA_DASAR'],
    insurances: ['BPJS_KESEHATAN'],
  },
  {
    id: 'fac-yap-01',
    name: 'RS Khusus Mata Dr. Yap (FKRTL - Tipe B)',
    address: 'Jl. Cik Di Tiro No.5, Terban, Gondokusuman, Kota Yogyakarta, D.I. Yogyakarta',
    latitude: -7.7797,
    longitude: 110.3758,
    bpjsStatus: 'ACCEPTED',
    isVerified: true,
    contactPhone: '(0274) 562054',
    services: [
      'RETINA_SUBSPECIALIST',
      'VITREORETINAL_SURGERY',
      'LASER_PHOTOCOAGULATION_PRP',
      'OCT_MACULAR_SCAN',
      'FLUORESCEIN_ANGIOGRAPHY',
    ],
    insurances: ['BPJS_KESEHATAN', 'MANDIRI_INHEALTH'],
  },
  {
    id: 'fac-sardjito-01',
    name: 'RSUP Dr. Sardjito (FKRTL - Rujukan Nasional Tipe A)',
    address: 'Jl. Kesehatan No.1, Sekip, Sinduadi, Mlati, Kabupaten Sleman, D.I. Yogyakarta',
    latitude: -7.7686,
    longitude: 110.3737,
    bpjsStatus: 'ACCEPTED',
    isVerified: true,
    contactPhone: '(0274) 631190',
    services: [
      'VITREORETINAL_CENTER',
      'RETINA_SURGERY_COMPLEX',
      'ANTI_VEGF_INJECTION',
      'OCT_ANGIOGRAPHY',
    ],
    insurances: ['BPJS_KESEHATAN', 'MANDIRI_INHEALTH'],
  },
  {
    id: 'fac-rsa-ugm-01',
    name: 'RS Akademik UGM / RSA UGM (FKRTL - Tipe B)',
    address: 'Jl. Kabupaten, Kronggahan, Trihanggo, Gamping, Sleman, D.I. Yogyakarta',
    latitude: -7.7431,
    longitude: 110.3503,
    bpjsStatus: 'ACCEPTED',
    isVerified: true,
    contactPhone: '(0274) 4530404',
    services: ['OPHTHALMOLOGY_CLINIC', 'DIABETIC_EYE_SCREENING', 'LASER_PRP'],
    insurances: ['BPJS_KESEHATAN'],
  },
  {
    id: 'fac-rsud-sleman-01',
    name: 'RSUD Sleman (FKRTL - Tipe B)',
    address: 'Jl. Bhayangkara No. 48, Murangan, Triharjo, Kec. Sleman, Kabupaten Sleman, D.I. Yogyakarta',
    latitude: -7.6912,
    longitude: 110.3458,
    bpjsStatus: 'ACCEPTED',
    isVerified: true,
    contactPhone: '(0274) 868437',
    services: ['POLI_SPESIALIS_MATA', 'SKRINING_KOMPLIKASI_DIABETES', 'BEDAH_KATARAK_RETINA'],
    insurances: ['BPJS_KESEHATAN', 'JAMKESDA'],
  },
  {
    id: 'fac-bethesda-01',
    name: 'RS Bethesda Yogyakarta (FKRTL - Tipe B)',
    address: 'Jl. Jend. Sudirman No. 70, Kotabaru, Gondokusuman, Yogyakarta',
    latitude: -7.7831,
    longitude: 110.3779,
    bpjsStatus: 'NEEDS_CONFIRMATION',
    isVerified: false,
    contactPhone: '(0274) 586688',
    services: ['POLI_MATA_TERPADU', 'SKRINING_DIABETES_KOMPREHENSIF'],
    insurances: ['BPJS_KESEHATAN', 'ASURANSI_SWASTA'],
  }
];

async function seed() {
  for (const f of facilitiesData) {
    await prisma.facility.upsert({
      where: { id: f.id },
      update: {
        name: f.name,
        address: f.address,
        latitude: f.latitude,
        longitude: f.longitude,
        bpjsStatus: f.bpjsStatus,
        isVerified: f.isVerified,
        contactPhone: f.contactPhone,
      },
      create: {
        id: f.id,
        name: f.name,
        address: f.address,
        latitude: f.latitude,
        longitude: f.longitude,
        bpjsStatus: f.bpjsStatus,
        isVerified: f.isVerified,
        contactPhone: f.contactPhone,
      },
    });

    for (const serviceName of f.services) {
      const existing = await prisma.facilityService.findFirst({
        where: { facilityId: f.id, serviceName },
      });
      if (!existing) {
        await prisma.facilityService.create({
          data: { facilityId: f.id, serviceName },
        });
      }
    }

    for (const insuranceName of f.insurances) {
      const existing = await prisma.facilityInsurance.findFirst({
        where: { facilityId: f.id, insuranceName },
      });
      if (!existing) {
        await prisma.facilityInsurance.create({
          data: { facilityId: f.id, insuranceName, status: 'ACTIVE' },
        });
      }
    }
  }
  console.log('SUCCESS: Faskes seeded count =', facilitiesData.length);
  process.exit(0);
}

seed().catch(err => {
  console.error(err);
  process.exit(1);
});
