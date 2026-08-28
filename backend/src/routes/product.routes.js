import { Router } from 'express';
import {
	createProduct,
	deleteProduct,
	getProducts,
	getVendorProducts,
	updateProduct,
	updateProductApproval,
	updateLightningDeal,
} from '../controllers/product.controller.js';
import { authenticate, authenticateAdminPortal, authorize } from '../middleware/auth.middleware.js';
import { upload } from '../middleware/upload.middleware.js';

const router = Router();

router.get('/', getProducts);
router.get('/vendor', authenticateAdminPortal, authorize('VENDOR', 'ADMIN'), getVendorProducts);
router.post('/', authenticate, authorize('VENDOR', 'ADMIN'), upload.array('images', 5), createProduct);
router.patch('/:id', authenticate, authorize('VENDOR', 'ADMIN'), updateProduct);
router.delete('/:id', authenticate, authorize('VENDOR', 'ADMIN'), deleteProduct);
router.patch('/:id/approval', authenticateAdminPortal, authorize('ADMIN'), updateProductApproval);
router.patch('/:id/lightning-deal', authenticate, authorize('VENDOR', 'ADMIN'), updateLightningDeal);

export default router;
