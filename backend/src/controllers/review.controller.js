import { prisma } from '../lib/prisma.js';
import { ApiResponse } from '../utils/apiResponse.js';

// GET /api/reviews/product/:productId - Get reviews for a product
export const getProductReviews = async (req, res, next) => {
  try {
    const { productId } = req.params;

    const reviews = await prisma.review.findMany({
      where: { productId },
      include: {
        user: { select: { id: true, firstName: true, lastName: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    return ApiResponse.success(res, 200, 'Product reviews loaded', reviews);
  } catch (error) {
    next(error);
  }
};

// POST /api/reviews - Add product review
export const createReview = async (req, res, next) => {
  try {
    const { productId, rating, comment } = req.body;
    const userId = req.user.id;

    const existingReview = await prisma.review.findFirst({
      where: { productId, userId },
    });

    if (existingReview) {
      return ApiResponse.error(res, 400, 'You have already reviewed this product');
    }

    const review = await prisma.review.create({
      data: {
        userId,
        productId,
        rating: parseInt(rating),
        comment,
      },
    });

    return ApiResponse.success(res, 201, 'Review submitted successfully', review);
  } catch (error) {
    next(error);
  }
};