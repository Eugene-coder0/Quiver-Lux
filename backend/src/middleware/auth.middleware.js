import { verifyToken } from '../utils/jwt.js';
import { ApiError } from '../utils/apiError.js';
import { prisma } from '../lib/prisma.js';

export const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new ApiError(401, 'Authentication token missing or invalid');
    }

    const token = authHeader.split(' ')[1];
    const decoded = verifyToken(token);

    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true,
        email: true,
        role: true,
        firstName: true,
        lastName: true,
        phone: true,
      },
    });

    if (!user) {
      throw new ApiError(401, 'User associated with token no longer exists');
    }

    req.user = user;
    next();
  } catch (error) {
    next(error instanceof ApiError ? error : new ApiError(401, 'Invalid or expired authentication token'));
  }
};

export const authenticateAdminPortal = async (req, res, next) => {
  if (
    process.env.NODE_ENV === 'development' &&
    !req.headers.authorization
  ) {
    req.user = { id: 'development-admin', role: 'ADMIN' };
    return next();
  }

  return authenticate(req, res, next);
};

export const optionalAuthenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next();
    }

    const token = authHeader.split(' ')[1];
    const decoded = verifyToken(token);
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true,
        email: true,
        role: true,
        firstName: true,
        lastName: true,
        phone: true,
      },
    });
    if (user) req.user = user;
  } catch (_) {
    // Public routes still work without a valid token
  }
  next();
};

export const authorize = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user || !allowedRoles.includes(req.user.role)) {
      return next(new ApiError(403, 'Forbidden: Insufficient privileges for this action'));
    }
    next();
  };
};
