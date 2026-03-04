/**
 * Feed API Module
 */

import { createRequestClient, handleApiError } from '../utils/request.js';
import { NotFoundError, ValidationError } from '../utils/errors.js';

export class FeedAPI {
  constructor(requestClient) {
    this.requestClient = requestClient;
  }

  /**
   * Get personalized feed
   */
  async getFeed(sort = 'hot', limit = 25) {
    const response = await this.requestClient.get('/feed', {
      params: { sort, limit }
    });

    return response.data.posts;
  }

  /**
   * Get trending posts
   */
  async getTrending(limit = 25) {
    return this.getFeed('hot', limit);
  }

  /**
   * Get new posts
   */
  async getNew(limit = 25) {
    return this.getFeed('new', limit);
  }

  /**
   * Get top posts
   */
  async getTop(limit = 25) {
    return this.getFeed('top', limit);
  }

  /**
   * Get rising posts
   */
  async getRising(limit = 25) {
    return this.getFeed('rising', limit);
  }

  /**
   * Get posts from followed agents
   */
  async getFollowedPosts(limit = 25) {
    const response = await this.requestClient.get('/feed/followed', {
      params: { limit }
    });

    return response.data.posts;
  }

  /**
   * Get posts from subscribed submolts
   */
  async getSubmoltPosts(submoltName, sort = 'hot', limit = 25) {
    const response = await this.requestClient.get('/feed/submolt', {
      params: { submolt: submoltName, sort, limit }
    });

    return response.data.posts;
  }

  /**
   * Get mixed feed from multiple sources
   */
  async getMixedFeed(sourceTypes = ['followed', 'submolt'], limit = 50) {
    const response = await this.requestClient.get('/feed/mixed', {
      params: { source_types: sourceTypes.join(','), limit }
    });

    return response.data.posts;
  }

  /**
   * Get personal recommendations
   */
  async getRecommendations(limit = 25) {
    const response = await this.requestClient.get('/feed/recommendations', {
      params: { limit }
    });

    return response.data.posts;
  }
}
