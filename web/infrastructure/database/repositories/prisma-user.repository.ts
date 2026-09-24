import { UserRepository } from "@/domain/auth/user.repository";
import { User, UserRole } from "@/domain/auth/user.entity";
import { prisma } from "../prisma/client";

export class PrismaUserRepository implements UserRepository {
  async findById(id: string): Promise<User | null> {
    const record = await prisma.user.findUnique({
      where: { id },
    });
    if (!record) return null;
    return this.toDomain(record);
  }

  async findByEmail(email: string): Promise<User | null> {
    const record = await prisma.user.findUnique({
      where: { email: email.toLowerCase().trim() },
    });
    if (!record) return null;
    return this.toDomain(record);
  }

  async create(user: User): Promise<User> {
    const record = await prisma.user.create({
      data: {
        id: user.id,
        email: user.email,
        passwordHash: user.passwordHash,
        role: user.role,
        fullName: user.fullName,
        phoneNumber: user.phoneNumber,
        facilityId: user.facilityId,
        isActive: user.isActive,
      },
    });
    return this.toDomain(record);
  }

  async update(user: User): Promise<User> {
    const record = await prisma.user.update({
      where: { id: user.id },
      data: {
        email: user.email,
        passwordHash: user.passwordHash,
        role: user.role,
        fullName: user.fullName,
        phoneNumber: user.phoneNumber,
        facilityId: user.facilityId,
        isActive: user.isActive,
      },
    });
    return this.toDomain(record);
  }

  async delete(id: string): Promise<void> {
    await prisma.user.delete({
      where: { id },
    });
  }

  private toDomain(record: {
    id: string;
    email: string;
    passwordHash: string;
    role: string;
    fullName: string;
    phoneNumber: string | null;
    facilityId: string | null;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
  }): User {
    return User.reconstitute({
      id: record.id,
      email: record.email,
      passwordHash: record.passwordHash,
      role: record.role as UserRole,
      fullName: record.fullName,
      phoneNumber: record.phoneNumber,
      facilityId: record.facilityId,
      isActive: record.isActive,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    });
  }
}
