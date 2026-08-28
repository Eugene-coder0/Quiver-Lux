import { Router } from 'express';
import { createCategory, getCategories } from '../controllers/category.controller.js';
import { authenticate, authorize } from '../middleware/auth.middleware.js';

const router = Router();

router.get('/', getCategories);
router.post('/', authenticate, authorize('ADMIN'), createCategory);

export default router;