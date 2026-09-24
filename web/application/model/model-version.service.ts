import { ModelVersionRepository } from "@/domain/model-version/model-version.repository";
import { ModelVersion } from "@/domain/model-version/model-version.entity";
import { AuditRepository } from "@/domain/audit/audit.repository";
import { NotFoundError, ForbiddenError, ConflictError } from "@/domain/common/errors";
import { AuthenticatedActor } from "@/infrastructure/security/auth.guard";

export interface RegisterModelDTO {
  modelName: string;
  version: string;
  pipelineVersion: string;
  weightsHash: string;
  isActive?: boolean;
}

export class ModelVersionService {
  constructor(
    private readonly modelVersionRepository: ModelVersionRepository,
    private readonly auditRepository: AuditRepository
  ) {}

  async listModels(): Promise<ModelVersion[]> {
    return this.modelVersionRepository.listAll();
  }

  async getModelById(id: string): Promise<ModelVersion> {
    const model = await this.modelVersionRepository.findById(id);
    if (!model) {
      throw new NotFoundError("ModelVersion", id);
    }
    return model;
  }

  async getActiveModel(): Promise<ModelVersion | null> {
    return this.modelVersionRepository.getActiveModel();
  }

  async registerModel(dto: RegisterModelDTO, actor: AuthenticatedActor): Promise<ModelVersion> {
    if (actor.role !== "ADMIN") {
      throw new ForbiddenError("Only system administrators can register new AI model versions.");
    }

    const existing = await this.modelVersionRepository.findByVersion(dto.version);
    if (existing) {
      throw new ConflictError(`Model version ${dto.version} already exists.`);
    }

    // If activating new model, deactivate others via repository
    if (dto.isActive) {
      await this.modelVersionRepository.deactivateAll();
    }

    const model = ModelVersion.create({
      modelName: dto.modelName,
      version: dto.version,
      pipelineVersion: dto.pipelineVersion,
      weightsHash: dto.weightsHash,
      isActive: dto.isActive ?? true,
    });

    const saved = await this.modelVersionRepository.create(model);

    await this.auditRepository.record({
      actorId: actor.id,
      actorRole: actor.role,
      action: "MODEL_VERSION_REGISTERED",
      resource: "ModelVersion",
      resourceId: saved.id,
      metadata: {
        version: saved.version,
        weightsHash: saved.weightsHash,
      },
    });

    return saved;
  }

  async activateModel(id: string, actor: AuthenticatedActor): Promise<ModelVersion> {
    if (actor.role !== "ADMIN") {
      throw new ForbiddenError("Only system administrators can activate model versions.");
    }

    const targetModel = await this.modelVersionRepository.findById(id);
    if (!targetModel) {
      throw new NotFoundError("ModelVersion", id);
    }

    const updated = await this.modelVersionRepository.activate(id);

    await this.auditRepository.record({
      actorId: actor.id,
      actorRole: actor.role,
      action: "MODEL_VERSION_ACTIVATED",
      resource: "ModelVersion",
      resourceId: id,
      metadata: {
        version: targetModel.version,
      },
    });

    return updated!;
  }
}
