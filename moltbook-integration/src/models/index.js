/**
 * Data Models for Moltbook Integration
 */

/**
 * Agent Model
 */
export class AgentModel {
  constructor(data) {
    this.id = data.id;
    this.name = data.name;
    this.description = data.description;
    this.karma = data.karma;
    this.avatarUrl = data.avatar_url;
    this.isClaimed = data.is_claimed;
    this.createdAt = data.created_at;
    this.followerCount = data.follower_count;
    this.followingCount = data.following_count;
    this.stats = data.stats || {
      posts: 0,
      comments: 0
    };
    this.owner = data.owner || {
      x_handle: null,
      x_name: null,
      x_avatar: null,
      x_verified: false,
      x_follower_count: 0
    };
    this.human = data.human || {
      username: null,
      email_verified: false
    };
  }

  toJSON() {
    return {
      id: this.id,
      name: this.name,
      description: this.description,
      karma: this.karma,
      avatarUrl: this.avatarUrl,
      isClaimed: this.isClaimed,
      createdAt: this.createdAt,
      followerCount: this.followerCount,
      followingCount: this.followingCount,
      stats: this.stats,
      owner: this.owner,
      human: this.human
    };
  }
}

/**
 * Post Model
 */
export class PostModel {
  constructor(data) {
    this.id = data.id;
    this.submolt = data.submolt;
    this.title = data.title;
    this.content = data.content;
    this.url = data.url;
    this.author = data.author ? {
      id: data.author.id,
      name: data.author.name,
      karma: data.author.karma
    } : null;
    this.upvotes = data.upvotes || 0;
    this.downvotes = data.downvotes || 0;
    this.commentCount = data.comment_count || 0;
    this.createdAt = data.created_at;
    this.updatedAt = data.updated_at;
    this.isEdited = data.is_edited || false;
  }

  get netVotes() {
    return this.upvotes - this.downvotes;
  }

  get karma() {
    return this.netVotes + (this.author?.karma || 0);
  }

  toJSON() {
    return {
      id: this.id,
      submolt: this.submolt,
      title: this.title,
      content: this.content,
      url: this.url,
      author: this.author,
      upvotes: this.upvotes,
      downvotes: this.downvotes,
      commentCount: this.commentCount,
      netVotes: this.netVotes,
      karma: this.karma,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      isEdited: this.isEdited
    };
  }
}

/**
 * Comment Model
 */
export class CommentModel {
  constructor(data) {
    this.id = data.id;
    this.postId = data.post_id;
    this.author = data.author ? {
      id: data.author.id,
      name: data.author.name,
      karma: data.author.karma
    } : null;
    this.content = data.content;
    this.parentId = data.parent_id;
    this.depth = data.depth || 0;
    this.upvotes = data.upvotes || 0;
    this.downvotes = data.downvotes || 0;
    this.createdAt = data.created_at;
    this.updatedAt = data.updated_at;
    this.isEdited = data.is_edited || false;
    this.replies = data.replies || [];
  }

  get netVotes() {
    return this.upvotes - this.downvotes;
  }

  get karma() {
    return this.netVotes + (this.author?.karma || 0);
  }

  toJSON() {
    return {
      id: this.id,
      postId: this.postId,
      author: this.author,
      content: this.content,
      parentId: this.parentId,
      depth: this.depth,
      upvotes: this.upvotes,
      downvotes: this.downvotes,
      netVotes: this.netVotes,
      karma: this.karma,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      isEdited: this.isEdited,
      replies: this.replies
    };
  }
}

/**
 * Submolt Model
 */
export class SubmoltModel {
  constructor(data) {
    this.name = data.name;
    this.displayName = data.display_name;
    this.description = data.description;
    this.memberCount = data.member_count || 0;
    this.postCount = data.post_count || 0;
    this.createdAt = data.created_at;
    this.isSubscribed = data.is_subscribed || false;
  }

  toJSON() {
    return {
      name: this.name,
      displayName: this.displayName,
      description: this.description,
      memberCount: this.memberCount,
      postCount: this.postCount,
      createdAt: this.createdAt,
      isSubscribed: this.isSubscribed
    };
  }
}

/**
 * Identity Token Model
 */
export class IdentityTokenModel {
  constructor(data) {
    this.success = data.success;
    this.identityToken = data.identity_token;
    this.expiresIn = data.expires_in;
    this.expiresAt = data.expires_at;
    this.audience = data.audience;
  }

  get isExpired() {
    return Date.now() > new Date(this.expiresAt).getTime();
  }

  get timeRemaining() {
    const now = Date.now();
    const expires = new Date(this.expiresAt).getTime();
    return expires - now;
  }
}
