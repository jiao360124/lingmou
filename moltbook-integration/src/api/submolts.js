/**
 * Submolts (Communities) API Module
 */

import { createRequestClient, handleApiError } from '../utils/request.js';
import { NotFoundError, ValidationError } from '../utils/errors.js';

export class SubmoltsAPI {
  constructor(requestClient) {
    this.requestClient = requestClient;
  }

  /**
   * Get all submolts
   */
  async listSubmolts() {
    const response = await this.requestClient.get('/submolts');
    return response.data.submolts;
  }

  /**
   * Get submolt information
   */
  async getSubmolt(submoltName) {
    if (!submoltName) {
      throw new ValidationError('Submolt name is required');
    }

    const response = await this.requestClient.get(`/submolts/${submoltName}`);

    if (!response.data.submolt) {
      throw new NotFoundError('Submolt not found');
    }

    return response.data.submolt;
  }

  /**
   * Create new submolt
   */
  async createSubmolt(name, displayName, description) {
    if (!name || !displayName || !description) {
      throw new ValidationError('name, displayName, and description are required');
    }

    const response = await this.requestClient.post('/submolts', {
      name,
      display_name: displayName,
      description
    });

    return response.data.submolt;
  }

  /**
   * Subscribe to submolt
   */
  async subscribe(submoltName) {
    if (!submoltName) {
      throw new ValidationError('Submolt name is required');
    }

    const response = await this.requestClient.post(`/submolts/${submoltName}/subscribe`);
    return response.data.success;
  }

  /**
   * Unsubscribe from submolt
   */
  async unsubscribe(submoltName) {
    if (!submoltName) {
      throw new ValidationError('Submolt name is required');
    }

    const response = await this.requestClient.delete(`/submolts/${submoltName}/subscribe`);
    return response.data.success;
  }

  /**
   * Get subscription status
   */
  async getSubscription(submoltName) {
    if (!submoltName) {
      throw new ValidationError('Submolt name is required');
    }

    const response = await this.requestClient.get(`/submolts/${submoltName}/subscription`);
    return response.data;
  }

  /**
   * List subscribed submolts
   */
  async getSubscriptions() {
    const response = await this.requestClient.get('/submolts/subscribed');
    return response.data.submolts;
  }

  /**
   * Get popular submolts
   */
  async getPopular(limit = 20) {
    const response = await this.requestClient.get('/submolts', {
      params: { sort: 'popular', limit }
    });

    return response.data.submolts;
  }

  /**
   * Get recommended submolts
   */
  async getRecommended(limit = 20) {
    const response = await this.requestClient.get('/submolts', {
      params: { sort: 'recommended', limit }
    });

    return response.data.submolts;
  }
}
