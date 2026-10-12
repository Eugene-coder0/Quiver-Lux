import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import cloudinary from 'cloudinary/lib/v2/index.js';
import { env } from './env.js';

const isCloudinaryConfigured = () => {
  return (
    Boolean(env.CLOUDINARY_CLOUD_NAME) &&
    env.CLOUDINARY_CLOUD_NAME !== 'demo' &&
    Boolean(env.CLOUDINARY_API_KEY) &&
    env.CLOUDINARY_API_KEY !== '123456789' &&
    Boolean(env.CLOUDINARY_API_SECRET) &&
    env.CLOUDINARY_API_SECRET !== 'secret'
  );
};

if (isCloudinaryConfigured()) {
  cloudinary.config({
    cloud_name: env.CLOUDINARY_CLOUD_NAME,
    api_key: env.CLOUDINARY_API_KEY,
    api_secret: env.CLOUDINARY_API_SECRET,
  });
}

const saveLocally = async (fileBuffer, folder = 'quiver-lux') => {
  const uploadsDir = path.join(process.cwd(), 'public', 'uploads');
  await fs.promises.mkdir(uploadsDir, { recursive: true });

  const uniqueSuffix = `${Date.now()}-${crypto.randomBytes(6).toString('hex')}`;
  const filename = `${uniqueSuffix}.jpg`;
  const filePath = path.join(uploadsDir, filename);

  await fs.promises.writeFile(filePath, fileBuffer);

  return {
    url: `/uploads/${filename}`,
    publicId: `local-${filename}`,
  };
};

export const uploadToCloudinary = async (fileBuffer, folder = 'quiver-lux') => {
  if (!isCloudinaryConfigured()) {
    return saveLocally(fileBuffer, folder);
  }

  try {
    return await new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        { folder, resource_type: 'image' },
        (error, result) => {
          if (error) return reject(error);
          resolve({
            url: result.secure_url,
            publicId: result.public_id,
          });
        }
      );
      uploadStream.end(fileBuffer);
    });
  } catch (error) {
    console.warn('⚠️ Cloudinary upload failed, falling back to local storage:', error.message);
    return saveLocally(fileBuffer, folder);
  }
};

export const deleteFromCloudinary = async (publicId) => {
  if (!publicId) return;

  if (publicId.startsWith('local-')) {
    const filename = publicId.replace('local-', '');
    const filePath = path.join(process.cwd(), 'public', 'uploads', filename);
    try {
      if (fs.existsSync(filePath)) {
        await fs.promises.unlink(filePath);
      }
    } catch (err) {
      console.warn('Failed to delete local upload:', err.message);
    }
    return;
  }

  if (isCloudinaryConfigured()) {
    try {
      return await cloudinary.uploader.destroy(publicId);
    } catch (err) {
      console.warn('Failed to destroy Cloudinary image:', err.message);
    }
  }
};
