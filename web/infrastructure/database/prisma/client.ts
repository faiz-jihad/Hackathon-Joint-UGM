import { PrismaClient } from "@prisma/client";

const prismaClientSingleton = () => {
  return new PrismaClient({
    log: process.env.NODE_ENV === "development" ? ["query", "error", "warn"] : ["error"],
  });
};

const globalForPrisma = globalThis as unknown as {
  prismaGlobal: PrismaClient | undefined;
};

export const prisma = (globalForPrisma.prismaGlobal ?? prismaClientSingleton()) as PrismaClient & Record<string, any>;

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prismaGlobal = prisma;
}

