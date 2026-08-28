import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const envSchema = z.object({
  PORT: z.string().default('5000').transform((val) => parseInt(val, 10)),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  JWT_SECRET: z.string().min(10, 'JWT_SECRET must be at least 10 characters long'),
  DATABASE_URL: z.string().url('DATABASE_URL must be a valid connection string'),
  ALLOWED_ORIGINS: z.string().default('*'),
  ALLOW_TEST_PAYSTACK_BYPASS: z
    .string()
    .default('true')
    .transform((val) => val.trim().toLowerCase() === 'true'),
  CLOUDINARY_CLOUD_NAME: z.string().default('demo'),
  CLOUDINARY_API_KEY: z.string().default('123456789'),
  CLOUDINARY_API_SECRET: z.string().default('secret'),
  PAYSTACK_SECRET_KEY: z.string().default('sk_test_placeholder'),
});

const parseEnv = () => {
  const result = envSchema.safeParse(process.env);

  if (!result.success) {
    console.error('❌ Invalid environment configuration variables:');
    console.error(result.error.format());
    process.exit(1);
  }

  return result.data;
};

export const env = parseEnv();
