import { UserRole } from "./user.entity";

export interface TokenPayload {
  userId: string;
  email: string;
  role: UserRole;
  facilityId?: string | null;
}

export interface TokenService {
  generateToken(payload: TokenPayload): string;
  verifyToken(token: string): TokenPayload | null;
}
