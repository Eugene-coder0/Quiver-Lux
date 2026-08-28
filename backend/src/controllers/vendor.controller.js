import slugify from 'slugify';
import { prisma } from '../lib/prisma.js';
import { createVendorSchema } from '../validators/vendor.validator.js';
import { uploadToCloudinary } from '../config/cloudinary.js';
import { buildVendorPaystackProfile } from '../services/vendor_paystack.service.js';
import { ApiResponse } from '../utils/apiResponse.js';
import { ApiError } from '../utils/apiError.js';

const serializeVendor = (vendor) => ({
  ...vendor,
  commissionRate: Number(vendor.commissionRate),
  rating: Number(vendor.rating ?? 0),
});

const serializeVendorApplication = (vendor) => ({
  id: vendor.id,
  storeName: vendor.storeName,
  ownerName:
    [vendor.user?.firstName, vendor.user?.lastName].filter(Boolean).join(' ').trim() ||
    'Vendor applicant',
  email: vendor.user?.email || '',
  category: 'General Luxury',
  description: vendor.description || '',
  phone: vendor.phone || '',
  businessAddress: vendor.businessAddress || '',
  paystackRecipientCode: vendor.paystackRecipientCode || '',
  paystackSubaccountCode: vendor.paystackSubaccountCode || '',
  paystackBusinessName: vendor.paystackBusinessName || '',
  paystackAccountName: vendor.paystackAccountName || '',
  paystackAccountNumber: vendor.paystackAccountNumber || '',
  paystackBankCode: vendor.paystackBankCode || '',
  appliedDate: vendor.createdAt,
  status: String(vendor.status || 'PENDING').toLowerCase(),
});

export const registerVendorStore = async (req, res, next) => {
  try {
    const validatedData = createVendorSchema.parse(req.body);

    const existingVendor = await prisma.vendor.findUnique({
      where: { userId: req.user.id },
    });
    if (existingVendor) throw new ApiError(400, 'You already have a vendor store profile');

    const slug = slugify(validatedData.storeName, { lower: true, strict: true });

    let storeLogoUrl = validatedData.storeLogo || null;
    if (req.file) {
      const uploadResult = await uploadToCloudinary(req.file.buffer, 'quiver-lux/logos');
      storeLogoUrl = uploadResult.url;
    }

    const paystackProfile = await buildVendorPaystackProfile({
      storeName: validatedData.storeName,
      brandName: validatedData.brandName,
      businessName: validatedData.paystackBusinessName,
      bankCode: validatedData.paystackBankCode,
      accountNumber: validatedData.paystackAccountNumber,
      contactEmail: req.user.email,
      description: validatedData.description,
      commissionRate: 10,
      legacySubaccountCode: validatedData.paystackSubaccountCode,
      legacyRecipientCode: validatedData.paystackRecipientCode,
      legacyAccountName: validatedData.paystackAccountName,
    });

    const vendor = await prisma.vendor.create({
      data: {
        userId: req.user.id,
        storeName: validatedData.storeName,
        brandName: validatedData.brandName || validatedData.storeName,
        slug,
        description: validatedData.description,
        phone: validatedData.phone || req.user.phone || '0000000',
        businessAddress: validatedData.businessAddress || 'Pending vendor address',
        storeLogo: storeLogoUrl,
        paystackRecipientCode: paystackProfile.paystackRecipientCode,
        paystackSubaccountCode: paystackProfile.paystackSubaccountCode,
        paystackBusinessName: paystackProfile.paystackBusinessName,
        paystackAccountName: paystackProfile.paystackAccountName,
        paystackAccountNumber: paystackProfile.paystackAccountNumber,
        paystackBankCode: paystackProfile.paystackBankCode,
        paystackSetupComplete: paystackProfile.paystackSetupComplete,
        status: 'PENDING',
      },
    });

    return ApiResponse.success(res, 201, 'Vendor store profile created successfully', {
      vendor: serializeVendor(vendor),
    });
  } catch (error) {
    next(error);
  }
};

export const updateVendorProfile = async (req, res, next) => {
  try {
    const validatedData = createVendorSchema.partial().parse(req.body);
    const vendor = await prisma.vendor.findUnique({
      where: { userId: req.user.id },
    });
    if (!vendor) throw new ApiError(404, 'Vendor profile not found');

    let storeLogoUrl = req.body.storeLogo || vendor.storeLogo;
    if (req.file) {
      const uploadResult = await uploadToCloudinary(req.file.buffer, 'quiver-lux/logos');
      storeLogoUrl = uploadResult.url;
    }

    const nextStoreName = validatedData.storeName ?? vendor.storeName;
    const nextBrandName = validatedData.brandName ?? vendor.brandName ?? nextStoreName;
    const shouldRefreshPaystack =
      validatedData.paystackBusinessName !== undefined ||
      validatedData.paystackAccountNumber !== undefined ||
      validatedData.paystackBankCode !== undefined ||
      validatedData.paystackSubaccountCode !== undefined ||
      validatedData.paystackRecipientCode !== undefined;
    const paystackProfile = shouldRefreshPaystack
      ? await buildVendorPaystackProfile({
          storeName: nextStoreName,
          brandName: nextBrandName,
          businessName:
            validatedData.paystackBusinessName ?? vendor.paystackBusinessName ?? nextBrandName,
          bankCode: validatedData.paystackBankCode ?? vendor.paystackBankCode,
          accountNumber: validatedData.paystackAccountNumber ?? vendor.paystackAccountNumber,
          contactEmail: req.user.email,
          description: validatedData.description ?? vendor.description,
          commissionRate: Number(vendor.commissionRate),
          legacySubaccountCode:
            validatedData.paystackSubaccountCode ?? vendor.paystackSubaccountCode,
          legacyRecipientCode:
            validatedData.paystackRecipientCode ?? vendor.paystackRecipientCode,
          legacyAccountName:
            validatedData.paystackAccountName ?? vendor.paystackAccountName,
        })
      : null;
    const updated = await prisma.vendor.update({
      where: { id: vendor.id },
      data: {
        storeName: nextStoreName,
        brandName: nextBrandName,
        slug:
          validatedData.storeName && validatedData.storeName !== vendor.storeName
            ? slugify(validatedData.storeName, { lower: true, strict: true })
            : vendor.slug,
        description: validatedData.description ?? vendor.description,
        phone: validatedData.phone ?? vendor.phone,
        businessAddress: validatedData.businessAddress ?? vendor.businessAddress,
        storeLogo: storeLogoUrl,
        paystackRecipientCode:
          paystackProfile?.paystackRecipientCode ?? vendor.paystackRecipientCode,
        paystackSubaccountCode:
          paystackProfile?.paystackSubaccountCode ?? vendor.paystackSubaccountCode,
        paystackBusinessName:
          paystackProfile?.paystackBusinessName ?? vendor.paystackBusinessName ?? nextStoreName,
        paystackAccountName:
          paystackProfile?.paystackAccountName ?? vendor.paystackAccountName,
        paystackAccountNumber:
          paystackProfile?.paystackAccountNumber ?? vendor.paystackAccountNumber,
        paystackBankCode:
          paystackProfile?.paystackBankCode ?? vendor.paystackBankCode,
        paystackSetupComplete:
          paystackProfile?.paystackSetupComplete ?? vendor.paystackSetupComplete,
      },
    });

    return ApiResponse.success(res, 200, 'Vendor profile updated successfully', {
      vendor: serializeVendor(updated),
    });
  } catch (error) {
    next(error);
  }
};

export const submitVendorApplication = async (req, res, next) => {
  try {
    const validatedData = createVendorSchema.parse(req.body);
    const existingVendor = await prisma.vendor.findUnique({
      where: { userId: req.user.id },
    });
    let storeLogoUrl = validatedData.storeLogo || existingVendor?.storeLogo || null;

    if (req.file) {
      const uploadResult = await uploadToCloudinary(req.file.buffer, 'quiver-lux/logos');
      storeLogoUrl = uploadResult.url;
    }

    const nextStoreName = validatedData.storeName.trim();
    const paystackProfile = await buildVendorPaystackProfile({
      storeName: nextStoreName,
      brandName: validatedData.brandName || nextStoreName,
      businessName: validatedData.paystackBusinessName,
      bankCode: validatedData.paystackBankCode,
      accountNumber: validatedData.paystackAccountNumber,
      contactEmail: req.user.email,
      description: validatedData.description,
      commissionRate: Number(existingVendor?.commissionRate ?? 10),
      legacySubaccountCode: validatedData.paystackSubaccountCode ?? existingVendor?.paystackSubaccountCode,
      legacyRecipientCode: validatedData.paystackRecipientCode ?? existingVendor?.paystackRecipientCode,
      legacyAccountName: validatedData.paystackAccountName ?? existingVendor?.paystackAccountName,
    });
    const vendor = existingVendor
      ? await prisma.vendor.update({
          where: { id: existingVendor.id },
          data: {
            storeName: nextStoreName,
            brandName: validatedData.brandName || nextStoreName,
            slug:
              nextStoreName !== existingVendor.storeName
                ? slugify(nextStoreName, { lower: true, strict: true })
                : existingVendor.slug,
            description: validatedData.description ?? existingVendor.description,
            phone:
              validatedData.phone ||
              existingVendor.phone ||
              req.user.phone ||
              '0000000',
            businessAddress:
              validatedData.businessAddress ||
              existingVendor.businessAddress ||
              'Pending vendor address',
            storeLogo: storeLogoUrl,
            paystackRecipientCode: paystackProfile.paystackRecipientCode,
            paystackSubaccountCode: paystackProfile.paystackSubaccountCode,
            paystackBusinessName: paystackProfile.paystackBusinessName,
            paystackAccountName: paystackProfile.paystackAccountName,
            paystackAccountNumber: paystackProfile.paystackAccountNumber,
            paystackBankCode: paystackProfile.paystackBankCode,
            paystackSetupComplete: paystackProfile.paystackSetupComplete,
            status: 'PENDING',
          },
        })
      : await prisma.vendor.create({
          data: {
            userId: req.user.id,
            storeName: nextStoreName,
            brandName: validatedData.brandName || nextStoreName,
            slug: slugify(nextStoreName, { lower: true, strict: true }),
            description: validatedData.description,
            phone: validatedData.phone || req.user.phone || '0000000',
            businessAddress: validatedData.businessAddress || 'Pending vendor address',
            storeLogo: storeLogoUrl,
            paystackRecipientCode: paystackProfile.paystackRecipientCode,
            paystackSubaccountCode: paystackProfile.paystackSubaccountCode,
            paystackBusinessName: paystackProfile.paystackBusinessName,
            paystackAccountName: paystackProfile.paystackAccountName,
            paystackAccountNumber: paystackProfile.paystackAccountNumber,
            paystackBankCode: paystackProfile.paystackBankCode,
            paystackSetupComplete: paystackProfile.paystackSetupComplete,
            status: 'PENDING',
          },
        });

    if (req.user.role !== 'CUSTOMER') {
      await prisma.user.update({
        where: { id: req.user.id },
        data: { role: 'CUSTOMER' },
      });
    }

    return ApiResponse.success(res, existingVendor ? 200 : 201, 'Vendor application submitted successfully', {
      vendor: serializeVendor(vendor),
      application: serializeVendorApplication({
        ...vendor,
        user: {
          firstName: req.user.firstName,
          lastName: req.user.lastName,
          email: req.user.email,
        },
      }),
    });
  } catch (error) {
    next(error);
  }
};

export const getVendorApplications = async (req, res, next) => {
  try {
    if (req.user.role !== 'ADMIN') {
      throw new ApiError(403, 'Admin authorization required');
    }

    const vendors = await prisma.vendor.findMany({
      include: {
        user: {
          select: {
            firstName: true,
            lastName: true,
            email: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return ApiResponse.success(res, 200, 'Vendor applications retrieved', {
      applications: vendors.map(serializeVendorApplication),
    });
  } catch (error) {
    next(error);
  }
};

export const reviewVendorApplication = async (req, res, next) => {
  try {
    if (req.user.role !== 'ADMIN') {
      throw new ApiError(403, 'Admin authorization required');
    }

    const nextStatus = String(req.body.status || '').toUpperCase();
    if (!['APPROVED', 'REJECTED', 'PENDING'].includes(nextStatus)) {
      throw new ApiError(400, 'Invalid vendor application status supplied');
    }

    const existingVendor = await prisma.vendor.findUnique({
      where: { id: req.params.id },
      include: {
        user: {
          select: {
            firstName: true,
            lastName: true,
            email: true,
          },
        },
      },
    });
    if (!existingVendor) {
      throw new ApiError(404, 'Vendor application not found');
    }

    const updated = await prisma.$transaction(async (tx) => {
      const vendor = await tx.vendor.update({
        where: { id: existingVendor.id },
        data: { status: nextStatus },
        include: {
          user: {
            select: {
              firstName: true,
              lastName: true,
              email: true,
            },
          },
        },
      });

      await tx.user.update({
        where: { id: existingVendor.userId },
        data: {
          role: nextStatus === 'APPROVED' ? 'VENDOR' : 'CUSTOMER',
        },
      });

      return vendor;
    });

    return ApiResponse.success(res, 200, 'Vendor application reviewed successfully', {
      application: serializeVendorApplication(updated),
      vendor: serializeVendor(updated),
    });
  } catch (error) {
    next(error);
  }
};

export const getVendorProfile = async (req, res, next) => {
  try {
    const vendor = await prisma.vendor.findUnique({
      where: { userId: req.user.id },
      include: {
        products: {
          include: {
            category: true,
            images: true,
          },
        },
      },
    });
    if (!vendor) throw new ApiError(404, 'Vendor profile not found');

    return ApiResponse.success(res, 200, 'Vendor profile retrieved', {
      vendor: serializeVendor(vendor),
    });
  } catch (error) {
    next(error);
  }
};
