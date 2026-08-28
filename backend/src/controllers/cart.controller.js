import { prisma } from '../lib/prisma.js';
import { ApiResponse } from '../utils/apiResponse.js';
import { ApiError } from '../utils/apiError.js';

export const getCart = async (req, res, next) => {
  try {
    let cart = await prisma.cart.findUnique({
      where: { userId: req.user.id },
      include: {
        items: {
          include: {
            product: {
              include: {
                images: { where: { isPrimary: true } },
                vendor: { select: { storeName: true, id: true } },
              },
            },
          },
        },
      },
    });

    if (!cart) {
      cart = await prisma.cart.create({
        data: { userId: req.user.id },
        include: { items: true },
      });
    }

    return ApiResponse.success(res, 200, 'Cart retrieved successfully', { cart });
  } catch (error) {
    next(error);
  }
};

export const addToCart = async (req, res, next) => {
  try {
    const { productId, quantity = 1 } = req.body;

    if (!productId) throw new ApiError(400, 'Product ID is required');

    const product = await prisma.product.findUnique({ where: { id: productId } });
    if (!product || !product.isActive) throw new ApiError(404, 'Product not available');
    if (product.stockQuantity < quantity) throw new ApiError(400, 'Insufficient stock available');

    let cart = await prisma.cart.findUnique({ where: { userId: req.user.id } });
    if (!cart) {
      cart = await prisma.cart.create({ data: { userId: req.user.id } });
    }

    const existingItem = await prisma.cartItem.findUnique({
      cartId_productId: { cartId: cart.id, productId },
    });

    if (existingItem) {
      await prisma.cartItem.update({
        where: { id: existingItem.id },
        data: { quantity: existingItem.quantity + parseInt(quantity, 10) },
      });
    } else {
      await prisma.cartItem.create({
        data: {
          cartId: cart.id,
          productId,
          quantity: parseInt(quantity, 10),
        },
      });
    }

    return ApiResponse.success(res, 200, 'Item added to cart successfully');
  } catch (error) {
    next(error);
  }
};

export const removeFromCart = async (req, res, next) => {
  try {
    const { itemId } = req.params;

    const cart = await prisma.cart.findUnique({ where: { userId: req.user.id } });
    if (!cart) throw new ApiError(404, 'Cart not found');

    await prisma.cartItem.deleteMany({
      where: { id: itemId, cartId: cart.id },
    });

    return ApiResponse.success(res, 200, 'Item removed from cart');
  } catch (error) {
    next(error);
  }
};