import { prisma } from '../lib/prisma.js';
import { ApiError } from '../utils/apiError.js';
import { createTransactionSplit } from './paystack.service.js';
import { isMockPaystackSubaccountCode } from './vendor_paystack.service.js';

export const buildVendorSplits = (vendorOrders) =>
  vendorOrders.map((vendorOrder) => ({
    vendorId: vendorOrder.vendorId,
    storeName: vendorOrder.vendor?.brandName || vendorOrder.vendor?.storeName,
    recipientCode: vendorOrder.vendor?.paystackRecipientCode,
    subaccountCode: vendorOrder.vendor?.paystackSubaccountCode,
    subtotal: Number(vendorOrder.subtotal),
    commissionRate: Number(vendorOrder.vendor?.commissionRate ?? 0),
    vendorEarnings: Number(
      vendorOrder.vendorEarnings ??
        Number(vendorOrder.subtotal) -
          Number(vendorOrder.subtotal) * (Number(vendorOrder.vendor?.commissionRate ?? 0) / 100)
    ),
  }));

export const resolvePaystackRouting = async ({ orderNumber, splits }) => {
  const canUseRealSplitRouting =
    splits.length > 0 &&
    splits.every(
      (splitItem) => splitItem.subaccountCode && !isMockPaystackSubaccountCode(splitItem.subaccountCode)
    );

  if (!canUseRealSplitRouting) {
    return {};
  }

  if (splits.length === 1) {
    const commissionKobo = Math.round(
      splits[0].subtotal * (splits[0].commissionRate / 100) * 100
    );
    return {
      subaccount: splits[0].subaccountCode,
      transactionCharge: Math.max(0, commissionKobo),
    };
  }

  const split = await createTransactionSplit({
    name: `Quiver Lux ${orderNumber}`,
    currency: 'NGN',
    subaccounts: splits.map((splitItem) => ({
      subaccount: splitItem.subaccountCode,
      share: Math.round(splitItem.vendorEarnings * 100),
    })),
  });

  if (!split?.split_code) {
    throw new ApiError(
      400,
      'Unable to create the Paystack split. Confirm each vendor bank setup and try again.'
    );
  }

  return { splitCode: split.split_code };
};

export const reserveStockForItems = async (tx, items) => {
  for (const item of items) {
    const updated = await tx.product.updateMany({
      where: {
        id: item.productId,
        stockQuantity: { gte: item.quantity },
      },
      data: {
        stockQuantity: {
          decrement: item.quantity,
        },
      },
    });
    if (updated.count !== 1) {
      throw new ApiError(400, 'One or more products do not have enough stock for this order');
    }
  }
};

export const restoreStockForOrderId = async (orderId) => {
  const vendorOrders = await prisma.vendorOrder.findMany({
    where: { orderId },
    include: { orderItems: true },
  });

  await prisma.$transaction(async (tx) => {
    for (const vendorOrder of vendorOrders) {
      for (const item of vendorOrder.orderItems) {
        await tx.product.update({
          where: { id: item.productId },
          data: {
            stockQuantity: {
              increment: item.quantity,
            },
          },
        });
      }
    }
  });
};

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

  await prisma.$transaction(async (tx) => {
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

  if (!payment || payment.status === 'SUCCESS' || payment.status === 'FAILED') {
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

  await restoreStockForOrderId(payment.orderId);

  return payment;
};
