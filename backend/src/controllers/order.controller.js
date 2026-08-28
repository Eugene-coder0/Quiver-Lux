import { prisma } from '../lib/prisma.js';
import {
  createTransactionSplit,
  initializePayment,
  verifyPaymentTransaction,
} from '../services/paystack.service.js';
import { finalizeSuccessfulPayment, markPaymentFailed } from '../services/order_payment.service.js';
import { isMockPaystackSubaccountCode } from '../services/vendor_paystack.service.js';
import { ApiResponse } from '../utils/apiResponse.js';
import { ApiError } from '../utils/apiError.js';
import { serializeProduct } from '../utils/productMapper.js';

const vendorOrderInclude = {
  vendor: {
    select: {
      id: true,
      storeName: true,
      brandName: true,
      storeLogo: true,
    },
  },
  orderItems: {
    include: {
      product: {
        include: {
          images: true,
          category: true,
          vendor: {
            select: {
              id: true,
              storeName: true,
              brandName: true,
              storeLogo: true,
            },
          },
        },
      },
    },
  },
  order: {
    include: {
      user: true,
      payment: true,
    },
  },
};

const FULFILLMENT_STATUSES = ['PENDING', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED'];
const PAYMENT_STATUSES = ['PENDING', 'SUCCESS', 'FAILED'];
const PAYSTACK_CHANNELS = ['card', 'bank', 'bank_transfer', 'ussd'];
const PAYMENT_METHODS = [...PAYSTACK_CHANNELS, 'manual_bank_transfer'];
const VENDOR_ALLOWED_TRANSITIONS = {
  PENDING: ['PROCESSING', 'CANCELLED'],
  PROCESSING: ['SHIPPED', 'CANCELLED'],
  SHIPPED: ['DELIVERED'],
  DELIVERED: [],
  CANCELLED: [],
};

const toAddressString = (address) => {
  if (!address) return '';
  if (typeof address === 'string') return address;
  return [
    address.streetLine1,
    address.streetLine2,
    address.city,
    address.state,
    address.country,
  ]
    .filter(Boolean)
    .join(', ');
};

const normalizePaymentStatus = (status) => {
  const paymentStatus = String(status || 'PENDING').toUpperCase();
  return PAYMENT_STATUSES.includes(paymentStatus) ? paymentStatus : 'PENDING';
};

const normalizeFulfillmentStatus = (status) => {
  const fulfillmentStatus = String(status || 'PENDING').toUpperCase();
  return FULFILLMENT_STATUSES.includes(fulfillmentStatus) ? fulfillmentStatus : 'PENDING';
};

const deriveLifecycleStatus = ({ paymentStatus, fulfillmentStatus }) => {
  const normalizedPayment = normalizePaymentStatus(paymentStatus);
  const normalizedFulfillment = normalizeFulfillmentStatus(fulfillmentStatus);

  if (normalizedFulfillment === 'CANCELLED') return 'cancelled';
  if (normalizedPayment !== 'SUCCESS') return 'payment_pending';
  if (normalizedFulfillment === 'PENDING') return 'paid';
  if (normalizedFulfillment === 'PROCESSING') return 'processing';
  if (normalizedFulfillment === 'SHIPPED') return 'shipped';
  if (normalizedFulfillment === 'DELIVERED') return 'delivered';
  return 'payment_pending';
};

const normalizePaymentMethod = (value) => {
  const method = String(value || 'card').toLowerCase();
  return PAYMENT_METHODS.includes(method) ? method : 'card';
};

const buildVendorSettlementDetails = (vendor) => ({
  vendorName: vendor?.brandName || vendor?.storeName || 'Quiver Lux Vendor',
  paystackBusinessName:
    vendor?.paystackBusinessName || vendor?.brandName || vendor?.storeName || '',
  paystackAccountName: vendor?.paystackAccountName || '',
  paystackAccountNumber: vendor?.paystackAccountNumber || '',
  paystackBankCode: vendor?.paystackBankCode || '',
});

const serializeVendorOrder = (vendorOrder) => {
  const paymentStatus = normalizePaymentStatus(
    vendorOrder.order?.payment?.status || vendorOrder.order?.paymentStatus
  );
  const fulfillmentStatus = normalizeFulfillmentStatus(vendorOrder.status);
  const paymentMethod = normalizePaymentMethod(vendorOrder.order?.payment?.paystackChannel);

  return {
    id: vendorOrder.id,
    orderId: vendorOrder.order?.orderNumber || '',
    vendorOrderId: vendorOrder.id,
    vendorId: vendorOrder.vendorId,
    vendorName: vendorOrder.vendor?.brandName || vendorOrder.vendor?.storeName || 'Quiver Lux Vendor',
    paymentStatus: paymentStatus.toLowerCase(),
    paymentMethod,
    fulfillmentStatus: fulfillmentStatus.toLowerCase(),
    lifecycleStatus: deriveLifecycleStatus({ paymentStatus, fulfillmentStatus }),
    trackingNote: vendorOrder.statusNote || '',
    trackingNumber: vendorOrder.trackingNumber || '',
    createdAt: vendorOrder.createdAt,
    updatedAt: vendorOrder.updatedAt,
    totalAmount: Number(vendorOrder.subtotal),
    vendorEarnings: Number(vendorOrder.vendorEarnings),
    commissionAmount: Number(vendorOrder.commissionAmount),
    customerName:
      [vendorOrder.order?.user?.firstName, vendorOrder.order?.user?.lastName].filter(Boolean).join(' ') ||
      'Guest shopper',
    customerEmail: vendorOrder.order?.user?.email || '',
    customerPhone:
      vendorOrder.order?.shippingAddressSnapshot?.phone ||
      vendorOrder.order?.user?.phone ||
      '',
    deliveryAddress: toAddressString(vendorOrder.order?.shippingAddressSnapshot),
    shippingAddress: vendorOrder.order?.shippingAddressSnapshot || null,
    ...buildVendorSettlementDetails(vendorOrder.vendor),
    items: (vendorOrder.orderItems || []).map((item) => ({
      id: item.id,
      quantity: item.quantity,
      totalPrice: Number(item.subtotal),
      product: serializeProduct(item.product),
    })),
  };
};

const buildLineItemsFromPayload = async (items) => {
  if (!Array.isArray(items) || items.length === 0) {
    throw new ApiError(400, 'Cart items are required for checkout');
  }

  const productIds = items.map((item) => item.productId).filter(Boolean);
  const products = await prisma.product.findMany({
    where: {
      id: { in: productIds },
      isActive: true,
      approvalStatus: 'APPROVED',
    },
    include: {
      vendor: true,
    },
  });

  const productMap = new Map(products.map((product) => [product.id, product]));
  const lineItems = [];

  for (const item of items) {
    const product = productMap.get(item.productId);
    if (!product) throw new ApiError(400, 'One or more products are no longer available');

    const quantity = Math.max(1, parseInt(item.quantity, 10) || 1);
    if (product.stockQuantity < quantity) {
      throw new ApiError(400, `${product.name} does not have enough stock for this order`);
    }

    if (!product.vendor?.paystackSetupComplete) {
      throw new ApiError(
        400,
        `${product.vendor?.brandName || product.vendor?.storeName || 'A vendor'} has not completed Paystack setup`
      );
    }

    const liveDiscount =
      product.isLimitedOffer &&
      product.discountPrice != null &&
      (!product.offerStartsAt || product.offerStartsAt <= new Date()) &&
      (!product.offerEndsAt || product.offerEndsAt >= new Date());
    const unitPrice = Number(liveDiscount ? product.discountPrice : product.price);
    lineItems.push({
      product,
      quantity,
      unitPrice,
      subtotal: unitPrice * quantity,
    });
  }

  return lineItems;
};

const loadVendorScopedOrder = async (req) => {
  const vendor = req.user.role === 'ADMIN'
    ? null
    : await prisma.vendor.findUnique({ where: { userId: req.user.id } });

  if (req.user.role !== 'ADMIN' && !vendor) {
    throw new ApiError(404, 'Vendor profile not found');
  }

  const existing = await prisma.vendorOrder.findFirst({
    where: {
      id: req.params.id,
      ...(req.user.role === 'ADMIN' ? {} : { vendorId: vendor.id }),
    },
    include: vendorOrderInclude,
  });

  if (!existing) {
    throw new ApiError(404, 'Vendor order not found');
  }

  return existing;
};

export const checkout = async (req, res, next) => {
  try {
    const {
      shippingAddress,
      items = [],
      callbackUrl,
      paymentMethod: rawPaymentMethod,
      paymentChannel: rawPaymentChannel,
    } = req.body;
    if (!shippingAddress) throw new ApiError(400, 'Shipping address details are required');
    const paymentMethod = normalizePaymentMethod(rawPaymentMethod || rawPaymentChannel);

    const lineItems = await buildLineItemsFromPayload(items);
    const itemsByVendor = new Map();
    let grandTotal = 0;

    for (const line of lineItems) {
      grandTotal += line.subtotal;
      const vendorId = line.product.vendorId;
      const group = itemsByVendor.get(vendorId) || {
        vendor: line.product.vendor,
        items: [],
        vendorSubtotal: 0,
      };
      group.items.push(line);
      group.vendorSubtotal += line.subtotal;
      itemsByVendor.set(vendorId, group);
    }

    const orderNumber = `QL-${Date.now()}-${Math.floor(1000 + Math.random() * 9000)}`;

    const newOrder = await prisma.$transaction(async (tx) => {
      const mainOrder = await tx.order.create({
        data: {
          orderNumber,
          userId: req.user.id,
          totalAmount: grandTotal,
          shippingAddressSnapshot: shippingAddress,
          paymentStatus: 'PENDING',
        },
      });

      for (const [vendorId, vendorGroup] of itemsByVendor.entries()) {
        const commissionRate = Number(vendorGroup.vendor.commissionRate) / 100;
        const commissionAmount = vendorGroup.vendorSubtotal * commissionRate;
        const vendorEarnings = vendorGroup.vendorSubtotal - commissionAmount;

        const vendorOrder = await tx.vendorOrder.create({
          data: {
            orderId: mainOrder.id,
            vendorId,
            subtotal: vendorGroup.vendorSubtotal,
            commissionAmount,
            vendorEarnings,
            status: 'PENDING',
          },
        });

        for (const item of vendorGroup.items) {
          await tx.orderItem.create({
            data: {
              vendorOrderId: vendorOrder.id,
              productId: item.product.id,
              productName: item.product.name,
              unitPrice: item.unitPrice,
              quantity: item.quantity,
              subtotal: item.subtotal,
            },
          });
        }
      }

      return mainOrder;
    });

    const splits = Array.from(itemsByVendor.values()).map((group) => ({
      vendorId: group.vendor.id,
      storeName: group.vendor.brandName || group.vendor.storeName,
      recipientCode: group.vendor.paystackRecipientCode,
      subaccountCode: group.vendor.paystackSubaccountCode,
      subtotal: group.vendorSubtotal,
      commissionRate: Number(group.vendor.commissionRate),
      vendorEarnings:
        group.vendorSubtotal -
        group.vendorSubtotal * (Number(group.vendor.commissionRate) / 100),
    }));

    const bankTransferVendors = Array.from(itemsByVendor.values()).map((group) => ({
      vendorId: group.vendor.id,
      subtotal: group.vendorSubtotal,
      ...buildVendorSettlementDetails(group.vendor),
    }));

    if (paymentMethod === 'manual_bank_transfer') {
      await prisma.payment.create({
        data: {
          orderId: newOrder.id,
          paystackReference: `MBT-${orderNumber}`,
          amount: grandTotal,
          status: 'PENDING',
          paystackChannel: 'manual_bank_transfer',
          rawResponse: {
            paymentMethod: 'manual_bank_transfer',
            vendors: bankTransferVendors,
          },
        },
      });

      return ApiResponse.success(res, 201, 'Order created. Awaiting bank transfer confirmation', {
        orderId: newOrder.id,
        orderNumber,
        totalAmount: grandTotal,
        reference: `MBT-${orderNumber}`,
        paymentStatus: 'pending',
        paymentMethod: 'manual_bank_transfer',
        fulfillmentStatus: 'pending',
        lifecycleStatus: 'payment_pending',
        bankTransfer: {
          vendors: bankTransferVendors,
          instruction:
            'Transfer to the vendor account shown below. The vendor or admin will confirm receipt before fulfillment begins.',
        },
      });
    }

    const amountInKobo = Math.round(grandTotal * 100);
    if (splits.some((splitItem) => !splitItem.subaccountCode)) {
      throw new ApiError(
        400,
        'One or more vendors have not completed the Paystack subaccount setup required for checkout'
      );
    }
    const canUseRealSplitRouting = splits.every(
      (splitItem) => !isMockPaystackSubaccountCode(splitItem.subaccountCode)
    );
    let splitCode;
    if (!canUseRealSplitRouting) {
      splitCode = undefined;
    } else if (splits.length === 1 && splits[0].subaccountCode) {
      splitCode = undefined;
    } else {
      const split = await createTransactionSplit({
        name: `Quiver Lux ${orderNumber}`,
        currency: 'NGN',
        subaccounts: splits.map((splitItem) => ({
          subaccount: splitItem.subaccountCode,
          share: Math.round(splitItem.vendorEarnings * 100),
        })),
      });
      splitCode = split.split_code;
    }
    let paystackData;
    try {
      paystackData = await initializePayment({
        email: req.user.email,
        amountInKobo,
        reference: orderNumber,
        metadata: {
          orderId: newOrder.id,
          userId: req.user.id,
          splits,
          paymentChannel: paymentMethod,
        },
        callbackUrl: typeof callbackUrl === 'string' && callbackUrl.trim().isNotEmpty
          ? callbackUrl.trim()
          : undefined,
        channels: PAYSTACK_CHANNELS.includes(paymentMethod) ? [paymentMethod] : undefined,
        splitCode,
        subaccount:
          canUseRealSplitRouting && splits.length === 1 ? splits[0].subaccountCode : undefined,
      });
    } catch (error) {
      await prisma.order.delete({
        where: { id: newOrder.id },
      });
      throw error;
    }

    await prisma.payment.create({
      data: {
        orderId: newOrder.id,
        paystackReference: orderNumber,
        amount: grandTotal,
        status: 'PENDING',
        paystackChannel: paymentMethod,
        rawResponse: {
          ...paystackData,
          splitCode,
        },
      },
    });

    return ApiResponse.success(res, 201, 'Order created and payment initialized', {
      orderId: newOrder.id,
      orderNumber,
      totalAmount: grandTotal,
      paymentUrl: paystackData.authorization_url,
      accessCode: paystackData.access_code,
      reference: orderNumber,
      paymentStatus: 'pending',
      paymentMethod,
      fulfillmentStatus: 'pending',
      lifecycleStatus: 'payment_pending',
    });
  } catch (error) {
    next(error);
  }
};

export const verifyPayment = async (req, res, next) => {
  try {
    const { reference } = req.query;
    if (!reference) throw new ApiError(400, 'Payment reference is required');

    const paystackVerification = await verifyPaymentTransaction(reference);
    const paymentStatus = String(paystackVerification.status || '').toLowerCase();

    if (paymentStatus === 'success') {
      await finalizeSuccessfulPayment(reference, paystackVerification);
    } else {
      await markPaymentFailed(reference, paystackVerification);
    }

    const orders = await prisma.vendorOrder.findMany({
      where: {
        order: {
          payment: {
            paystackReference: String(reference),
          },
        },
      },
      include: vendorOrderInclude,
      orderBy: { createdAt: 'asc' },
    });

    const serializedOrders = orders.map(serializeVendorOrder);
    const leadOrder = serializedOrders[0] ?? null;

    return ApiResponse.success(res, 200, 'Payment verification completed', {
      status: paymentStatus === 'success' ? 'success' : 'failed',
      reference: String(reference),
      paymentStatus: paymentStatus === 'success' ? 'success' : 'failed',
      lifecycleStatus: leadOrder?.lifecycleStatus ?? 'payment_pending',
      orders: serializedOrders,
    });
  } catch (error) {
    next(error);
  }
};

export const getCustomerOrders = async (req, res, next) => {
  try {
    const vendorOrders = await prisma.vendorOrder.findMany({
      where: {
        order: {
          userId: req.user.id,
        },
      },
      include: vendorOrderInclude,
      orderBy: { createdAt: 'desc' },
    });

    return ApiResponse.success(res, 200, 'Orders retrieved successfully', {
      orders: vendorOrders.map(serializeVendorOrder),
    });
  } catch (error) {
    next(error);
  }
};

export const getPortalOrders = async (req, res, next) => {
  try {
    const vendor = req.user.role === 'ADMIN'
      ? null
      : await prisma.vendor.findUnique({ where: { userId: req.user.id } });

    if (req.user.role !== 'ADMIN' && !vendor) {
      throw new ApiError(404, 'Vendor profile not found');
    }

    const orders = await prisma.vendorOrder.findMany({
      where: {
        ...(req.user.role === 'ADMIN' ? {} : { vendorId: vendor.id }),
        OR: [
          {
            order: {
              paymentStatus: 'SUCCESS',
            },
          },
          {
            order: {
              payment: {
                is: {
                  paystackChannel: 'bank_transfer',
                },
              },
            },
          },
        ],
      },
      include: vendorOrderInclude,
      orderBy: { createdAt: 'desc' },
    });

    return ApiResponse.success(res, 200, 'Portal orders retrieved successfully', {
      orders: orders.map(serializeVendorOrder),
    });
  } catch (error) {
    next(error);
  }
};

export const confirmPortalOrderPayment = async (req, res, next) => {
  try {
    const existing = await loadVendorScopedOrder(req);
    const payment = existing.order?.payment;
    if (!payment) {
      throw new ApiError(404, 'Payment record not found for this order');
    }
    if (normalizePaymentMethod(payment.paystackChannel) != 'manual_bank_transfer') {
      throw new ApiError(400, 'Only bank transfer orders can be manually confirmed');
    }
    if (normalizePaymentStatus(payment.status) === 'SUCCESS') {
      throw new ApiError(400, 'This payment has already been confirmed');
    }

    await finalizeSuccessfulPayment(payment.paystackReference, {
      status: 'success',
      channel: 'bank_transfer',
      reference: payment.paystackReference,
      confirmedBy: req.user.id,
      confirmedAt: new Date().toISOString(),
    });

    const refreshed = await loadVendorScopedOrder(req);
    return ApiResponse.success(res, 200, 'Bank transfer payment confirmed successfully', {
      order: serializeVendorOrder(refreshed),
    });
  } catch (error) {
    next(error);
  }
};

export const updatePortalOrderStatus = async (req, res, next) => {
  try {
    const { status, trackingNote, trackingNumber } = req.body;
    const nextStatus = normalizeFulfillmentStatus(status);

    if (!FULFILLMENT_STATUSES.includes(nextStatus)) {
      throw new ApiError(400, 'Invalid order status supplied');
    }

    const existing = await loadVendorScopedOrder(req);
    const currentStatus = normalizeFulfillmentStatus(existing.status);
    const paymentStatus = normalizePaymentStatus(
      existing.order?.payment?.status || existing.order?.paymentStatus
    );
    const isAdminOverride = req.user.role === 'ADMIN';

    if (paymentStatus !== 'SUCCESS' && nextStatus !== 'CANCELLED' && nextStatus !== currentStatus) {
      throw new ApiError(400, 'Only paid orders can move into fulfillment updates');
    }

    if (!isAdminOverride && nextStatus !== currentStatus) {
      const allowedTransitions = VENDOR_ALLOWED_TRANSITIONS[currentStatus] ?? [];
      if (!allowedTransitions.includes(nextStatus)) {
        throw new ApiError(
          400,
          `Vendors cannot move an order from ${currentStatus.toLowerCase()} to ${nextStatus.toLowerCase()}`
        );
      }
    }

    const updated = await prisma.vendorOrder.update({
      where: { id: existing.id },
      data: {
        status: nextStatus,
        statusNote: trackingNote !== undefined ? trackingNote : existing.statusNote,
        trackingNumber:
          trackingNumber !== undefined ? trackingNumber : existing.trackingNumber,
      },
      include: vendorOrderInclude,
    });

    return ApiResponse.success(res, 200, 'Order tracking updated successfully', {
      order: serializeVendorOrder(updated),
    });
  } catch (error) {
    next(error);
  }
};
