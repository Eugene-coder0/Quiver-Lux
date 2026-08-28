import { Router } from 'express';
import { getCart, addToCart, removeFromCart } from '../controllers/cart.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = Router();

router.use(authenticate);
router.get('/', getCart);
router.post('/add', addToCart);
router.delete('/items/:itemId', removeFromCart);

export default router;