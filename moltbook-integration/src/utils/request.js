/**
 * HTTP Request Utility
 */

import axios from 'axios';
import { config, validateConfig } from '../config/index.js';
import { handleApiError, MoltbookError } from './errors.js';

export class RequestClient {
  constructor(config) {
    this.config = config;
    this.client = this.createClient();
    this.requestQueue = new Set();
    this.rateLimitWindow = new Map();
  }

  /**
   * Create Axios instance
   */
  createClient() {
    return axios.create({
      baseURL: this.config.baseUrl,
      timeout: this.config.timeout,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.config.apiKey}`
      }
    });
  }

  /**
   * Rate limit check
   */
  async checkRateLimit() {
    const now = Date.now();
    const windowStart = now - this.config.rateWindow;

    // Remove old requests
    for (const [key, timestamp] of this.rateLimitWindow) {
      if (timestamp < windowStart) {
        this.rateLimitWindow.delete(key);
      }
    }

    // Check if we've exceeded the limit
    if (this.rateLimitWindow.size >= this.config.rateLimit) {
      const oldestRequest = Math.min(...this.rateLimitWindow.values());
      const waitTime = oldestRequest + this.config.rateWindow - now;
      throw new MoltbookError(
        `Rate limit exceeded. Retry after ${Math.ceil(waitTime / 1000)} seconds`,
        429,
        'RATE_LIMIT_EXCEEDED'
      );
    }
  }

  /**
   * Make HTTP request with retry logic
   */
  async request(method, endpoint, data = null, options = {}) {
    await this.checkRateLimit();

    let lastError = null;

    for (let i = 0; i < this.config.maxRetries; i++) {
      try {
        const url = `${endpoint}`;
        const response = await this.client({
          method,
          url,
          data,
          ...options
        });

        return response;
      } catch (error) {
        lastError = error;

        // Don't retry on certain errors
        if (error.response?.status === 401 ||
            error.response?.status === 403 ||
            error.response?.status === 404) {
          throw error;
        }

        // Wait before retry
        if (i < this.config.maxRetries - 1) {
          await new Promise(resolve =>
            setTimeout(resolve, this.config.retryDelay * (i + 1))
          );
        }
      }
    }

    throw lastError;
  }

  /**
   * GET request
   */
  async get(endpoint, params = {}, options = {}) {
    return this.request('GET', endpoint, null, {
      params,
      ...options
    });
  }

  /**
   * POST request
   */
  async post(endpoint, data = {}, options = {}) {
    return this.request('POST', endpoint, data, options);
  }

  /**
   * PATCH request
   */
  async patch(endpoint, data = {}, options = {}) {
    return this.request('PATCH', endpoint, data, options);
  }

  /**
   * PUT request
   */
  async put(endpoint, data = {}, options = {}) {
    return this.request('PUT', endpoint, data, options);
  }

  /**
   * DELETE request
   */
  async delete(endpoint, options = {}) {
    return this.request('DELETE', endpoint, null, options);
  }

  /**
   * Clear rate limit window (useful for testing)
   */
  clearRateLimit() {
    this.rateLimitWindow.clear();
  }
}

/**
 * Create a new request client instance
 */
export function createRequestClient(configOverride = null) {
  const config = configOverride || config;
  return new RequestClient(config);
}
