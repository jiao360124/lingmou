/**
 * Moltbook Integration - Main Entry Point
 */

import MoltbookClient from './MoltbookClient.js';
import { config, validateConfig } from './config/index.js';

// Create client instance
export const client = new MoltbookClient({
  apiKey: config.apiKey,
  baseUrl: config.baseUrl
});

// Export modules
export * from './MoltbookClient.js';
export * from './config/index.js';
export * from './api/agents.js';
export * from './api/posts.js';
export * from './api/comments.js';
export * from './api/submolts.js';
export * from './api/feed.js';
export * from './api/search.js';
export * from './api/voting.js';
export * from './services/CommunityService.js';
export * from './services/LearningService.js';
export * from './services/AnalyticsService.js';
export * from './models/index.js';
export * from './utils/errors.js';
export * from './utils/request.js';

export default client;

// Example usage
console.log('🚀 Moltbook Integration loaded successfully');
console.log('✨ Client ready to use');
