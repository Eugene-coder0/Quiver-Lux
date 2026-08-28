import { z } from 'zod';

export const registerSchema = z.object({
  email: z.string().email('Invalid email address format'),
  password: z.string().min(8, 'Password must be at least 8 characters long'),
  firstName: z.string().min(2, 'First name is required'),
  lastName: z.string().min(2, 'Last name is required'),
  phone: z.string().optional(),
  role: z.enum(['CUSTOMER', 'VENDOR']).default('CUSTOMER'),
  storeName: z.string().min(3, 'Store name must be at least 3 characters').optional(),
  brandName: z.string().min(2, 'Brand name must be at least 2 characters').optional(),
  businessAddress: z.string().min(5, 'Business address is required').optional(),
  paystackRecipientCode: z.string().optional(),
  paystackSubaccountCode: z.string().optional(),
  paystackBusinessName: z.string().optional(),
  paystackAccountName: z.string().optional(),
  paystackAccountNumber: z.string().optional(),
  paystackBankCode: z.string().optional(),
}).superRefine((data, ctx) => {
  if (data.role !== 'VENDOR') {
    return;
  }

  if (!data.storeName?.trim()) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: 'Store name is required for vendor registration',
      path: ['storeName'],
    });
  }

  if (!data.businessAddress?.trim()) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: 'Business address is required for vendor registration',
      path: ['businessAddress'],
    });
  }

  if (!data.paystackBusinessName?.trim()) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: 'Business name is required for vendor payment setup',
      path: ['paystackBusinessName'],
    });
  }

  if (!data.paystackBankCode?.trim()) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: 'Bank selection is required for vendor payment setup',
      path: ['paystackBankCode'],
    });
  }

  if (!data.paystackAccountNumber?.trim()) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: 'Account number is required for vendor payment setup',
      path: ['paystackAccountNumber'],
    });
  }

  if (!data.paystackAccountName?.trim()) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: 'Verify the settlement account before continuing',
      path: ['paystackAccountName'],
    });
  }
});

export const loginSchema = z.object({
  email: z.string().email('Invalid email address format'),
  password: z.string().min(1, 'Password is required'),
});
