import { z } from 'zod';

const optionalNumber = z
  .union([z.string(), z.number()])
  .optional()
  .transform((val) => {
    if (val === undefined || val === null || val === '') return null;
    const parsed = typeof val === 'number' ? val : parseFloat(val);
    return Number.isNaN(parsed) ? null : parsed;
  });

const optionalInt = z
  .union([z.string(), z.number()])
  .optional()
  .transform((val) => {
    if (val === undefined || val === null || val === '') return 0;
    const parsed = typeof val === 'number' ? val : parseInt(val, 10);
    return Number.isNaN(parsed) ? 0 : parsed;
  });

const optionalBool = z
  .union([z.string(), z.boolean()])
  .optional()
  .transform((val) => val === true || val === 'true' || val === '1');

export const createProductSchema = z.object({
  categoryId: z.string().uuid().optional(),
  categoryName: z.string().min(2).optional(),
  name: z.string().min(3, 'Product name must be at least 3 characters'),
  description: z.string().min(10, 'Description must be at least 10 characters'),
  price: z.union([z.string(), z.number()]).transform((val) => parseFloat(val)),
  discountPrice: optionalNumber,
  stockQuantity: optionalInt,
  isLimitedOffer: optionalBool,
  offerStartsAt: z.string().optional().nullable(),
  offerEndsAt: z.string().optional().nullable(),
  imageUrls: z.union([z.string(), z.array(z.string())]).optional(),
});

export const updateProductSchema = createProductSchema.partial();
