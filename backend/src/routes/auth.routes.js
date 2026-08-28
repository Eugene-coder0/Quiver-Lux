import { Router } from 'express';
import {
  register,
  login,
  getProfile,
  getUsers,
  getPaystackBanks,
  verifyPaystackAccount,
} from '../controllers/auth.controller.js';
import { authenticate, authenticateAdminPortal } from '../middleware/auth.middleware.js';

const router = Router();

router.get('/paystack/banks', getPaystackBanks);
router.post('/paystack/verify-account', verifyPaystackAccount);
router.post('/register', register);
router.post('/login', login);
router.get('/me', authenticate, getProfile);
router.get('/users', authenticateAdminPortal, getUsers);

export default router;
