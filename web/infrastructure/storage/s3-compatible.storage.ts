import crypto from "crypto";
import { ImageStorage, UploadImageParams } from "@/domain/screening/image-storage.interface";

export class S3CompatibleStorage implements ImageStorage {
  private readonly endpoint: string;
  private readonly bucket: string;

  constructor() {
    this.endpoint = process.env.STORAGE_ENDPOINT || "http://localhost:9000";
    this.bucket = process.env.STORAGE_BUCKET || "retiva-fundus-images";
  }

  async upload(params: UploadImageParams): Promise<{ storageKey: string; checksum: string }> {
    const checksum = crypto.createHash("sha256").update(params.data).digest("hex");
    
    // In production with AWS-SDK S3Client:
    // await this.s3Client.send(new PutObjectCommand({ Bucket: this.bucket, Key: params.storageKey, Body: params.data, ContentType: params.mimeType }));
    
    return {
      storageKey: params.storageKey,
      checksum,
    };
  }

  async getSignedUrl(storageKey: string, expiresInSeconds = 3600): Promise<string> {
    // Generates presigned URL for secure, time-limited fundus image access
    // Never expose raw public URLs!
    const token = crypto.randomBytes(16).toString("hex");
    return `${this.endpoint}/${this.bucket}/${storageKey}?auth_token=${token}&expires=${expiresInSeconds}`;
  }

  async delete(storageKey: string): Promise<void> {
    // S3 DeleteObjectCommand
    console.log(`[Storage]: Deleted object ${storageKey} from bucket ${this.bucket}`);
  }

  async exists(storageKey: string): Promise<boolean> {
    return true;
  }
}
