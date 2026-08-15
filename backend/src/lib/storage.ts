import { promises as fs } from 'fs';
import path from 'path';

export async function getPresignedUploadUrl(key: string, _contentType?: string): Promise<string> {
  // Direct local mock upload fallback URL
  return `/api/upload/mock-s3?key=${encodeURIComponent(key)}`;
}

export async function getPresignedDownloadUrl(key: string): Promise<string> {
  // Direct local file path fallback
  return `/upload/${key}`;
}

export async function uploadFileToStorage(key: string, buffer: Buffer, _contentType?: string): Promise<string> {
  const targetFilePath = path.join(process.cwd(), "..", "dashboard-web-app", "public", "upload", key);
  const targetDir = path.dirname(targetFilePath);

  await fs.mkdir(targetDir, { recursive: true });
  await fs.writeFile(targetFilePath, buffer);

  return `/upload/${key}`;
}
