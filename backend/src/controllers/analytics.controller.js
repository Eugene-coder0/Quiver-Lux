import { prisma } from '../lib/prisma.js';
import { ApiResponse } from '../utils/apiResponse.js';
import { ApiError } from '../utils/apiError.js';

export const getVendorAnalytics = async (req, res, next) => {
  try {
    const vendor = await prisma.vendor.findUnique({
      where: { userId: req.user.id },
    });

    if (!vendor) throw new ApiError(404, 'Vendor profile not found');

    const [totalProducts, paidVendorOrders, soldLineItems] = await Promise.all([
      prisma.product.count({
        where: { vendorId: vendor.id },
      }),
      prisma.vendorOrder.findMany({
        where: {
          vendorId: vendor.id,
          order: {
            paymentStatus: 'SUCCESS',
          },
        },
      }),
      prisma.orderItem.findMany({
        where: {
          vendorOrder: {
            vendorId: vendor.id,
            order: {
              paymentStatus: 'SUCCESS',
            },
          },
        },
      }),
    ]);

    const totalSoldUnits = soldLineItems.reduce((sum, item) => sum + item.quantity, 0);
    const totalEarnings = paidVendorOrders.reduce(
      (sum, order) => sum + Number(order.vendorEarnings),
      0
    );

    return ApiResponse.success(res, 200, 'Vendor analytics loaded', {
      totalProducts,
      totalSoldUnits,
      totalVendorOrders: paidVendorOrders.length,
      totalEarnings,
    });
  } catch (error) {
    next(error);
  }
};

export const getAdminAnalytics = async (req, res, next) => {
  try {
    if (req.user.role !== 'ADMIN') {
      throw new ApiError(403, 'Access denied. Admin authorization required.');
    }

    const [
      totalUsers,
      totalCustomers,
      totalVendors,
      totalProducts,
      totalOrders,
      totalCustomerSignIns,
      paidOrders,
      vendorOrders,
    ] = await Promise.all([
      prisma.user.count(),
      prisma.user.count({ where: { role: 'CUSTOMER' } }),
      prisma.vendor.count(),
      prisma.product.count(),
      prisma.order.count(),
      prisma.loginEvent.count({ where: { role: 'CUSTOMER' } }),
      prisma.order.findMany({
        where: { paymentStatus: 'SUCCESS' },
        select: { totalAmount: true },
      }),
      prisma.vendorOrder.findMany({
        where: {
          order: {
            paymentStatus: 'SUCCESS',
          },
        },
        select: { commissionAmount: true },
      }),
    ]);

    const totalPlatformRevenue = paidOrders.reduce(
      (sum, order) => sum + Number(order.totalAmount),
      0
    );
    const totalPlatformCommission = vendorOrders.reduce(
      (sum, order) => sum + Number(order.commissionAmount),
      0
    );

    return ApiResponse.success(res, 200, 'Admin analytics loaded', {
      totalUsers,
      totalCustomers,
      totalVendors,
      totalProducts,
      totalOrders,
      totalCustomerSignIns,
      totalPlatformRevenue,
      totalPlatformCommission,
    });
  } catch (error) {
    next(error);
  }
};
