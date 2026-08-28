export class ApiError extends Error {
  constructor(statusCode, message, errorDetails = null) {
    super(message);
    this.statusCode = statusCode;
    this.errorDetails = errorDetails;
    Error.captureStackTrace(this, this.constructor);
    console.log('apiError module loaded successfully');
  }
}