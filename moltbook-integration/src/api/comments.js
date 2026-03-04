/**
 * Comments API Module
 */

import { createRequestClient, handleApiError } from '../utils/request.js';
import { NotFoundError, ValidationError } from '../utils/errors.js';

export class CommentsAPI {
  constructor(requestClient) {
    this.requestClient = requestClient;
  }

  /**
   * Add comment to post
   */
  async addComment(postId, content) {
    if (!postId || !content) {
      throw new ValidationError('Post ID and content are required');
    }

    const response = await this.requestClient.post(
      `/posts/${postId}/comments`,
      { content }
    );

    return response.data.comment;
  }

  /**
   * Reply to comment
   */
  async replyComment(postId, commentId, content) {
    if (!postId || !commentId || !content) {
      throw new ValidationError('Post ID, comment ID, and content are required');
    }

    const response = await this.requestClient.post(
      `/posts/${postId}/comments`,
      {
        content,
        parent_id: commentId
      }
    );

    return response.data.comment;
  }

  /**
   * Get comments for a post
   */
  async getComments(postId, sort = 'top', limit = 25) {
    if (!postId) {
      throw new ValidationError('Post ID is required');
    }

    const response = await this.requestClient.get(
      `/posts/${postId}/comments`,
      {
        params: { sort, limit }
      }
    );

    return response.data.comments;
  }

  /**
   * Get nested comments for a comment
   */
  async getCommentReplies(commentId, sort = 'top', limit = 25) {
    if (!commentId) {
      throw new ValidationError('Comment ID is required');
    }

    const response = await this.requestClient.get(
      `/comments/${commentId}/replies`,
      {
        params: { sort, limit }
      }
    );

    return response.data.comments;
  }

  /**
   * Delete comment
   */
  async deleteComment(commentId) {
    if (!commentId) {
      throw new ValidationError('Comment ID is required');
    }

    const response = await this.requestClient.delete(`/comments/${commentId}`);
    return response.data.success;
  }

  /**
   * Get top comments from a post
   */
  async getTopComments(postId, limit = 10) {
    return this.getComments(postId, 'top', limit);
  }

  /**
   * Get new comments from a post
   */
  async getNewComments(postId, limit = 10) {
    return this.getComments(postId, 'new', limit);
  }

  /**
   * Get controversial comments from a post
   */
  async getControversialComments(postId, limit = 10) {
    return this.getComments(postId, 'controversial', limit);
  }
}
