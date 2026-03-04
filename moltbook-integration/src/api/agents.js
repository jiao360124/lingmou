/**
 * Agent API Module
 */

import { createRequestClient, handleApiError } from '../utils/request.js';
import { NotFoundError, ValidationError } from '../utils/errors.js';

export class AgentAPI {
  constructor(requestClient, config) {
    this.requestClient = requestClient;
    this.config = config;
  }

  /**
   * Get current agent profile
   */
  async getProfile() {
    const response = await this.requestClient.get('/agents/me');

    if (!response.data.agent) {
      throw new NotFoundError('Agent not found');
    }

    return response.data.agent;
  }

  /**
   * Update agent profile
   */
  async updateProfile(updates) {
    if (!updates.description && !updates.name) {
      throw new ValidationError('At least one field to update is required');
    }

    const response = await this.requestClient.patch('/agents/me', updates);
    return response.data.agent;
  }

  /**
   * Get another agent's profile
   */
  async getAgentProfile(agentName) {
    if (!agentName) {
      throw new ValidationError('Agent name is required');
    }

    const response = await this.requestClient.get('/agents/profile', {
      params: { name: agentName }
    });

    return response.data.agent;
  }

  /**
   * Check claim status
   */
  async checkClaimStatus() {
    const response = await this.requestClient.get('/agents/status');
    return response.data;
  }

  /**
   * Get agent statistics
   */
  async getStats() {
    const agent = await this.getProfile();
    return {
      karma: agent.karma,
      posts: agent.stats?.posts || 0,
      comments: agent.stats?.comments || 0,
      followers: agent.follower_count,
      following: agent.following_count
    };
  }

  /**
   * Get owner information
   */
  async getOwner() {
    const agent = await this.getProfile();
    return {
      username: agent.human?.username,
      emailVerified: agent.human?.email_verified,
      xHandle: agent.owner?.x_handle,
      xName: agent.owner?.x_name,
      xVerified: agent.owner?.x_verified,
      xFollowerCount: agent.owner?.x_follower_count
    };
  }

  /**
   * Generate identity token
   */
  async generateIdentityToken(audience = null) {
    const data = {};
    if (audience) {
      data.audience = audience;
    }

    const response = await this.requestClient.post(
      '/agents/me/identity-token',
      data
    );

    return response.data;
  }

  /**
   * Verify identity token (for receiving agents)
   */
  static async verifyIdentity(token, appKey, audience = null) {
    const requestClient = createRequestClient({
      apiKey: appKey
    });

    const data = { token };
    if (audience) {
      data.audience = audience;
    }

    const response = await requestClient.post(
      '/agents/verify-identity',
      data,
      {
        headers: {
          'X-Moltbook-App-Key': appKey
        }
      }
    );

    return response.data;
  }
}
