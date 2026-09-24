export interface UploadImageParams {
  storageKey: string;
  data: Buffer | Uint8Array;
  mimeType: string;
}

export interface ImageStorage {
  upload(params: UploadImageParams): Promise<{ storageKey: string; checksum: string }>;
  getSignedUrl(storageKey: string, expiresInSeconds?: number): Promise<string>;
  delete(storageKey: string): Promise<void>;
  exists(storageKey: string): Promise<boolean>;
}
