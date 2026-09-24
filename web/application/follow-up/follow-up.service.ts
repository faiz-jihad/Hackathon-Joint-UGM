import { FollowUpRepository, FollowUpSearchParams } from "@/domain/follow-up/follow-up.repository";
import { PatientRepository } from "@/domain/patient/patient.repository";
import { ScreeningRepository } from "@/domain/screening/screening.repository";
import { ReferralRepository } from "@/domain/referral/referral.repository";
import { DiabetesProfileRepository } from "@/domain/patient/diabetes-profile.repository";
import { AuditRepository } from "@/domain/audit/audit.repository";
import { FollowUp, FollowUpStatus } from "@/domain/follow-up/follow-up.entity";
import { NotFoundError, ForbiddenError } from "@/domain/common/errors";
import { AuthenticatedActor } from "@/infrastructure/security/auth.guard";

export interface ScheduleFollowUpDTO {
  patientId: string;
  screeningId?: string;
  dueDate: string; // ISO date string
  notes?: string;
}

export class FollowUpService {
  constructor(
    private readonly followUpRepository: FollowUpRepository,
    private readonly patientRepository: PatientRepository,
    private readonly screeningRepository: ScreeningRepository,
    private readonly referralRepository: ReferralRepository,
    private readonly diabetesProfileRepository: DiabetesProfileRepository,
    private readonly auditRepository: AuditRepository
  ) {}

  async scheduleFollowUp(dto: ScheduleFollowUpDTO, actor: AuthenticatedActor): Promise<FollowUp> {
    const patient = await this.patientRepository.findById(dto.patientId);
    if (!patient) {
      throw new NotFoundError("Patient", dto.patientId);
    }

    const followUp = FollowUp.create({
      patientId: dto.patientId,
      screeningId: dto.screeningId,
      dueDate: new Date(dto.dueDate),
      completionNotes: dto.notes,
    });

    const saved = await this.followUpRepository.create(followUp);

    // If linked to a screening, advance screening state to FOLLOW_UP_REQUIRED
    if (dto.screeningId) {
      const screening = await this.screeningRepository.findById(dto.screeningId);
      if (screening) {
        (screening as any).props.status = "FOLLOW_UP_REQUIRED";
        await this.screeningRepository.update(screening);
      }
    }

    await this.auditRepository.record({
      actorId: actor.id,
      actorRole: actor.role,
      action: "FOLLOW_UP_SCHEDULED",
      resource: "FollowUp",
      resourceId: saved.id,
      metadata: {
        patientId: dto.patientId,
        dueDate: dto.dueDate,
      },
    });

    return saved;
  }

  async completeFollowUp(id: string, notes: string | undefined, actor: AuthenticatedActor): Promise<FollowUp> {
    const followUp = await this.followUpRepository.findById(id);
    if (!followUp) {
      throw new NotFoundError("FollowUp", id);
    }

    followUp.complete(notes);
    const updated = await this.followUpRepository.update(followUp);

    // If linked to screening, mark screening state as FOLLOW_UP_COMPLETED
    if (followUp.screeningId) {
      const screening = await this.screeningRepository.findById(followUp.screeningId);
      if (screening) {
        (screening as any).props.status = "FOLLOW_UP_COMPLETED";
        await this.screeningRepository.update(screening);
      }
    }

    await this.auditRepository.record({
      actorId: actor.id,
      actorRole: actor.role,
      action: "FOLLOW_UP_COMPLETED",
      resource: "FollowUp",
      resourceId: updated.id,
      metadata: { patientId: followUp.patientId },
    });

    return updated;
  }

  async getFollowUpsByPatient(patientId: string, actor: AuthenticatedActor): Promise<FollowUp[]> {
    const patient = await this.patientRepository.findById(patientId);
    if (!patient) throw new NotFoundError("Patient", patientId);

    if (actor.role === "PATIENT" && patient.userId !== actor.id) {
      throw new ForbiddenError("Patients can only view their own follow-up schedules.");
    }

    return this.followUpRepository.findByPatientId(patientId);
  }

  async searchFollowUps(params: FollowUpSearchParams, actor: AuthenticatedActor) {
    if (actor.role === "PATIENT") {
      throw new ForbiddenError("Patients are not authorized to query global follow-up schedules.");
    }
    return this.followUpRepository.search(params);
  }

  /**
   * Longitudinal Patient Screening History
   * Aggregates patient demography, diabetes parameters, screening timeline,
   * AI/human results, referrals, and follow-up adherence.
   */
  async getPatientHistory(patientId: string, actor: AuthenticatedActor): Promise<any> {
    const patient = await this.patientRepository.findById(patientId);
    if (!patient) throw new NotFoundError("Patient", patientId);

    if (actor.role === "PATIENT" && patient.userId !== actor.id) {
      throw new ForbiddenError("Patients can only view their own screening history.");
    }

    const [diabetesProfile, screeningSearchResult, referrals, followUps] = await Promise.all([
      this.diabetesProfileRepository.findByPatientId(patientId),
      this.screeningRepository.search({ patientId, limit: 100 }),
      this.referralRepository.findByPatientId(patientId),
      this.followUpRepository.findByPatientId(patientId),
    ]);

    // Build timeline items
    const timeline = screeningSearchResult.screenings.map((s) => ({
      screeningId: s.id,
      date: s.createdAt,
      status: s.status,
      conductedById: s.conductedById,
      imagesCount: s.images.length,
      qualityCheckSummary: Array.from(s.qualityChecks.values()).map((q) => ({
        passed: q.passed,
        score: q.overallScore,
        reason: q.retakeReason,
      })),
      aiFinding: s.aiResult ? s.aiResult.toJSON() : null,
      reliabilityFinding: s.reliabilityAssessment ? s.reliabilityAssessment.toJSON() : null,
    }));

    return {
      patient: patient.toJSON(),
      diabetesProfile: diabetesProfile ? diabetesProfile.toJSON() : null,
      totalScreenings: screeningSearchResult.total,
      timeline,
      referrals: referrals.map((r) => r.toJSON()),
      followUps: followUps.map((f) => f.toJSON()),
    };
  }
}
