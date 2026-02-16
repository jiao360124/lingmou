/**
 * Error Handling Middleware
 * 统一错误处理
 */

/**
 * 错误处理中间件
 * @param {Error} err - 错误对象
 * @param {Request} req - Express请求对象
 * @param {Response} res - Express响应对象
 * @param {Function} next - Express下一个中间件
 */
function errorHandler(err, req, res, next) {
  console.error('[Error]', {
    message: err.message,
    stack: err.stack,
    url: req.originalUrl,
    method: req.method
  });

  const statusCode = err.statusCode || 500;
  const isDevelopment = process.env.NODE_ENV === 'development';

  res.status(statusCode).json({
    success: false,
    error: {
      message: err.message || 'Internal Server Error',
      ...(isDevelopment && { stack: err.stack })
    },
    timestamp: Date.now()
  });
}

/**
 * 自定义错误类
 */
class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * 404错误处理器
 */
function notFoundHandler(req, res, next) {
  const error = new AppError(`Route ${req.originalUrl} not found`, 404);
  next(error);
}

module.exports = {
  errorHandler,
  AppError,
  notFoundHandler
};
