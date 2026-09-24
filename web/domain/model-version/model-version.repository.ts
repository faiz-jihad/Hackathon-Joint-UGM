import { ModelVersion } from "./model-version.entity";

export interface ModelVersionRepository {
  findById(id: string): Promise<ModelVersion | null>;
  findByVersion(version: string): Promise<ModelVersion | null>;
  getActiveModel(): Promise<ModelVersion | null>;
  create(model: ModelVersion): Promise<ModelVersion>;
  listAll(): Promise<ModelVersion[]>;
  activate(id: string): Promise<ModelVersion>;
  deactivateAll(): Promise<void>;
}
