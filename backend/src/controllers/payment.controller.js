import crypto from 'crypto';

import { prisma } from '../lib/prisma.js';
import { env } from '../config/env.js';
import { ApiResponse } from '../utils/apiResponse.js';
import { ApiError } from '../utils/apiError.js';
import { initializePayment as initializePaystackPayment } from '../services/paystack.service.js';
import { verifyPaymentTransaction } from '../services/paystack.service.js';
import { finalizeSuccessfulPayment } from '../services/order_payment.service.js';

export const initializePayment = async (req, res, next) => {
  try {
    const { orderId, callbackUrl } = req.body;
    if (!orderId) throw new ApiError(400, 'Order ID is required');

    const order = await prisma.order.findFirst({
      where: { id: orderId, userId: req.user.id },
      include: {
        payment: true,
        vendorOrders: {
          include: {
            vendor: true,
          },
        },
      },
    });

    if (!order) throw new ApiError(404, 'Order not found');
    if (order.paymentStatus === 'SUCCESS') {
      throw new ApiError(400, 'Order has already been paid');
    }

    const reference = order.payment?.paystackReference || `QL-${Date.now()}-${order.id.slice(0, 6)}`;
    const splits = order.vendorOrders.map((vendorOrder) => ({
      vendorId: vendorOrder.vendorId,
      storeName: vendorOrder.vendor?.brandName || vendorOrder.vendor?.storeName,
      recipientCode: vendorOrder.vendor?.paystackRecipientCode,
      subaccountCode: vendorOrder.vendor?.paystackSubaccountCode,
      subtotal: Number(vendorOrder.subtotal),
      commissionRate: Number(vendorOrder.vendor?.commissionRate ?? 0),
    }));

    const paystackData = await initializePaystackPayment({
      email: req.user.email,
      amountInKobo: Math.round(Number(order.totalAmount) * 100),
      reference,
      metadata: {
        orderId: order.id,
        userId: req.user.id,
        splits,
      },
      callbackUrl: typeof callbackUrl === 'string' && callbackUrl.trim().isNotEmpty
        ? callbackUrl.trim()
        : undefined,
    });

    if (order.payment) {
      await prisma.payment.update({
        where: { id: order.payment.id },
        data: {
          paystackReference: reference,
          rawResponse: paystackData,
        },
      });
    } else {
      await prisma.payment.create({
        data: {
          orderId: order.id,
          paystackReference: reference,
          amount: Number(order.totalAmount),
          status: 'PENDING',
          rawResponse: paystackData,
        },
      });
    }

    return ApiResponse.success(res, 200, 'Payment initialized successfully', {
      authorizationUrl: paystackData.authorization_url,
      accessCode: paystackData.access_code,
      reference,
    });
  } catch (error) {
    next(error);
  }
};

export const handleWebhook = async (req, res, next) => {
  try {
    const hash = crypto
      .createHmac('sha512', env.PAYSTACK_SECRET_KEY)
      .update(JSON.stringify(req.body))
      .digest('hex');

    if (hash !== req.headers['x-paystack-signature']) {
      return res.status(400).send('Invalid signature');
    }

    const event = req.body;
    if (event.event === 'charge.success') {
      const reference = event.data?.reference;
      if (reference) {
        await finalizeSuccessfulPayment(reference, event.data);
      }
    }

    return res.status(200).json({ status: 'success' });
  } catch (error) {
    next(error);
  }
};

export const verifyPaymentReference = async (reference) => {
  const payload = await verifyPaymentTransaction(reference);
  if (payload.status === 'success') {
    await finalizeSuccessfulPayment(reference, payload);
  }
  return payload;
};
