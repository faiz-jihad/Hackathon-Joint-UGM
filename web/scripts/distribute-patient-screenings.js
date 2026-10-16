const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('Distributing patient screenings across distinct accounts...');

  // 1. Ensure additional realistic patients exist
  const additionalPatients = [
    {
      id: 'pat-007',
      nik: '3471011408800003',
      fullName: 'Bapak Haryanto Wijaya',
      birthDate: new Date('1980-08-14'),
      gender: 'MALE',
      phone: '081566778899',
      address: 'Jl. Kaliurang Km 5, Sleman',
    },
    {
      id: 'pat-008',
      nik: '3404012204700005',
      fullName: 'Bapak Agus Salim',
      birthDate: new Date('1970-04-22'),
      gender: 'MALE',
      phone: '081988776655',
      address: 'Jl. Godean Km 3, Yogyakarta',
    },
    {
      id: 'pat-009',
      nik: '3404051908740002',
      fullName: 'Bapak Hendro Kusumo',
      birthDate: new Date('1974-08-19'),
      gender: 'MALE',
      phone: '081223344556',
      address: 'Jl. Magelang Km 7, Mlati, Sleman',
    },
  ];

  for (const p of additionalPatients) {
    await prisma.patient.upsert({
      where: { id: p.id },
      update: { fullName: p.fullName, nik: p.nik },
      create: p,
    });
  }

  // 2. Specific mapping for prominent RTV screenings so every case has a unique person
  const specificScreeningMap = {
    'RTV-20261015-16': 'pat-001', // Bapak Sutrisno
    'RTV-20261015-26': 'pat-003', // Ibu Ratna Dewi
    'RTV-20261015-28': 'pat-003', // Ibu Ratna Dewi
    'RTV-20261015-33': 'pat-005', // Bapak Wahyu Hidayat
    'RTV-20261015-39': 'pat-006', // Ibu Endang Rahayu
    'RTV-20261016-16': 'pat-004', // Bapak Bambang Sudarmono
    'RTV-20261016-18': 'pat-007', // Bapak Haryanto Wijaya
    'RTV-20261016-26': 'pat-002', // Ny. Siti Aminah
    'RTV-20261016-27': 'pat-002', // Ny. Siti Aminah
    'RTV-20261016-40': 'pat-004', // Bapak Bambang Sudarmono
    'RTV-20261016-56': 'pat-006', // Ibu Endang Rahayu
    'RTV-20261016-71': 'pat-008', // Bapak Agus Salim
    'RTV-20261024-36': 'pat-009', // Bapak Hendro Kusumo
  };

  for (const [screeningId, patientId] of Object.entries(specificScreeningMap)) {
    try {
      await prisma.screening.update({
        where: { id: screeningId },
        data: { patientId },
      });
      console.log(`Updated screening ${screeningId} -> patient ${patientId}`);
    } catch (e) {
      // If screening doesn't exist in DB, continue
    }
  }

  // 3. For any remaining scr_ screenings that still point to Asep, rotate them
  const remaining = await prisma.screening.findMany({
    where: { patientId: 'b74e26e2-ce9d-4791-98c8-ff084eda97da' },
  });

  const patientPool = [
    'pat-001',
    'pat-002',
    'pat-003',
    'pat-004',
    'pat-005',
    'pat-006',
    'pat-007',
    'pat-008',
    'pat-009',
  ];

  let idx = 0;
  for (const s of remaining) {
    // Keep at most 1 case for Asep if desired, distribute others
    if (idx === 0) {
      idx++;
      continue;
    }
    const assignedPat = patientPool[idx % patientPool.length];
    await prisma.screening.update({
      where: { id: s.id },
      data: { patientId: assignedPat },
    });
    console.log(`Rotated scr screening ${s.id} -> ${assignedPat}`);
    idx++;
  }

  console.log('Patient screenings successfully distributed!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
