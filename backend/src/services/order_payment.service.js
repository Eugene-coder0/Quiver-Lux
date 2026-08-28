import { prisma } from '../lib/prisma.js';
import { ApiError } from '../utils/apiError.js';

export const finalizeSuccessfulPayment = async (reference, payload = null) => {
  const payment = await prisma.payment.findUnique({
    where: { paystackReference: String(reference) },
    include: {
      order: {
        include: {
          vendorOrders: {
            include: {
              orderItems: true,
            },
          },
        },
      },
    },
  });

  if (!payment) {
    throw new ApiError(404, 'Payment record not found');
  }

  if (payment.status === 'SUCCESS') {
    return payment;
  }

  const orderItems = payment.order?.vendorOrders.flatMap((vendorOrder) => vendorOrder.orderItems) ?? [];
  const productIds = [...new Set(orderItems.map((item) => item.productId))];
  const products = await prisma.product.findMany({
    where: { id: { in: productIds } },
    select: { id: true, name: true, stockQuantity: true },
  });
  const productMap = new Map(products.map((product) => [product.id, product]));

  for (const item of orderItems) {
    const product = productMap.get(item.productId);
    if (!product) {
      throw new ApiError(404, 'A product in this order no longer exists');
    }
    if (product.stockQuantity < item.quantity) {
      throw new ApiError(
        409,
        `${product.name} no longer has enough stock to complete this paid order`
      );
    }
  }

  await prisma.$transaction(async (tx) => {
    for (const item of orderItems) {
      await tx.product.update({
        where: { id: item.productId },
        data: {
          stockQuantity: {
            decrement: item.quantity,
          },
        },
      });
    }

    await tx.payment.update({
      where: { id: payment.id },
      data: {
        status: 'SUCCESS',
        rawResponse: payload ?? undefined,
        verifiedAt: new Date(),
      },
    });

    await tx.order.update({
      where: { id: payment.orderId },
      data: {
        paymentStatus: 'SUCCESS',
      },
    });
  });

  return payment;
};

export const markPaymentFailed = async (reference, payload = null) => {
  const payment = await prisma.payment.findUnique({
    where: { paystackReference: String(reference) },
  });

  if (!payment || payment.status === 'SUCCESS') {
    return payment;
  }

  await prisma.$transaction([
    prisma.payment.update({
      where: { id: payment.id },
      data: {
        status: 'FAILED',
        rawResponse: payload ?? undefined,
      },
    }),
    prisma.order.update({
      where: { id: payment.orderId },
      data: {
        paymentStatus: 'FAILED',
      },
    }),
  ]);

  return payment;
};
