import jwt from "jsonwebtoken";
import { TokenPayload, TokenService } from "@/domain/auth/token-service.interface";

export class JwtTokenService implements TokenService {
  private readonly secret: string;
  private readonly expiresIn: string;

  constructor() {
    this.secret = process.env.JWT_SECRET || "retiva-default-dev-secret-key-change-in-prod";
    this.expiresIn = process.env.JWT_EXPIRES_IN || "7d";
  }

  generateToken(payload: TokenPayload): string {
    return jwt.sign(payload, this.secret, {
      expiresIn: this.expiresIn,
    } as jwt.SignOptions);
  }

  verifyToken(token: string): TokenPayload | null {
    try {
      const decoded = jwt.verify(token, this.secret) as TokenPayload;
      return decoded;
    } catch {
      return null;
    }
  }
}
