import { UserRepository } from "@/domain/auth/user.repository";
import { User, UserRole, normalizeUserRole, formatRoleDisplayName } from "@/domain/auth/user.entity";
import { PasswordHasher } from "@/domain/auth/password-hasher.interface";
import { TokenService, TokenPayload } from "@/domain/auth/token-service.interface";
import { ConflictError, UnauthorizedError, NotFoundError, ForbiddenError } from "@/domain/common/errors";

export interface RegisterDTO {
  email: string;
  password: string;
  fullName: string;
  role?: UserRole;
  phoneNumber?: string;
  facilityId?: string;
  nik?: string;
}

export interface LoginDTO {
  email: string;
  password: string;
  role?: UserRole;
}

export interface AuthResponseDTO {
  token: string;
  user: {
    id: string;
    email: string;
    fullName: string;
    role: UserRole;
    facilityId?: string | null;
  };
}

export class AuthService {
  constructor(
    private readonly userRepository: UserRepository,
    private readonly passwordHasher: PasswordHasher,
    private readonly tokenService: TokenService
  ) {}

  async register(dto: RegisterDTO): Promise<AuthResponseDTO> {
    const existing = await this.userRepository.findByEmail(dto.email);
    if (existing) {
      throw new ConflictError(`User with email ${dto.email} already exists.`);
    }

    const passwordHash = await this.passwordHasher.hash(dto.password);

    const user = User.create({
      email: dto.email,
      passwordHash,
      fullName: dto.fullName,
      role: dto.role || "PATIENT",
      phoneNumber: dto.phoneNumber,
      facilityId: dto.facilityId,
      isActive: true,
    });

    const savedUser = await this.userRepository.create(user);

    const tokenPayload: TokenPayload = {
      userId: savedUser.id,
      email: savedUser.email,
      role: savedUser.role,
      facilityId: savedUser.facilityId,
    };

    const token = this.tokenService.generateToken(tokenPayload);

    return {
      token,
      user: {
        id: savedUser.id,
        email: savedUser.email,
        fullName: savedUser.fullName,
        role: savedUser.role,
        facilityId: savedUser.facilityId,
      },
    };
  }

  async login(dto: LoginDTO): Promise<AuthResponseDTO> {
    const user = await this.userRepository.findByEmail(dto.email);
    if (!user) {
      throw new NotFoundError("Akun belum terdaftar di sistem RETIVA.", dto.email);
    }

    if (!user.isActive) {
      throw new UnauthorizedError("Akun dinonaktifkan. Silakan hubungi administrator.");
    }

    const targetRole = normalizeUserRole(dto.role);
    if (targetRole && user.role !== targetRole) {
      throw new ForbiddenError(
        `Akun ini memiliki peran ${formatRoleDisplayName(user.role)}, bukan ${formatRoleDisplayName(targetRole)}.`
      );
    }

    const isValid = await this.passwordHasher.compare(dto.password, user.passwordHash);
    if (!isValid) {
      throw new UnauthorizedError("Kata sandi yang Anda masukkan salah.");
    }

    const tokenPayload: TokenPayload = {
      userId: user.id,
      email: user.email,
      role: user.role,
      facilityId: user.facilityId,
    };

    const token = this.tokenService.generateToken(tokenPayload);

    return {
      token,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        role: user.role,
        facilityId: user.facilityId,
      },
    };
  }

  async loginWithGoogleProfile(profile: {
    email: string;
    fullName: string;
    role?: UserRole;
    facilityId?: string;
  }): Promise<AuthResponseDTO> {
    const cleanEmail = profile.email.toLowerCase().trim();
    let user = await this.userRepository.findByEmail(cleanEmail);

    if (!user) {
      // Auto-provision user baru via Google Auth (Role Pengguna / PATIENT secara default)
      const targetRole = normalizeUserRole(profile.role) || "PATIENT";
      const randomPasswordHash = await this.passwordHasher.hash(
        `retiva-google-oauth-${Date.now()}-${Math.random().toString(36).substring(2, 10)}`
      );

      const newUser = User.create({
        email: cleanEmail,
        passwordHash: randomPasswordHash,
        fullName: profile.fullName?.trim() || cleanEmail.split("@")[0],
        role: targetRole,
        facilityId: profile.facilityId || null,
        isActive: true,
      });

      user = await this.userRepository.create(newUser);
    }

    if (!user.isActive) {
      throw new UnauthorizedError("Akun dinonaktifkan. Silakan hubungi administrator.");
    }

    const targetRole = normalizeUserRole(profile.role);
    if (targetRole && user.role !== targetRole) {
      throw new ForbiddenError(
        `Akun ini memiliki peran ${formatRoleDisplayName(user.role)}, bukan ${formatRoleDisplayName(targetRole)}.`
      );
    }

    const tokenPayload: TokenPayload = {
      userId: user.id,
      email: user.email,
      role: user.role,
      facilityId: user.facilityId,
    };

    const token = this.tokenService.generateToken(tokenPayload);

    return {
      token,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        role: user.role,
        facilityId: user.facilityId,
      },
    };
  }

  async getCurrentUser(userId: string): Promise<User> {
    const user = await this.userRepository.findById(userId);
    if (!user) {
      throw new NotFoundError("User", userId);
    }
    return user;
  }
}
