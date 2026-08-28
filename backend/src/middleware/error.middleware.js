import { ApiError } from '../utils/apiError.js';
import { ApiResponse } from '../utils/apiResponse.js';
import { env } from '../config/env.js';
import { logger } from '../utils/logger.js';

export const errorHandler = (err, req, res, next) => {
  let statusCode = err.statusCode || 500;
  let message = err.message || 'Internal Server Error';
  let errorDetails = err.errorDetails || null;

  if (env.NODE_ENV === 'development') {
    logger.error(`${req.method} ${req.url} - ${message}`);
    if (err.stack) console.error(err.stack);
  }

  // Handle specific known error instances
  if (err instanceof ApiError) {
    return ApiResponse.error(res, statusCode, message, errorDetails);
  }

  // Fallback for unhandled unexpected runtime exceptions
  const details = env.NODE_ENV === 'development' ? { stack: err.stack } : null;
  return ApiResponse.error(res, statusCode, message, details);
};