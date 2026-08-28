import { Router } from 'express';
import { getProductReviews, createReview } from '../controllers/review.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = Router();

// Public route to read reviews
router.get('/product/:productId', getProductReviews);

// Protected route to post a review
router.post('/', authenticate, createReview);

export default router;