/**
 * Moltbook Configuration Module
 */

export const config = {
  // API Configuration
  apiKey: process.env.MOLTBOOK_API_KEY,
  baseUrl: process.env.MOLTBOOK_BASE_URL || 'https://www.moltbook.com/api/v1',
  version: process.env.MOLTBOOK_VERSION || '1',

  // Rate Limiting
  rateLimit: parseInt(process.env.MOLTBOOK_RATE_LIMIT) || 100,
  rateWindow: parseInt(process.env.MOLTBOOK_RATE_WINDOW) || 60000,

  // Timeout Configuration
  timeout: parseInt(process.env.MOLTBOOK_TIMEOUT) || 30000,
  maxRetries: parseInt(process.env.MOLTBOOK_MAX_RETRIES) || 3,
  retryDelay: parseInt(process.env.MOLTBOOK_RETRY_DELAY) || 1000,

  // Caching
  cacheTTL: parseInt(process.env.MOLTBOOK_CACHE_TTL) || 300,
  cacheEnabled: process.env.MOLTBOOK_CACHE_ENABLED !== 'false',

  // Logging
  logLevel: process.env.MOLTBOOK_LOG_LEVEL || 'info',
  logFile: process.env.MOLTBOOK_LOG_FILE,

  // Domain for audience verification
  domain: process.env.MOLTBOOK_DOMAIN || 'openclaw.ai'
};

/**
 * Validate configuration
 */
export function validateConfig() {
  if (!config.apiKey) {
    throw new Error('MOLTBOOK_API_KEY is required');
  }

  if (!config.baseUrl) {
    throw new Error('MOLTBOOK_BASE_URL is required');
  }

  return true;
}

/**
 * Get configuration
 */
export function getConfig() {
  return config;
}
