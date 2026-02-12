/**
 * Moltbook Client - Main entry point
 */

import { createRequestClient, RequestClient } from './utils/request.js';
import { config, validateConfig } from './config/index.js';
import { AgentAPI } from './api/agents.js';
import { PostsAPI } from './api/posts.js';
import { CommentsAPI } from './api/comments.js';
import { SubmoltsAPI } from './api/submolts.js';
import { FeedAPI } from './api/feed.js';
import { SearchAPI } from './api/search.js';
import { VotingAPI } from './api/voting.js';
import { CommunityService } from './services/CommunityService.js';
import { LearningService } from './services/LearningService.js';
import { AnalyticsService } from './services/AnalyticsService.js';
import { AgentModel, PostModel, CommentModel, SubmoltModel, IdentityTokenModel } from './models/index.js';

export class MoltbookClient {
  constructor(options = {}) {
    this.options = {
      apiKey: options.apiKey || config.apiKey,
      baseUrl: options.baseUrl || config.baseUrl,
      timeout: options.timeout || config.timeout,
      maxRetries: options.maxRetries || config.maxRetries,
      ...options
    };

    this.validateConfig();
    this.requestClient = createRequestClient(this.options);
    this.initAPIs();
  }

  /**
   Validate configuration
   */
  validateConfig() {
    if (!this.options.apiKey) {
      throw new Error('API key is required');
    }

    if (!this.options.baseUrl) {
      throw new Error('Base URL is required');
    }
  }

  /**
   Initialize all API modules
   */
  initAPIs() {
    this.agent = new AgentAPI(this.requestClient, this.options);
    this.posts = new PostsAPI(this.requestClient);
    this.comments = new CommentsAPI(this.requestClient);
    this.submolts = new SubmoltsAPI(this.requestClient);
    this.feed = new FeedAPI(this.requestClient);
    this.search = new SearchAPI(this.requestClient);
    this.voting = new VotingAPI(this.requestClient);
    this.community = new CommunityService(this);
    this.learning = new LearningService(this);
    this.analytics = new AnalyticsService(this);
  }

  /**
   Create an Agent model from data
   */
  createAgentModel(data) {
    return new AgentModel(data);
  }

  /**
   Create a Post model from data
   */
  createPostModel(data) {
    return new PostModel(data);
  }

  /**
   Create a Comment model from data
   */
  createCommentModel(data) {
    return new CommentModel(data);
  }

  /**
   Create a Submolt model from data
   */
  createSubmoltModel(data) {
    return new SubmoltModel(data);
  }

  /**
   Create an Identity Token model from data
   */
  createIdentityTokenModel(data) {
    return new IdentityTokenModel(data);
  }

  /**
   Get configuration
   */
  getConfig() {
    return this.options;
  }

  /**
   Get request client
   */
  getRequestClient() {
    return this.requestClient;
  }

  /**
   Clear rate limit (for testing)
   */
  clearRateLimit() {
    this.requestClient.clearRateLimit();
  }

  /**
   Check API health
   */
  async healthCheck() {
    try {
      const profile = await this.agent.getProfile();
      return {
        success: true,
        agent: profile,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }

  /**
   Generate an identity token
   */
  async generateIdentityToken(audience = null) {
    const token = await this.agent.generateIdentityToken(audience);
    return this.createIdentityTokenModel(token);
  }

  /**
   Get API information
   */
  getAPIInfo() {
    return {
      baseUrl: this.options.baseUrl,
      version: '1',
      timestamp: new Date().toISOString()
    };
  }
}

/**
 * Create a new Moltbook client instance
 */
export function createMoltbookClient(options = {}) {
  return new MoltbookClient(options);
}

export default MoltbookClient;
