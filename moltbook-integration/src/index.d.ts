/**
 * TypeScript Type Definitions for Moltbook Integration
 */

// Main Client
export class MoltbookClient {
  constructor(options: MoltbookClientOptions);
  get agent(): AgentAPI;
  get posts(): PostsAPI;
  get comments(): CommentsAPI;
  get submolts(): SubmoltsAPI;
  get feed(): FeedAPI;
  get search(): SearchAPI;
  get voting(): VotingAPI;
  get community(): CommunityService;
  get learning(): LearningService;
  get analytics(): AnalyticsService;

  getConfig(): MoltbookClientOptions;
  getRequestClient(): RequestClient;
  healthCheck(): Promise<HealthCheckResult>;
  generateIdentityToken(audience?: string): Promise<IdentityTokenModel>;
}

export interface MoltbookClientOptions {
  apiKey: string;
  baseUrl?: string;
  timeout?: number;
  maxRetries?: number;
  logLevel?: 'debug' | 'info' | 'warn' | 'error';
  cacheEnabled?: boolean;
  cacheTTL?: number;
}

export interface HealthCheckResult {
  success: boolean;
  agent?: AgentProfile;
  error?: string;
  timestamp: string;
}

// Models
export class AgentModel {
  constructor(data: AgentProfile);
  toJSON(): AgentProfile;
}

export class PostModel {
  constructor(data: Post);
  toJSON(): Post;
}

export class CommentModel {
  constructor(data: Comment);
  toJSON(): Comment;
}

export class SubmoltModel {
  constructor(data: Submolt);
  toJSON(): Submolt;
}

export class IdentityTokenModel {
  constructor(data: IdentityToken);
  get isExpired(): boolean;
  get timeRemaining(): number;
}

// Configuration
export interface MoltbookConfig {
  apiKey: string;
  baseUrl: string;
  rateLimit: number;
  rateWindow: number;
  timeout: number;
  maxRetries: number;
  retryDelay: number;
  cacheTTL: number;
  cacheEnabled: boolean;
  logLevel: string;
  domain: string;
}

export interface AgentProfile {
  id: string;
  name: string;
  description: string;
  karma: number;
  avatar_url: string;
  is_claimed: boolean;
  created_at: string;
  follower_count: number;
  following_count: number;
  stats?: {
    posts: number;
    comments: number;
  };
  owner?: {
    x_handle: string;
    x_name: string;
    x_avatar: string;
    x_verified: boolean;
    x_follower_count: number;
  };
  human?: {
    username: string;
    email_verified: boolean;
  };
}

export interface IdentityToken {
  success: boolean;
  identity_token: string;
  expires_in: number;
  expires_at: string;
  audience: string;
}
