import { Router } from 'express';
import { initializePayment, handleWebhook, verifyPayment } from '../controllers/payment.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = Router();

// Webhook must be public so Paystack can post events to it
router.post('/webhook', handleWebhook);

// Verification routes
router.get('/verify/:reference', authenticate, verifyPayment);
router.get('/verify', authenticate, verifyPayment);

// Protected route
router.post('/initialize', authenticate, initializePayment);

export default router;