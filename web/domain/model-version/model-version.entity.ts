export interface ModelVersionProps {
  id: string;
  modelName: string;
  version: string; // e.g. "efficientnet-b3-v1.0.0"
  pipelineVersion: string; // e.g. "dr-pipe-v1.2"
  weightsHash: string; // SHA-256 integrity hash of model weights
  isActive: boolean;
  deployedAt: Date;
}

export class ModelVersion {
  private constructor(private readonly props: ModelVersionProps) {}

  public static create(
    props: Omit<ModelVersionProps, "id" | "deployedAt"> & { id?: string }
  ): ModelVersion {
    if (!props.modelName || props.modelName.trim().length === 0) {
      throw new Error("Model name is required.");
    }
    if (!props.version || props.version.trim().length === 0) {
      throw new Error("Model version string is required.");
    }

    return new ModelVersion({
      id: props.id || crypto.randomUUID(),
      modelName: props.modelName.trim(),
      version: props.version.trim(),
      pipelineVersion: props.pipelineVersion.trim(),
      weightsHash: props.weightsHash,
      isActive: props.isActive ?? true,
      deployedAt: new Date(),
    });
  }

  public static reconstitute(props: ModelVersionProps): ModelVersion {
    return new ModelVersion(props);
  }

  public get id(): string { return this.props.id; }
  public get modelName(): string { return this.props.modelName; }
  public get version(): string { return this.props.version; }
  public get pipelineVersion(): string { return this.props.pipelineVersion; }
  public get weightsHash(): string { return this.props.weightsHash; }
  public get isActive(): boolean { return this.props.isActive; }
  public get deployedAt(): Date { return this.props.deployedAt; }

  public toJSON() {
    return {
      id: this.id,
      modelName: this.modelName,
      version: this.version,
      pipelineVersion: this.pipelineVersion,
      weightsHash: this.weightsHash,
      isActive: this.isActive,
      deployedAt: this.deployedAt.toISOString(),
    };
  }
}
