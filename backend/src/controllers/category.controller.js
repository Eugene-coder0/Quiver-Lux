import slugify from 'slugify';
import { prisma } from '../lib/prisma.js';
import { ApiResponse } from '../utils/apiResponse.js';
import { ApiError } from '../utils/apiError.js';

const marketplaceCategories = [
  { name: 'Clothing', description: 'Luxury fashion, garments, and apparel.' },
  { name: 'Home Accessories', description: 'Decor accents and home styling essentials.' },
  { name: 'Footwear', description: 'Designer footwear and premium shoes.' },
  { name: 'Jewelry', description: 'Fine jewelry and statement accessories.' },
  { name: 'Bags', description: 'Luxury handbags, clutches, and travel bags.' },
];

export const createCategory = async (req, res, next) => {
  try {
    const { name, description } = req.body;
    if (!name) throw new ApiError(400, 'Category name is required');

    const slug = slugify(name, { lower: true, strict: true });

    const existing = await prisma.category.findUnique({ where: { slug } });
    if (existing) throw new ApiError(400, 'Category with this name already exists');

    const category = await prisma.category.create({
      data: { name, slug, description },
    });

    return ApiResponse.success(res, 201, 'Category created successfully', { category });
  } catch (error) {
    next(error);
  }
};

export const getCategories = async (req, res, next) => {
  try {
    for (const category of marketplaceCategories) {
      const slug = slugify(category.name, { lower: true, strict: true });
      await prisma.category.upsert({
        where: { slug },
        update: {
          name: category.name,
          description: category.description,
          isActive: true,
        },
        create: {
          name: category.name,
          slug,
          description: category.description,
          isActive: true,
        },
      });
    }

    const categories = await prisma.category.findMany({
      where: { isActive: true },
      orderBy: { name: 'asc' },
    });
    return ApiResponse.success(res, 200, 'Categories retrieved', { categories });
  } catch (error) {
    next(error);
  }
};
