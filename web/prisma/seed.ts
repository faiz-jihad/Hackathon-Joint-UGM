import { PrismaClient, UserRole } from "@prisma/client";
import bcrypt from "bcryptjs";

const prisma = new PrismaClient();

async function main() {
  console.log("🌱 Memulai proses seeding akun admin RETIVA...");

  const plainPassword = "password";
  const saltRounds = 12;
  const passwordHash = await bcrypt.hash(plainPassword, saltRounds);

  const admins = [
    {
      email: "admin@gmail.com",
      fullName: "Administrator RETIVA",
      role: UserRole.ADMIN,
      phoneNumber: "081234567890",
      isActive: true,
    },
    {
      email: "guntoroloa@gmail.com",
      fullName: "Guntoro Loa",
      role: UserRole.ADMIN,
      phoneNumber: "081298765432",
      isActive: true,
    },
  ];

  for (const adminData of admins) {
    const user = await prisma.user.upsert({
      where: { email: adminData.email },
      update: {
        fullName: adminData.fullName,
        role: adminData.role,
        passwordHash: passwordHash,
        isActive: adminData.isActive,
      },
      create: {
        email: adminData.email,
        fullName: adminData.fullName,
        role: adminData.role,
        passwordHash: passwordHash,
        phoneNumber: adminData.phoneNumber,
        isActive: adminData.isActive,
      },
    });

    console.log(`✅ Berhasil membuat/memperbarui akun admin: ${user.email} (${user.fullName}) [ID: ${user.id}]`);
  }

  console.log("✨ Seeding 2 akun admin RETIVA selesai dengan sukses!");
}

main()
  .catch((e) => {
    console.error("❌ Error saat seeding data admin:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
