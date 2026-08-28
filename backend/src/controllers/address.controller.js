import { prisma } from '../lib/prisma.js';
import { ApiResponse } from '../utils/apiResponse.js';

// GET /api/addresses - Retrieve saved user addresses
export const getAddresses = async (req, res, next) => {
  try {
    const addresses = await prisma.address.findMany({
      where: { userId: req.user.id },
      orderBy: { isDefault: 'desc' },
    });
    return ApiResponse.success(res, 200, 'Addresses retrieved successfully', addresses);
  } catch (error) {
    next(error);
  }
};

// POST /api/addresses - Save new address
export const createAddress = async (req, res, next) => {
  try {
    const { fullName, phone, streetLine1, streetLine2, city, state, country, isDefault } = req.body;

    if (isDefault) {
      await prisma.address.updateMany({
        where: { userId: req.user.id },
        data: { isDefault: false },
      });
    }

    const address = await prisma.address.create({
      data: {
        userId: req.user.id,
        fullName,
        phone,
        streetLine1,
        streetLine2,
        city,
        state,
        country: country || 'Nigeria',
        isDefault: isDefault || false,
      },
    });

    return ApiResponse.success(res, 201, 'Address created successfully', address);
  } catch (error) {
    next(error);
  }
};

// DELETE /api/addresses/:id - Delete address
export const deleteAddress = async (req, res, next) => {
  try {
    const { id } = req.params;

    await prisma.address.deleteMany({
      where: { id, userId: req.user.id },
    });

    return ApiResponse.success(res, 200, 'Address deleted successfully');
  } catch (error) {
    next(error);
  }
};