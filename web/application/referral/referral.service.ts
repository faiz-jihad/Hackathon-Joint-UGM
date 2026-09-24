import { ReferralRepository } from "@/domain/referral/referral.repository";
import { FacilityRepository } from "@/domain/facility/facility.repository";
import { PatientRepository } from "@/domain/patient/patient.repository";
import { ScreeningRepository } from "@/domain/screening/screening.repository";
import { AuditRepository } from "@/domain/audit/audit.repository";
import { Referral, ReferralStatus } from "@/domain/referral/referral.entity";
import { UrgencyLevel } from "@/domain/recommendation/recommendation.entity";
import { NotFoundError, ForbiddenError, ValidationError } from "@/domain/common/errors";
import { AuthenticatedActor } from "@/infrastructure/security/auth.guard";

export interface CreateReferralDTO {
  screeningId: string;
  patientId: string;
  targetFacilityId: string;
  urgency?: UrgencyLevel;
  reason: string;
  clinicalSummary: string;
}

export class ReferralService {
  constructor(
    private readonly referralRepository: ReferralRepository,
    private readonly facilityRepository: FacilityRepository,
    private readonly patientRepository: PatientRepository,
    private readonly screeningRepository: ScreeningRepository,
    private readonly auditRepository: AuditRepository
  ) {}

  async createReferral(dto: CreateReferralDTO, actor: AuthenticatedActor): Promise<Referral> {
    if (actor.role === "PATIENT") {
      throw new ForbiddenError("Patients cannot self-issue clinical referral letters.");
    }

    const [patient, facility, screening] = await Promise.all([
      this.patientRepository.findById(dto.patientId),
      this.facilityRepository.findById(dto.targetFacilityId),
      this.screeningRepository.findById(dto.screeningId),
    ]);

    if (!patient) throw new NotFoundError("Patient", dto.patientId);
    if (!facility) throw new NotFoundError("Target Facility", dto.targetFacilityId);
    if (!screening) throw new NotFoundError("Screening", dto.screeningId);

    const referral = Referral.create({
      screeningId: dto.screeningId,
      patientId: dto.patientId,
      targetFacilityId: dto.targetFacilityId,
      urgency: dto.urgency || "MEDIUM",
      reason: dto.reason,
      clinicalSummary: dto.clinicalSummary,
      status: "ISSUED",
    });

    const savedReferral = await this.referralRepository.create(referral);

    // Update screening status to REFERRAL_RECOMMENDED
    (screening as any).props.status = "REFERRAL_RECOMMENDED";
    await this.screeningRepository.update(screening);

    await this.auditRepository.record({
      actorId: actor.id,
      actorRole: actor.role,
      action: "REFERRAL_ISSUED",
      resource: "Referral",
      resourceId: savedReferral.id,
      metadata: {
        screeningId: dto.screeningId,
        patientId: dto.patientId,
        targetFacilityName: facility.name,
        urgency: referral.urgency,
      },
    });

    return savedReferral;
  }

  async getReferralById(id: string, actor: AuthenticatedActor): Promise<{ referral: Referral; facility: any }> {
    const referral = await this.referralRepository.findById(id);
    if (!referral) {
      throw new NotFoundError("Referral", id);
    }

    if (actor.role === "PATIENT") {
      const patient = await this.patientRepository.findById(referral.patientId);
      if (!patient || patient.userId !== actor.id) {
        throw new ForbiddenError("Patients can only view their own referral letters.");
      }
    }

    const facility = await this.facilityRepository.findById(referral.targetFacilityId);

    return {
      referral,
      facility: facility ? facility.toJSON() : null,
    };
  }

  async updateReferralStatus(
    id: string,
    status: ReferralStatus,
    actor: AuthenticatedActor
  ): Promise<Referral> {
    const referral = await this.referralRepository.findById(id);
    if (!referral) {
      throw new NotFoundError("Referral", id);
    }

    if (status === "PATIENT_ATTENDED") {
      referral.markAttended();
    } else if (status === "CANCELLED") {
      referral.cancel();
    } else {
      (referral as any).props.status = status;
    }

    const updated = await this.referralRepository.update(referral);

    await this.auditRepository.record({
      actorId: actor.id,
      actorRole: actor.role,
      action: `REFERRAL_STATUS_${status}`,
      resource: "Referral",
      resourceId: referral.id,
      metadata: { status },
    });

    return updated;
  }
}
