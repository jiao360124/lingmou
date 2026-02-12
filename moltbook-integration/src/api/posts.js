/**
 * Posts API Module
 */

import { createRequestClient, handleApiError } from '../utils/request.js';
import { NotFoundError, ValidationError } from '../utils/errors.js';

export class PostsAPI {
  constructor(requestClient) {
    this.requestClient = requestClient;
  }

  /**
   * Create a text post
   */
  async createPost(submolt, title, content) {
    if (!submolt || !title || !content) {
      throw new ValidationError('submolt, title, and content are required');
    }

    const response = await this.requestClient.post('/posts', {
      submolt,
      title,
      content
    });

    return response.data.post;
  }

  /**
   * Create a link post
   */
  async createLinkPost(submolt, title, url) {
    if (!submolt || !title || !url) {
      throw new ValidationError('submolt, title, and url are required');
    }

    const response = await this.requestClient.post('/posts', {
      submolt,
      title,
      url
    });

    return response.data.post;
  }

  /**
   * Get feed with sorting
   */
  async getFeed(sort = 'hot', limit = 25) {
    const response = await this.requestClient.get('/posts', {
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
   * Get single post
   */
  async getPost(postId) {
    if (!postId) {
      throw new ValidationError('Post ID is required');
    }

    const response = await this.requestClient.get(`/posts/${postId}`);

    if (!response.data.post) {
      throw new NotFoundError('Post not found');
    }

    return response.data.post;
  }

  /**
   * Delete post
   */
  async deletePost(postId) {
    if (!postId) {
      throw new ValidationError('Post ID is required');
    }

    const response = await this.requestClient.delete(`/posts/${postId}`);
    return response.data.success;
  }

  /**
   * Get posts by agent
   */
  async getAgentPosts(agentName, limit = 25) {
    const response = await this.requestClient.get('/posts', {
      params: { agent_name: agentName, limit }
    });

    return response.data.posts;
  }

  /**
   * Get posts by submolt
   */
  async getSubmoltPosts(submoltName, sort = 'hot', limit = 25) {
    const response = await this.requestClient.get('/posts', {
      params: { submolt: submoltName, sort, limit }
    });

    return response.data.posts;
  }

  /**
   * Get posts from followed agents
   */
  async getFollowedPosts(limit = 25) {
    const response = await this.requestClient.get('/feed', {
      params: { sort: 'hot', limit }
    });

    return response.data.posts;
  }
}
