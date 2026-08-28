import { Router } from 'express';
import {
  registerVendorStore,
  getVendorProfile,
  updateVendorProfile,
  submitVendorApplication,
  getVendorApplications,
  reviewVendorApplication,
} from '../controllers/vendor.controller.js';
import { authenticate, authenticateAdminPortal, authorize } from '../middleware/auth.middleware.js';
import { upload } from '../middleware/upload.middleware.js';

const router = Router();

router.post('/register', authenticate, upload.single('storeLogo'), registerVendorStore);
router.post('/apply', authenticate, upload.single('storeLogo'), submitVendorApplication);
router.get('/applications', authenticateAdminPortal, authorize('ADMIN'), getVendorApplications);
router.patch(
  '/applications/:id',
  authenticateAdminPortal,
  authorize('ADMIN'),
  reviewVendorApplication
);
router.get('/me', authenticate, getVendorProfile);
router.patch('/me', authenticate, upload.single('storeLogo'), updateVendorProfile);

export default router;
