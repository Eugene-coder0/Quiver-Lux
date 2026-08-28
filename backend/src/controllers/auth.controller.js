import slugify from 'slugify';
import { prisma } from '../lib/prisma.js';
import { hashPassword, comparePassword } from '../utils/password.js';
import { generateToken } from '../utils/jwt.js';
import { registerSchema, loginSchema } from '../validators/auth.validator.js';
import { listBanks, resolveAccountNumber } from '../services/paystack.service.js';
import {
  buildTestModePaystackFallback,
  buildVendorPaystackProfile,
  shouldUseTestPaystackBypass,
} from '../services/vendor_paystack.service.js';
import { ApiResponse } from '../utils/apiResponse.js';
import { ApiError } from '../utils/apiError.js';

export const register = async (req, res, next) => {
  try {
    const validatedData = registerSchema.parse(req.body);

    const existingUser = await prisma.user.findUnique({
      where: { email: validatedData.email.toLowerCase() },
    });

    if (existingUser) {
      throw new ApiError(400, 'An account with this email address already exists');
    }

    const hashedPassword = await hashPassword(validatedData.password);
    const isVendorApplication = validatedData.role === 'VENDOR';
    const normalizedStoreName = validatedData.storeName?.trim();
    const normalizedBrandName = validatedData.brandName?.trim();
    const normalizedBusinessAddress = validatedData.businessAddress?.trim();
    const normalizedRecipientCode = validatedData.paystackRecipientCode?.trim();
    const normalizedSubaccountCode = validatedData.paystackSubaccountCode?.trim();
    const normalizedBusinessName = validatedData.paystackBusinessName?.trim();
    const normalizedAccountName = validatedData.paystackAccountName?.trim();
    const normalizedAccountNumber = validatedData.paystackAccountNumber?.trim();
    const normalizedBankCode = validatedData.paystackBankCode?.trim();
    let vendorPaystackProfile = null;

    if (isVendorApplication && normalizedStoreName) {
      const existingVendor = await prisma.vendor.findUnique({
        where: { storeName: normalizedStoreName },
      });

      if (existingVendor) {
        throw new ApiError(400, 'A vendor store with this name already exists');
      }

      vendorPaystackProfile = await buildVendorPaystackProfile({
        storeName: normalizedStoreName,
        brandName: normalizedBrandName,
        businessName: normalizedBusinessName,
        bankCode: normalizedBankCode,
        accountNumber: normalizedAccountNumber,
        contactEmail: validatedData.email,
        description: 'Vendor application submitted during account registration.',
        legacyAccountName: normalizedAccountName,
      });
    }

    const user = await prisma.$transaction(async (tx) => {
      const fallbackStoreName =
        normalizedStoreName ||
        `${validatedData.firstName} ${validatedData.lastName} Store ${Date.now()}`;
      const createdUser = await tx.user.create({
        data: {
          email: validatedData.email.toLowerCase(),
          passwordHash: hashedPassword,
          firstName: validatedData.firstName,
          lastName: validatedData.lastName,
          phone: validatedData.phone,
          role: isVendorApplication ? 'CUSTOMER' : 'CUSTOMER',
          cart: { create: {} },
          ...(isVendorApplication
            ? {
                vendor: {
                  create: {
                    storeName: fallbackStoreName,
                    brandName:
                      normalizedBrandName ||
                      fallbackStoreName ||
                      `${validatedData.firstName} ${validatedData.lastName} Store`,
                    slug: slugify(
                      fallbackStoreName,
                      { lower: true, strict: true },
                    ),
                    description: 'Vendor application submitted during account registration.',
                    phone: validatedData.phone || '0000000',
                    businessAddress: normalizedBusinessAddress || 'Pending vendor address',
                    paystackRecipientCode:
                      vendorPaystackProfile?.paystackRecipientCode ||
                      normalizedRecipientCode,
                    paystackSubaccountCode:
                      vendorPaystackProfile?.paystackSubaccountCode ||
                      normalizedSubaccountCode,
                    paystackBusinessName:
                      vendorPaystackProfile?.paystackBusinessName ||
                      normalizedBusinessName ||
                      normalizedBrandName ||
                      fallbackStoreName ||
                      `${validatedData.firstName} ${validatedData.lastName} Store`,
                    paystackAccountName:
                      vendorPaystackProfile?.paystackAccountName || normalizedAccountName,
                    paystackAccountNumber:
                      vendorPaystackProfile?.paystackAccountNumber || normalizedAccountNumber,
                    paystackBankCode:
                      vendorPaystackProfile?.paystackBankCode || normalizedBankCode,
                    paystackSetupComplete: Boolean(
                      vendorPaystackProfile?.paystackSetupComplete ||
                        normalizedRecipientCode ||
                        normalizedSubaccountCode,
                    ),
                    status: 'PENDING',
                  },
                },
              }
            : {}),
        },
        select: {
          id: true,
          email: true,
          firstName: true,
          lastName: true,
          phone: true,
          role: true,
          createdAt: true,
          vendor: true,
        },
      });
      return createdUser;
    });

    const token = generateToken({ userId: user.id, role: user.role });

    return ApiResponse.success(
      res,
      201,
      isVendorApplication
        ? 'Vendor application submitted and is awaiting admin approval'
        : 'User account registered successfully',
      { user, token },
    );
  } catch (error) {
    if (error.name === 'ZodError') {
      return next(new ApiError(400, 'Validation failed', error.errors));
    }
    next(error);
  }
};

export const getPaystackBanks = async (req, res, next) => {
  try {
    const banks = await listBanks({
      country: String(req.query.country || 'nigeria').toLowerCase(),
      currency: String(req.query.currency || 'NGN').toUpperCase(),
      enabledForVerification: true,
    });

    return ApiResponse.success(res, 200, 'Paystack banks retrieved successfully', {
      banks: banks.map((bank) => ({
        id: bank.id,
        name: bank.name,
        code: bank.code,
        slug: bank.slug,
        currency: bank.currency,
      })),
    });
  } catch (error) {
    next(error);
  }
};

export const verifyPaystackAccount = async (req, res, next) => {
  try {
    const accountNumber = req.body.accountNumber?.toString().trim();
    const bankCode = req.body.bankCode?.toString().trim();

    if (!accountNumber || !bankCode) {
      throw new ApiError(400, 'Bank code and account number are required');
    }

    let account;
    let bypassMode = false;
    try {
      account = await resolveAccountNumber({ accountNumber, bankCode });
    } catch (error) {
      if (!shouldUseTestPaystackBypass(error)) {
        throw error;
      }
      const fallback = buildTestModePaystackFallback({
        accountNumber,
        bankCode,
        accountName: req.body.accountName,
        businessName: req.body.businessName,
      });
      account = {
        account_name: fallback.paystackAccountName,
        account_number: fallback.paystackAccountNumber,
        bank_id: null,
      };
      bypassMode = true;
    }

    return ApiResponse.success(res, 200, 'Account verified successfully', {
      accountName: account.account_name || '',
      accountNumber: account.account_number || accountNumber,
      bankId: account.bank_id ?? null,
      bypassMode,
    });
  } catch (error) {
    next(error);
  }
};

export const login = async (req, res, next) => {
  try {
    const validatedData = loginSchema.parse(req.body);

    const user = await prisma.user.findUnique({
      where: { email: validatedData.email.toLowerCase() },
    });

    if (!user) {
      throw new ApiError(401, 'Invalid credentials provided');
    }

    const isMatch = await comparePassword(validatedData.password, user.passwordHash);

    if (!isMatch) {
      throw new ApiError(401, 'Invalid credentials provided');
    }

    if (user.role === 'CUSTOMER') {
      await prisma.loginEvent.create({
        data: {
          userId: user.id,
          role: user.role,
        },
      });
    }

    const vendor = await prisma.vendor.findUnique({
      where: { userId: user.id },
    });

    const token = generateToken({ userId: user.id, role: user.role });

    const userProfile = {
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      name: `${user.firstName} ${user.lastName}`.trim(),
      phone: user.phone,
      role: user.role,
      vendorStatus: vendor?.status ?? 'NONE',
      vendor,
    };

    return ApiResponse.success(res, 200, 'Logged in successfully', { user: userProfile, token });
  } catch (error) {
    if (error.name === 'ZodError') {
      return next(new ApiError(400, 'Validation failed', error.errors));
    }
    next(error);
  }
};

export const getProfile = async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        phone: true,
        role: true,
        createdAt: true,
        vendor: true,
      },
    });

    const normalizedUser = user
      ? {
          ...user,
          name: `${user.firstName} ${user.lastName}`.trim(),
          vendorStatus: user.vendor?.status ?? 'NONE',
        }
      : null;

    return ApiResponse.success(res, 200, 'Profile details retrieved', { user: normalizedUser });
  } catch (error) {
    next(error);
  }
};

export const getUsers = async (req, res, next) => {
  try {
    if (req.user.role !== 'ADMIN') {
      throw new ApiError(403, 'Admin authorization required');
    }

    const users = await prisma.user.findMany({
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        phone: true,
        role: true,
        createdAt: true,
        vendor: { select: { status: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    return ApiResponse.success(res, 200, 'Users retrieved successfully', { users });
  } catch (error) {
    next(error);
  }
};
