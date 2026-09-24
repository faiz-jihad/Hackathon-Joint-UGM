import { ModelVersionRepository } from "@/domain/model-version/model-version.repository";
import { ModelVersion } from "@/domain/model-version/model-version.entity";
import { prisma } from "../prisma/client";

export class PrismaModelVersionRepository implements ModelVersionRepository {
  async findById(id: string): Promise<ModelVersion | null> {
    const record = await prisma.modelVersion.findUnique({
      where: { id },
    });
    if (!record) return null;
    return this.toDomain(record);
  }

  async findByVersion(version: string): Promise<ModelVersion | null> {
    const record = await prisma.modelVersion.findUnique({
      where: { version },
    });
    if (!record) return null;
    return this.toDomain(record);
  }

  async getActiveModel(): Promise<ModelVersion | null> {
    const record = await prisma.modelVersion.findFirst({
      where: { isActive: true },
      orderBy: { deployedAt: "desc" },
    });
    if (!record) return null;
    return this.toDomain(record);
  }

  async create(model: ModelVersion): Promise<ModelVersion> {
    const record = await prisma.modelVersion.create({
      data: {
        id: model.id,
        modelName: model.modelName,
        version: model.version,
        pipelineVersion: model.pipelineVersion,
        weightsHash: model.weightsHash,
        isActive: model.isActive,
      },
    });
    return this.toDomain(record);
  }

  async listAll(): Promise<ModelVersion[]> {
    const records = await prisma.modelVersion.findMany({
      orderBy: { deployedAt: "desc" },
    });
    return records.map((r) => this.toDomain(r));
  }

  async deactivateAll(): Promise<void> {
    await prisma.modelVersion.updateMany({
      where: { isActive: true },
      data: { isActive: false },
    });
  }

  async activate(id: string): Promise<ModelVersion> {
    await prisma.$transaction([
      prisma.modelVersion.updateMany({
        data: { isActive: false },
      }),
      prisma.modelVersion.update({
        where: { id },
        data: { isActive: true },
      }),
    ]);
    const updated = await this.findById(id);
    if (!updated) throw new Error(`Model version ${id} not found after activation.`);
    return updated;
  }

  private toDomain(record: {
    id: string;
    modelName: string;
    version: string;
    pipelineVersion: string;
    weightsHash: string;
    isActive: boolean;
    deployedAt: Date;
  }): ModelVersion {
    return ModelVersion.reconstitute({
      id: record.id,
      modelName: record.modelName,
      version: record.version,
      pipelineVersion: record.pipelineVersion,
      weightsHash: record.weightsHash,
      isActive: record.isActive,
      deployedAt: record.deployedAt,
    });
  }
}
