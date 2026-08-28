import { Router } from 'express';
import { initializePayment, handleWebhook } from '../controllers/payment.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = Router();

// Webhook must be public so Paystack can post events to it
router.post('/webhook', handleWebhook);

// Protected route
router.post('/initialize', authenticate, initializePayment);

export default router;