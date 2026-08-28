import slugify from 'slugify';

import { prisma } from '../lib/prisma.js';
import { uploadToCloudinary } from '../config/cloudinary.js';
import { createProductSchema, updateProductSchema } from '../validators/product.validator.js';
import { ApiResponse } from '../utils/apiResponse.js';
import { ApiError } from '../utils/apiError.js';
import { serializeProduct } from '../utils/productMapper.js';

const includeProduct = {
  images: true,
  category: true,
  vendor: {
    select: {
      id: true,
      slug: true,
      storeName: true,
      brandName: true,
      storeLogo: true,
      paystackSetupComplete: true,
    },
  },
  _count: {
    select: {
      reviews: true,
    },
  },
};

const resolveCategoryId = async ({ categoryId, categoryName }) => {
  if (categoryId) {
    const existing = await prisma.category.findUnique({ where: { id: categoryId } });
    if (!existing) throw new ApiError(400, 'Selected category does not exist');
    return existing.id;
  }

  if (!categoryName) throw new ApiError(400, 'Category is required');

  const slug = slugify(categoryName, { lower: true, strict: true });
  const category = await prisma.category.findUnique({ where: { slug } });
  if (!category) throw new ApiError(400, 'Selected category does not exist');
  return category.id;
};

const validateOfferWindow = (data, basePrice) => {
  if (
    data.isLimitedOffer &&
    (data.discountPrice == null || Number(data.discountPrice) >= Number(basePrice))
  ) {
    throw new ApiError(400, 'Lightning deal price must be lower than the original price');
  }

  if (data.offerStartsAt && data.offerEndsAt) {
    const startsAt = new Date(data.offerStartsAt);
    const endsAt = new Date(data.offerEndsAt);
    if (endsAt <= startsAt) {
      throw new ApiError(400, 'Lightning deal end time must be after its start time');
    }
  }
};

export const createProduct = async (req, res, next) => {
  try {
    const vendor = await prisma.vendor.findUnique({ where: { userId: req.user.id } });
    if (!vendor) throw new ApiError(403, 'Only approved vendors can create products');

    const validatedData = createProductSchema.parse(req.body);
    validateOfferWindow(validatedData, validatedData.price);
    const categoryId = await resolveCategoryId(validatedData);
    const slug = `${slugify(validatedData.name, {
      lower: true,
      strict: true,
    })}-${Date.now().toString().slice(-4)}`;

    const product = await prisma.product.create({
      data: {
        vendorId: vendor.id,
        categoryId,
        name: validatedData.name,
        slug,
        description: validatedData.description,
        price: validatedData.price,
        discountPrice: validatedData.discountPrice,
        stockQuantity: validatedData.stockQuantity,
        isLimitedOffer: validatedData.isLimitedOffer,
        offerStartsAt: validatedData.offerStartsAt ? new Date(validatedData.offerStartsAt) : null,
        offerEndsAt: validatedData.offerEndsAt ? new Date(validatedData.offerEndsAt) : null,
        approvalStatus: 'PENDING',
      },
    });

    const imageUrls = Array.isArray(validatedData.imageUrls)
      ? validatedData.imageUrls
      : validatedData.imageUrls
        ? [validatedData.imageUrls]
        : [];

    const uploadedImages = req.files?.length
      ? await Promise.all(
          req.files.map((file, index) =>
            uploadToCloudinary(file.buffer, 'quiver-lux/products').then((result) => ({
              productId: product.id,
              url: result.url,
              publicId: result.publicId,
              isPrimary: index === 0 && imageUrls.length === 0,
            }))
          )
        )
      : [];

    const linkedImages = imageUrls.map((url, index) => ({
      productId: product.id,
      url,
      publicId: `external-${product.id}-${index}`,
      isPrimary: index === 0,
    }));

    if (uploadedImages.length || linkedImages.length) {
      await prisma.productImage.createMany({
        data: [...linkedImages, ...uploadedImages],
      });
    }

    const fullProduct = await prisma.product.findUnique({
      where: { id: product.id },
      include: includeProduct,
    });

    return ApiResponse.success(res, 201, 'Product created successfully', {
      product: serializeProduct(fullProduct),
    });
  } catch (error) {
    next(error);
  }
};

export const getProducts = async (req, res, next) => {
  try {
    const { category, search, page = 1, limit = 24 } = req.query;
    const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);
    const where = {
      isActive: true,
      approvalStatus: 'APPROVED',
      ...(category && { category: { slug: String(category) } }),
      ...(search && { name: { contains: String(search), mode: 'insensitive' } }),
    };

    const [products, total] = await Promise.all([
      prisma.product.findMany({
        where,
        include: includeProduct,
        orderBy: { createdAt: 'desc' },
        skip,
        take: parseInt(limit, 10),
      }),
      prisma.product.count({ where }),
    ]);

    return ApiResponse.success(res, 200, 'Products retrieved successfully', {
      products: products.map(serializeProduct),
      pagination: {
        total,
        page: parseInt(page, 10),
        pages: Math.ceil(total / parseInt(limit, 10)),
      },
    });
  } catch (error) {
    next(error);
  }
};

export const getVendorProducts = async (req, res, next) => {
  try {
    const isAdmin = req.user.role === 'ADMIN';
    const vendor = isAdmin
      ? null
      : await prisma.vendor.findUnique({ where: { userId: req.user.id } });

    if (!isAdmin && !vendor) throw new ApiError(404, 'Vendor profile not found');

    const products = await prisma.product.findMany({
      where: isAdmin ? {} : { vendorId: vendor.id },
      include: includeProduct,
      orderBy: { createdAt: 'desc' },
    });

    return ApiResponse.success(res, 200, 'Vendor products retrieved successfully', {
      products: products.map(serializeProduct),
    });
  } catch (error) {
    next(error);
  }
};

export const updateProductApproval = async (req, res, next) => {
  try {
    if (req.user.role !== 'ADMIN') throw new ApiError(403, 'Admin authorization required');
    const { approvalStatus } = req.body;
    if (!['APPROVED', 'REJECTED', 'PENDING'].includes(String(approvalStatus))) {
      throw new ApiError(400, 'Invalid approval status supplied');
    }

    const updated = await prisma.product.update({
      where: { id: req.params.id },
      data: { approvalStatus: String(approvalStatus) },
      include: includeProduct,
    });

    return ApiResponse.success(res, 200, 'Product approval status updated successfully', {
      product: serializeProduct(updated),
    });
  } catch (error) {
    next(error);
  }
};

export const updateLightningDeal = async (req, res, next) => {
  try {
    const vendor = await prisma.vendor.findUnique({ where: { userId: req.user.id } });
    if (!vendor) throw new ApiError(404, 'Vendor profile not found');

    const product = await prisma.product.findFirst({
      where: { id: req.params.id, vendorId: vendor.id },
    });
    if (!product) throw new ApiError(404, 'Product not found in your store');

    validateOfferWindow(req.body, product.price);

    const updated = await prisma.product.update({
      where: { id: product.id },
      data: {
        isLimitedOffer: Boolean(req.body.isLimitedOffer),
        discountPrice: req.body.isLimitedOffer ? Number(req.body.discountPrice) : null,
        offerStartsAt: req.body.offerStartsAt ? new Date(req.body.offerStartsAt) : null,
        offerEndsAt: req.body.offerEndsAt ? new Date(req.body.offerEndsAt) : null,
      },
      include: includeProduct,
    });

    return ApiResponse.success(res, 200, 'Lightning deal updated successfully', {
      product: serializeProduct(updated),
    });
  } catch (error) {
    next(error);
  }
};

export const updateProduct = async (req, res, next) => {
  try {
    const vendor = await prisma.vendor.findUnique({ where: { userId: req.user.id } });
    if (!vendor) throw new ApiError(404, 'Vendor profile not found');

    const product = await prisma.product.findFirst({
      where: { id: req.params.id, vendorId: vendor.id },
    });
    if (!product) throw new ApiError(404, 'Product not found in your store');

    const validatedData = updateProductSchema.parse(req.body);
    const categoryId =
      validatedData.categoryId || validatedData.categoryName
        ? await resolveCategoryId(validatedData)
        : product.categoryId;
    validateOfferWindow(
      {
        ...validatedData,
        isLimitedOffer: validatedData.isLimitedOffer ?? product.isLimitedOffer,
        discountPrice: validatedData.discountPrice ?? product.discountPrice,
        offerStartsAt: validatedData.offerStartsAt ?? product.offerStartsAt,
        offerEndsAt: validatedData.offerEndsAt ?? product.offerEndsAt,
      },
      validatedData.price ?? product.price
    );

    const updated = await prisma.product.update({
      where: { id: product.id },
      data: {
        categoryId,
        name: validatedData.name ?? product.name,
        description: validatedData.description ?? product.description,
        price: validatedData.price ?? product.price,
        discountPrice:
          validatedData.discountPrice !== undefined ? validatedData.discountPrice : product.discountPrice,
        stockQuantity: validatedData.stockQuantity ?? product.stockQuantity,
        isLimitedOffer: validatedData.isLimitedOffer ?? product.isLimitedOffer,
        offerStartsAt:
          validatedData.offerStartsAt !== undefined
            ? validatedData.offerStartsAt
              ? new Date(validatedData.offerStartsAt)
              : null
            : product.offerStartsAt,
        offerEndsAt:
          validatedData.offerEndsAt !== undefined
            ? validatedData.offerEndsAt
              ? new Date(validatedData.offerEndsAt)
              : null
            : product.offerEndsAt,
      },
      include: includeProduct,
    });

    return ApiResponse.success(res, 200, 'Product updated successfully', {
      product: serializeProduct(updated),
    });
  } catch (error) {
    next(error);
  }
};

export const deleteProduct = async (req, res, next) => {
  try {
    const vendor = await prisma.vendor.findUnique({ where: { userId: req.user.id } });
    if (!vendor) throw new ApiError(404, 'Vendor profile not found');

    const product = await prisma.product.findFirst({
      where: { id: req.params.id, vendorId: vendor.id },
    });
    if (!product) throw new ApiError(404, 'Product not found in your store');

    await prisma.product.delete({
      where: { id: product.id },
    });

    return ApiResponse.success(res, 200, 'Product deleted successfully');
  } catch (error) {
    next(error);
  }
};
