/**
 * Voting API Module
 */

import { createRequestClient, handleApiError } from '../utils/request.js';
import { NotFoundError, ValidationError } from '../utils/errors.js';

export class VotingAPI {
  constructor(requestClient) {
    this.requestClient = requestClient;
  }

  /**
   * Upvote a post
   */
  async upvotePost(postId) {
    if (!postId) {
      throw new ValidationError('Post ID is required');
    }

    const response = await this.requestClient.post(`/posts/${postId}/upvote`);
    return response.data;
  }

  /**
   * Downvote a post
   */
  async downvotePost(postId) {
    if (!postId) {
      throw new ValidationError('Post ID is required');
    }

    const response = await this.requestClient.post(`/posts/${postId}/downvote`);
    return response.data;
  }

  /**
   * Remove vote from post
   */
  async removeVotePost(postId) {
    if (!postId) {
      throw new ValidationError('Post ID is required');
    }

    const response = await this.requestClient.delete(`/posts/${postId}/vote`);
    return response.data;
  }

  /**
   * Upvote a comment
   */
  async upvoteComment(commentId) {
    if (!commentId) {
      throw new ValidationError('Comment ID is required');
    }

    const response = await this.requestClient.post(`/comments/${commentId}/upvote`);
    return response.data;
  }

  /**
   * Downvote a comment
   */
  async downvoteComment(commentId) {
    if (!commentId) {
      throw new ValidationError('Comment ID is required');
    }

    const response = await this.requestClient.post(`/comments/${commentId}/downvote`);
    return response.data;
  }

  /**
   * Remove vote from comment
   */
  async removeVoteComment(commentId) {
    if (!commentId) {
      throw new ValidationError('Comment ID is required');
    }

    const response = await this.requestClient.delete(`/comments/${commentId}/vote`);
    return response.data;
  }

  /**
   * Get user's votes
   */
  async getMyVotes(type = null, limit = 50) {
    const params = { limit };
    if (type) {
      params.type = type;
    }

    const response = await this.requestClient.get('/votes', { params });
    return response.data.votes;
  }

  /**
   * Get user's voted posts
   */
  async getVotedPosts(limit = 50) {
    return this.getMyVotes('posts', limit);
  }

  /**
   * Get user's voted comments
   */
  async getVotedComments(limit = 50) {
    return this.getMyVotes('comments', limit);
  }
}
