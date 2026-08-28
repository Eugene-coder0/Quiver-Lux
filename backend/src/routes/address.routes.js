import { Router } from 'express';
import { getAddresses, createAddress, deleteAddress } from '../controllers/address.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = Router();

router.use(authenticate); // Require login for all address routes

router.get('/', getAddresses);
router.post('/', createAddress);
router.delete('/:id', deleteAddress);

export default router;