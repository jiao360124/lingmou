/**
 * Learning Service - Handles learning sessions and knowledge management
 */

import { PostsAPI } from '../api/posts.js';
import { CommentsAPI } from '../api/comments.js';
import { SearchAPI } from '../api/search.js';
import { FeedAPI } from '../api/feed.js';
import { uuid } from 'uuid';

export class LearningService {
  constructor(moltbookClient) {
    this.posts = new PostsAPI(moltbookClient.requestClient);
    this.comments = new CommentsAPI(moltbookClient.requestClient);
    this.search = new SearchAPI(moltbookClient.requestClient);
    this.feed = new FeedAPI(moltbookClient.requestClient);

    this.config = moltbookClient.config;
    this.notebooks = new Map();
  }

  /**
   * Auto-discover relevant learning content
   */
  async discoverTopics(interests, limit = 20) {
    try {
      const results = [];

      for (const interest of interests) {
        const posts = await this.search.searchPosts(interest, limit);

        for (const post of posts) {
          results.push({
            type: 'post',
            title: post.title,
            content: post.content,
            submolt: post.submolt,
            author: post.author?.name || 'Unknown',
            upvotes: post.upvotes || 0,
            createdAt: post.created_at
          });
        }
      }

      // Sort by upvotes and return top results
      results.sort((a, b) => b.upvotes - a.upvotes);
      return results.slice(0, limit);
    } catch (error) {
      throw new Error(`Failed to discover topics: ${error.message}`);
    }
  }

  /**
   * Join a learning session (submolt)
   */
  async joinLearningSession(submoltName) {
    try {
      // Subscribe to submolt
      await this.posts.subscribe(submoltName);

      // Create a notebook for this session
      const notebookId = uuid();
      this.notebooks.set(notebookId, {
        submolt: submoltName,
        createdAt: new Date().toISOString(),
        notes: [],
        discussions: []
      });

      return {
        success: true,
        notebookId,
        submolt: submoltName,
        message: `Joined learning session: ${submoltName}`
      };
    } catch (error) {
      throw new Error(`Failed to join learning session: ${error.message}`);
    }
  }

  /**
   * Add a note to a learning session
   */
  async addNote(notebookId, content) {
    if (!this.notebooks.has(notebookId)) {
      throw new Error('Notebook not found');
    }

    const notebook = this.notebooks.get(notebookId);
    const note = {
      id: uuid(),
      content,
      createdAt: new Date().toISOString(),
      timestamp: Date.now()
    };

    notebook.notes.push(note);

    return note;
  }

  /**
   * Record discussion points
   */
  async recordDiscussion(notebookId, postId, comment) {
    if (!this.notebooks.has(notebookId)) {
      throw new Error('Notebook not found');
    }

    const notebook = this.notebooks.get(notebookId);
    const discussion = {
      id: uuid(),
      postId,
      comment,
      createdAt: new Date().toISOString(),
      timestamp: Date.now()
    };

    notebook.discussions.push(discussion);

    return discussion;
  }

  /**
   Get a learning session notebook
   */
  async getNotebook(notebookId) {
    if (!this.notebooks.has(notebookId)) {
      throw new Error('Notebook not found');
    }

    return this.notebooks.get(notebookId);
  }

  /**
   Get all notebooks
   */
  getAllNotebooks() {
    return Array.from(this.notebooks.values());
  }

  /**
   Save current notebooks to disk
   */
  async saveNotebooks(filePath) {
    const data = Array.from(this.notebooks.entries()).map(([id, notebook]) => ({
      id,
      ...notebook
    }));

    const fs = await import('fs/promises');
    await fs.writeFile(filePath, JSON.stringify(data, null, 2));
  }

  /**
   Load notebooks from disk
   */
  async loadNotebooks(filePath) {
    const fs = await import('fs/promises');
    try {
      const data = await fs.readFile(filePath, 'utf8');
      const notebooks = JSON.parse(data);

      notebooks.forEach(notebook => {
        this.notebooks.set(notebook.id, notebook);
      });
    } catch (error) {
      // File doesn't exist, start fresh
      console.log('No existing notebooks found');
    }
  }

  /**
   Get learning progress
   */
  async getLearningProgress(notebookId) {
    const notebook = await this.getNotebook(notebookId);

    return {
      notebookId,
      submolt: notebook.submolt,
      totalNotes: notebook.notes.length,
      totalDiscussions: notebook.discussions.length,
      completionRate: notebook.notes.length > 0
        ? Math.round((notebook.discussions.length / notebook.notes.length) * 100)
        : 0
    };
  }

  /**
   Generate a learning summary
   */
  async generateSummary(notebookId) {
    const notebook = await this.getNotebook(notebookId);

    return {
      notebookId,
      submolt: notebook.submolt,
      notesCount: notebook.notes.length,
      discussionsCount: notebook.discussions.length,
      totalComments: notebook.discussions.reduce((sum, d) => {
        const content = typeof d.comment === 'string' ? d.comment : '';
        return sum + content.split(' ').length;
      }, 0),
      generatedAt: new Date().toISOString()
    };
  }
}
