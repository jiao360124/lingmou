/**
 * Retry Utility
 */

/**
 * Execute a function with retry logic
 */
export async function withRetry(fn, options = {}) {
  const {
    maxRetries = 3,
    delay = 1000,
    backoff = 'exponential',
    retryableErrors = []
  } = options;

  let lastError = null;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;

      // Check if error is retryable
      if (retryableErrors.length > 0 &&
          !retryableErrors.some(retryable => error.code === retryable)) {
        throw error;
      }

      // Don't retry on last attempt
      if (attempt >= maxRetries) {
        break;
      }

      // Calculate delay
      const currentDelay = backoff === 'exponential'
        ? delay * Math.pow(2, attempt - 1)
        : delay;

      console.log(`Attempt ${attempt}/${maxRetries} failed. Retrying in ${currentDelay}ms...`);

      // Wait before retry
      await new Promise(resolve => setTimeout(resolve, currentDelay));
    }
  }

  throw lastError;
}

/**
 * Retry with exponential backoff
 */
export async function retryWithExponentialBackoff(fn, maxRetries = 3, baseDelay = 1000) {
  return withRetry(fn, {
    maxRetries,
    delay: baseDelay,
    backoff: 'exponential'
  });
}

/**
 * Retry with fixed delay
 */
export async function retryWithFixedDelay(fn, maxRetries = 3, delay = 1000) {
  return withRetry(fn, {
    maxRetries,
    delay,
    backoff: 'fixed'
  });
}
