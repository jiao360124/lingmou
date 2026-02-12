/**
 * Analytics Service - Community content analysis and insights
 */

import { SearchAPI } from '../api/search.js';
import { FeedAPI } from '../api/feed.js';
import { SubmoltsAPI } from '../api/submolts.js';

export class AnalyticsService {
  constructor(moltbookClient) {
    this.search = new SearchAPI(moltbookClient.requestClient);
    this.feed = new FeedAPI(moltbookClient.requestClient);
    this.submolts = new SubmoltsAPI(moltbookClient.requestClient);

    this.config = moltbookClient.config;
  }

  /**
   Analyze trending topics
   */
  async analyzeTrendingTopics(limit = 20) {
    try {
      const trending = await this.search.searchTrending(limit);

      // Extract top keywords
      const keywordCounts = {};
      trending.forEach(topic => {
        const keywords = topic.toLowerCase().split(/\s+/).filter(w => w.length > 3);
        keywords.forEach(keyword => {
          keywordCounts[keyword] = (keywordCounts[keyword] || 0) + 1;
        });
      });

      // Sort by frequency
      const sortedKeywords = Object.entries(keywordCounts)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 10);

      return {
        success: true,
        trendingTopics: trending,
        topKeywords: sortedKeywords,
        count: trending.length
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        trendingTopics: [],
        topKeywords: [],
        count: 0
      };
    }
  }

  /**
   Analyze popular submolts
   */
  async analyzePopularSubmolts(limit = 20) {
    try {
      const popular = await this.submolts.getPopular(limit);

      // Calculate engagement metrics
      const analyzed = popular.map(submolt => ({
        ...submolt,
        memberCount: submolt.member_count || 0,
        postCount: submolt.post_count || 0
      }));

      return {
        success: true,
        popularSubmolts: analyzed,
        count: analyzed.length
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        popularSubmolts: [],
        count: 0
      };
    }
  }

  Analyze community engagement
   */
  async analyzeEngagement(limit = 100) {
    try {
      const feed = await this.feed.getTrending(limit);
      const comments = await this.feed.getNew(50);

      const totalPosts = feed.length;
      const totalComments = comments.length;

      // Calculate average engagement
      const avgEngagement = totalPosts > 0
        ? totalComments / totalPosts
        : 0;

      // Count by submolt
      const submoltCounts = {};
      feed.forEach(post => {
        const submolt = post.submolt;
        submoltCounts[submolt] = (submoltCounts[submolt] || 0) + 1;
      });

      const topSubmolts = Object.entries(submoltCounts)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 10);

      return {
        success: true,
        totalPosts,
        totalComments,
        avgEngagement: avgEngagement.toFixed(2),
        topSubmolts,
        count: totalPosts
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        totalPosts: 0,
        totalComments: 0,
        avgEngagement: '0.00',
        topSubmolts: [],
        count: 0
      };
    }
  }

  /**
   Extract learning insights from community content
   */
  async extractLearningInsights(interests = [], limit = 50) {
    try {
      const insights = {
        popularTopics: [],
        keyPrinciples: [],
        commonPatterns: [],
        recommendedResources: []
      };

      // Search for posts about interests
      for (const interest of interests) {
        const results = await this.search.searchPosts(interest, limit);

        // Extract titles as popular topics
        results.forEach(post => {
          insights.popularTopics.push({
            topic: post.title,
            submolt: post.submolt,
            upvotes: post.upvotes || 0
          });
        });
      }

      // Sort topics by upvotes
      insights.popularTopics.sort((a, b) => b.upvotes - a.upvotes);
      insights.popularTopics = insights.popularTopics.slice(0, 20);

      return {
        success: true,
        insights,
        count: insights.popularTopics.length
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        insights: {
          popularTopics: [],
          keyPrinciples: [],
          commonPatterns: [],
          recommendedResources: []
        },
        count: 0
      };
    }
  }

  /**
   Get community activity summary
   */
  async getActivitySummary() {
    try {
      const trending = await this.feed.getTrending(25);
      const popular = await this.submolts.getPopular(15);

      return {
        success: true,
        trendingCount: trending.length,
        popularSubmoltsCount: popular.length,
        topTrendingPost: trending[0],
        topSubmolt: popular[0],
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        trendingCount: 0,
        popularSubmoltsCount: 0,
        topTrendingPost: null,
        topSubmolt: null,
        timestamp: new Date().toISOString()
      };
    }
  }

  /**
   Compare engagement across submolts
   */
  async compareSubmoltEngagement(submoltNames = [], limit = 100) {
    if (!submoltNames || submoltNames.length === 0) {
      try {
        const popular = await this.submolts.getPopular(10);
        submoltNames = popular.map(s => s.name);
      } catch (error) {
        return {
          success: false,
          error: error.message,
          comparisons: []
        };
      }
    }

    const comparisons = [];

    for (const submoltName of submoltNames) {
      try {
        const posts = await this.feed.getSubmoltPosts(submoltName, 'hot', limit);
        const upvotes = posts.reduce((sum, post) => sum + (post.upvotes || 0), 0);

        comparisons.push({
          submolt: submoltName,
          postCount: posts.length,
          totalUpvotes: upvotes,
          avgUpvotes: posts.length > 0 ? upvotes / posts.length : 0
        });
      } catch (error) {
        console.error(`Failed to analyze ${submoltName}:`, error.message);
      }
    }

    // Sort by engagement
    comparisons.sort((a, b) => b.avgUpvotes - a.avgUpvotes);

    return {
      success: true,
      comparisons,
      count: comparisons.length
    };
  }
}
