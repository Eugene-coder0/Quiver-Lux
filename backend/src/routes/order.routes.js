import { Router } from 'express';
import {
  checkout,
  confirmPortalOrderPayment,
  getCustomerOrders,
  getPortalOrders,
  updatePortalOrderStatus,
  verifyPayment,
} from '../controllers/order.controller.js';
import { authenticate, authenticateAdminPortal, authorize } from '../middleware/auth.middleware.js';

const router = Router();

router.post('/checkout', authenticate, checkout);
router.get('/customer', authenticate, getCustomerOrders);
router.get('/portal', authenticateAdminPortal, authorize('VENDOR', 'ADMIN'), getPortalOrders);
router.patch('/portal/:id', authenticateAdminPortal, authorize('VENDOR', 'ADMIN'), updatePortalOrderStatus);
router.post('/portal/:id/confirm-payment', authenticateAdminPortal, authorize('VENDOR', 'ADMIN'), confirmPortalOrderPayment);
router.get('/verify-payment', verifyPayment);

export default router;
