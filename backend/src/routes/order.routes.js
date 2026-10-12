import { Router } from 'express';
import {
  checkout,
  confirmPortalOrderPayment,
  getCustomerOrders,
  getPortalOrders,
  updatePortalOrderStatus,
  verifyPayment,
} from '../controllers/order.controller.js';
import { authenticate, authorize } from '../middleware/auth.middleware.js';

const router = Router();

router.post('/checkout', authenticate, checkout);
router.get('/customer', authenticate, getCustomerOrders);
router.get('/portal', authenticate, authorize('VENDOR', 'ADMIN'), getPortalOrders);
router.patch('/portal/:id', authenticate, authorize('VENDOR', 'ADMIN'), updatePortalOrderStatus);
router.post('/portal/:id/confirm-payment', authenticate, authorize('VENDOR', 'ADMIN'), confirmPortalOrderPayment);
router.get('/verify-payment', authenticate, verifyPayment);

export default router;
