import bcrypt from "bcryptjs";
import { PasswordHasher } from "@/domain/auth/password-hasher.interface";

export class BcryptPasswordHasher implements PasswordHasher {
  private readonly saltRounds = 12;

  async hash(plainText: string): Promise<string> {
    return bcrypt.hash(plainText, this.saltRounds);
  }

  async compare(plainText: string, hashed: string): Promise<boolean> {
    return bcrypt.compare(plainText, hashed);
  }
}
