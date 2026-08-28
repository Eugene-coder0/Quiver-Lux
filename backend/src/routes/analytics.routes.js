import { Router } from 'express';
import { getVendorAnalytics, getAdminAnalytics } from '../controllers/analytics.controller.js';
import { authenticate, authenticateAdminPortal } from '../middleware/auth.middleware.js';

const router = Router();

router.get('/vendor', authenticate, getVendorAnalytics);
router.get('/admin', authenticateAdminPortal, getAdminAnalytics);

export default router;