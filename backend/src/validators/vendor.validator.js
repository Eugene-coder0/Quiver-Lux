import { z } from 'zod';

export const createVendorSchema = z
  .object({
    storeName: z.string().min(3, 'Store name must be at least 3 characters'),
    brandName: z.string().min(2).optional(),
    storeLogo: z.string().url().optional(),
    description: z.string().optional(),
    phone: z.string().min(7, 'Phone number is required').optional(),
    businessAddress: z.string().min(5, 'Business address is required').optional(),
    category: z.string().min(2).optional(),
    paystackRecipientCode: z.string().optional(),
    paystackSubaccountCode: z.string().optional(),
    paystackBusinessName: z.string().optional(),
    paystackAccountName: z.string().optional(),
    paystackAccountNumber: z.string().optional(),
    paystackBankCode: z.string().optional(),
  })
  .superRefine((data, ctx) => {
    const hasManagedSetup =
      Boolean(data.paystackBusinessName?.trim()) &&
      Boolean(data.paystackAccountNumber?.trim()) &&
      Boolean(data.paystackBankCode?.trim());
    const hasLegacySetup =
      Boolean(data.paystackRecipientCode?.trim()) ||
      Boolean(data.paystackSubaccountCode?.trim());

    if (!hasManagedSetup && !hasLegacySetup) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message:
          'Provide bank details for Paystack setup, or a legacy recipient/subaccount code',
        path: ['paystackBusinessName'],
      });
    }
  });
