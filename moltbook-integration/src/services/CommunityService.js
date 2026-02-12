/**
 * Community Service - Handles community interactions
 */

import { AgentAPI } from '../api/agents.js';
import { PostsAPI } from '../api/posts.js';
import { CommentsAPI } from '../api/comments.js';
import { SubmoltsAPI } from '../api/submolts.js';
import { FeedAPI } from '../api/feed.js';
import { SearchAPI } from '../api/search.js';

export class CommunityService {
  constructor(moltbookClient) {
    this.agent = new AgentAPI(moltbookClient.requestClient, moltbookClient.config);
    this.posts = new PostsAPI(moltbookClient.requestClient);
    this.comments = new CommentsAPI(moltbookClient.requestClient);
    this.submolts = new SubmoltsAPI(moltbookClient.requestClient);
    this.feed = new FeedAPI(moltbookClient.requestClient);
    this.search = new SearchAPI(moltbookClient.requestClient);
    this.voting = new VotingAPI(moltbookClient.requestClient);

    this.config = moltbookClient.config;
  }

  /**
   * Post content to a submolt
   */
  async postContent(submolt, title, content, isLink = false, url = null) {
    try {
      let post;

      if (isLink && url) {
        post = await this.posts.createLinkPost(submolt, title, url);
      } else {
        post = await this.posts.createPost(submolt, title, content);
      }

      return {
        success: true,
        post,
        message: 'Content posted successfully'
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        message: 'Failed to post content'
      };
    }
  }

  /**
   * Reply to a post
   */
  async replyToPost(postId, content) {
    try {
      const comment = await this.comments.addComment(postId, content);

      return {
        success: true,
        comment,
        message: 'Reply posted successfully'
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        message: 'Failed to post reply'
      };
    }
  }

  /**
   * Reply to a comment
   */
  async replyToComment(postId, commentId, content) {
    try {
      const reply = await this.comments.replyComment(postId, commentId, content);

      return {
        success: true,
        reply,
        message: 'Reply posted successfully'
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        message: 'Failed to post reply'
      };
    }
  }

  /**
   * Follow an agent
   */
  async followAgent(agentName) {
    try {
      const response = await this.agent.followAgent(agentName);

      return {
        success: true,
        message: `Following ${agentName} successfully`
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        message: 'Failed to follow agent'
      };
    }
  }

  /**
   * Unfollow an agent
   */
  async unfollowAgent(agentName) {
    try {
      await this.agent.unfollowAgent(agentName);

      return {
        success: true,
        message: `Unfollowed ${agentName} successfully`
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        message: 'Failed to unfollow agent'
      };
    }
  }

  /**
   * Subscribe to submolt
   */
  async subscribeSubmolt(submoltName) {
    try {
      await this.submolts.subscribe(submoltName);

      return {
        success: true,
        message: `Subscribed to ${submoltName} successfully`
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        message: 'Failed to subscribe to submolt'
      };
    }
  }

  /**
   * Unsubscribe from submolt
   */
  async unsubscribeSubmolt(submoltName) {
    try {
      await this.submolts.unsubscribe(submoltName);

      return {
        success: true,
        message: `Unsubscribed from ${submoltName} successfully`
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        message: 'Failed to unsubscribe from submolt'
      };
    }
  }

  /**
   * Like/Upvote a post
   */
  async likePost(postId) {
    try {
      await this.voting.upvotePost(postId);

      return {
        success: true,
        message: 'Post liked successfully'
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        message: 'Failed to like post'
      };
    }
  }

  /**
   * Dislike/Downvote a post
   */
  async dislikePost(postId) {
    try {
      await this.voting.downvotePost(postId);

      return {
        success: true,
        message: 'Post disliked successfully'
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        message: 'Failed to dislike post'
      };
    }
  }

  /**
   * Get personalized feed
   */
  async getPersonalFeed(sort = 'hot', limit = 25) {
    try {
      const posts = await this.feed.getFeed(sort, limit);

      return {
        success: true,
        posts,
        total: posts.length
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        posts: [],
        total: 0
      };
    }
  }

  /**
   * Search and discover content
   */
  async discoverContent(query, limit = 25) {
    try {
      const results = await this.search.search(query, 'posts', limit);

      return {
        success: true,
        posts: results,
        total: results.length
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        posts: [],
        total: 0
      };
    }
  }
}
