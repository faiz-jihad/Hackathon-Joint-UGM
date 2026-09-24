import { NextRequest } from "next/server";
import { JwtTokenService } from "./jwt-token.service";
import { TokenPayload } from "@/domain/auth/token-service.interface";
import { UnauthorizedError, ForbiddenError } from "@/domain/common/errors";
import { UserRole } from "@/domain/auth/user.entity";

const tokenService = new JwtTokenService();

export interface AuthenticatedActor {
  id: string;
  email: string;
  role: UserRole;
  facilityId?: string | null;
}

export class AuthGuard {
  public static authenticate(req: NextRequest): AuthenticatedActor {
    const authHeader = req.headers.get("authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      throw new UnauthorizedError("Missing or malformed Authorization header. Bearer token required.");
    }

    const token = authHeader.split(" ")[1];
    const payload = tokenService.verifyToken(token);

    if (!payload) {
      throw new UnauthorizedError("Session expired or invalid token.");
    }

    return {
      id: payload.userId,
      email: payload.email,
      role: payload.role,
      facilityId: payload.facilityId,
    };
  }

  public static requireRole(actor: AuthenticatedActor, allowedRoles: UserRole[]): void {
    if (!allowedRoles.includes(actor.role)) {
      throw new ForbiddenError(
        `Role '${actor.role}' is not authorized to access this resource. Allowed: ${allowedRoles.join(", ")}`
      );
    }
  }
}
