/**
 * Search API Module
 */

import { createRequestClient, handleApiError } from '../utils/request.js';
import { ValidationError } from '../utils/errors.js';

export class SearchAPI {
  constructor(requestClient) {
    this.requestClient = requestClient;
  }

  /**
   * Search posts
   */
  async searchPosts(query, limit = 25) {
    if (!query) {
      throw new ValidationError('Search query is required');
    }

    const response = await this.requestClient.get('/search', {
      params: {
        q: query,
        type: 'posts',
        limit
      }
    });

    return response.data.results;
  }

  /**
   * Search agents
   */
  async searchAgents(query, limit = 25) {
    if (!query) {
      throw new ValidationError('Search query is required');
    }

    const response = await this.requestClient.get('/search', {
      params: {
        q: query,
        type: 'agents',
        limit
      }
    });

    return response.data.results;
  }

  /**
   * Search submolts
   */
  async searchSubmolts(query, limit = 25) {
    if (!query) {
      throw new ValidationError('Search query is required');
    }

    const response = await this.requestClient.get('/search', {
      params: {
        q: query,
        type: 'submolts',
        limit
      }
    });

    return response.data.results;
  }

  /**
   * Broad search (all types)
   */
  async search(query, type = null, limit = 25) {
    if (!query) {
      throw new ValidationError('Search query is required');
    }

    const params = { q: query, limit };
    if (type) {
      params.type = type;
    }

    const response = await this.requestClient.get('/search', { params });

    return {
      posts: response.data.posts || [],
      agents: response.data.agents || [],
      submolts: response.data.submolts || [],
      results: response.data.results || []
    };
  }

  /**
   * Search trending topics
   */
  async searchTrending(limit = 25) {
    const response = await this.requestClient.get('/search/trending', {
      params: { limit }
    });

    return response.data.topics;
  }

  /**
   * Search similar to a post
   */
  async searchSimilar(postId, limit = 25) {
    if (!postId) {
      throw new ValidationError('Post ID is required');
    }

    const response = await this.requestClient.get(`/posts/${postId}/similar`, {
      params: { limit }
    });

    return response.data.posts;
  }

  /**
   * Get autocomplete suggestions
   */
  async getAutocomplete(query, limit = 10) {
    if (!query) {
      throw new ValidationError('Query is required');
    }

    const response = await this.requestClient.get('/search/autocomplete', {
      params: { q: query, limit }
    });

    return response.data.suggestions;
  }
}
