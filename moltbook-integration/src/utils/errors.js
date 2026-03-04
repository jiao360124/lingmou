/**
 * Custom Error Classes for Moltbook Integration
 */

export class MoltbookError extends Error {
  constructor(message, statusCode = null, code = null) {
    super(message);
    this.name = this.constructor.name;
    this.statusCode = statusCode;
    this.code = code;
    Error.captureStackTrace(this, this.constructor);
  }
}

export class AuthenticationError extends MoltbookError {
  constructor(message = 'Authentication failed') {
    super(message, 401, 'AUTHENTICATION_FAILED');
  }
}

export class RateLimitError extends MoltbookError {
  constructor(message = 'Rate limit exceeded', retryAfter = null) {
    super(message, 429, 'RATE_LIMIT_EXCEEDED');
    this.retryAfter = retryAfter;
  }
}

export class NotFoundError extends MoltbookError {
  constructor(message = 'Resource not found') {
    super(message, 404, 'NOT_FOUND');
  }
}

export class ValidationError extends MoltbookError {
  constructor(message = 'Validation error') {
    super(message, 400, 'VALIDATION_ERROR');
  }
}

export class ConflictError extends MoltbookError {
  constructor(message = 'Conflict occurred') {
    super(message, 409, 'CONFLICT');
  }
}

export class ForbiddenError extends MoltbookError {
  constructor(message = 'Access forbidden') {
    super(message, 403, 'FORBIDDEN');
  }
}

export class NetworkError extends MoltbookError {
  constructor(message = 'Network error') {
    super(message, 0, 'NETWORK_ERROR');
  }
}

/**
 * Handle API error responses
 */
export function handleApiError(response) {
  const errorData = response.data;

  switch (response.status) {
    case 401:
      throw new AuthenticationError(
        errorData.error || 'Authentication failed',
        errorData.hint
      );
    case 403:
      throw new ForbiddenError(
        errorData.error || 'Access forbidden'
      );
    case 404:
      throw new NotFoundError(
        errorData.error || 'Resource not found'
      );
    case 409:
      throw new ConflictError(
        errorData.error || 'Conflict occurred'
      );
    case 429:
      throw new RateLimitError(
        errorData.error || 'Rate limit exceeded',
        errorData.retry_after_seconds
      );
    case 500:
    case 502:
    case 503:
    case 504:
      throw new MoltbookError(
        errorData.error || 'Internal server error',
        response.status
      );
    default:
      throw new MoltbookError(
        errorData.error || `Unexpected error: ${response.status}`,
        response.status
      );
  }
}
