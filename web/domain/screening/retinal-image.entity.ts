export type EyePosition = "OD" | "OS"; // OD = Oculus Dexter (Mata Kanan), OS = Oculus Sinister (Mata Kiri)

export interface RetinalImageProps {
  id: string;
  screeningId: string;
  eye: EyePosition;
  storageKey: string; // Object storage key, NOT BLOB!
  mimeType: string;
  checksum: string; // SHA-256 hash
  fileSizeBytes?: number | null;
  uploadedAt: Date;
}

export class RetinalImage {
  private constructor(private readonly props: RetinalImageProps) {}

  public static create(
    props: Omit<RetinalImageProps, "id" | "uploadedAt"> & { id?: string }
  ): RetinalImage {
    if (!props.storageKey || props.storageKey.trim().length === 0) {
      throw new Error("Storage key must not be empty.");
    }

    if (!props.checksum || props.checksum.trim().length === 0) {
      throw new Error("Integrity checksum (SHA-256) is required for medical imaging.");
    }

    const validMimes = ["image/jpeg", "image/png", "image/webp", "image/tiff"];
    if (!validMimes.includes(props.mimeType)) {
      throw new Error(`Unsupported image MIME type: ${props.mimeType}. Allowed: ${validMimes.join(", ")}`);
    }

    return new RetinalImage({
      id: props.id || crypto.randomUUID(),
      screeningId: props.screeningId,
      eye: props.eye,
      storageKey: props.storageKey.trim(),
      mimeType: props.mimeType,
      checksum: props.checksum,
      fileSizeBytes: props.fileSizeBytes ?? null,
      uploadedAt: new Date(),
    });
  }

  public static reconstitute(props: RetinalImageProps): RetinalImage {
    return new RetinalImage(props);
  }

  public get id(): string { return this.props.id; }
  public get screeningId(): string { return this.props.screeningId; }
  public get eye(): EyePosition { return this.props.eye; }
  public get storageKey(): string { return this.props.storageKey; }
  public get mimeType(): string { return this.props.mimeType; }
  public get checksum(): string { return this.props.checksum; }
  public get fileSizeBytes(): number | null | undefined { return this.props.fileSizeBytes; }
  public get uploadedAt(): Date { return this.props.uploadedAt; }

  public toJSON() {
    return {
      id: this.id,
      screeningId: this.screeningId,
      eye: this.eye,
      storageKey: this.storageKey,
      mimeType: this.mimeType,
      checksum: this.checksum,
      fileSizeBytes: this.fileSizeBytes,
      uploadedAt: this.uploadedAt.toISOString(),
    };
  }
}
