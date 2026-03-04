/**
 * Moltbook Integration - Quick Tool
 * 使用示例: node moltbook-tool.js [command] [options]
 *
 * Commands:
 *   test          - Run tests
 *   profile       - Get agent profile
 *   feed          - Get trending feed
 *   post          - Create a post
 *   search        - Search content
 *   stats         - Get community stats
 */

import MoltbookClient from './src/MoltbookClient.js';
import { config, validateConfig } from './src/config/index.js';

async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.log('Usage: node moltbook-tool.js <command> [options]');
    console.log('\nCommands:');
    console.log('  test          - Run tests');
    console.log('  profile       - Get agent profile');
    console.log('  feed          - Get trending feed');
    console.log('  post          - Create a post');
    console.log('  search        - Search content');
    console.log('  stats         - Get community stats');
    process.exit(1);
  }

  const command = args[0];

  try {
    // Validate config
    validateConfig();

    // Create client
    const client = new MoltbookClient({
      apiKey: config.apiKey,
      baseUrl: config.baseUrl
    });

    switch (command) {
      case 'test':
        await runTests(client);
        break;
      case 'profile':
        await getProfile(client);
        break;
      case 'feed':
        await getFeed(client);
        break;
      case 'post':
        await createPost(client);
        break;
      case 'search':
        await searchContent(client);
        break;
      case 'stats':
        await getStats(client);
        break;
      default:
        console.error(`Unknown command: ${command}`);
        process.exit(1);
    }
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

async function runTests(client) {
  console.log('🚀 Running tests...\n');

  const tests = [
    { name: 'Health Check', fn: () => client.healthCheck() },
    { name: 'Get Profile', fn: () => client.agent.getProfile() },
    { name: 'Get Feed', fn: () => client.feed.getTrending(5) }
  ];

  let passed = 0;
  let failed = 0;

  for (const test of tests) {
    try {
      await test.fn();
      console.log(`✅ ${test.name}`);
      passed++;
    } catch (error) {
      console.error(`❌ ${test.name}: ${error.message}`);
      failed++;
    }
  }

  console.log(`\nPassed: ${passed}/${tests.length}`);
}

async function getProfile(client) {
  console.log('👤 Getting agent profile...\n');

  const profile = await client.agent.getProfile();

  console.log('Name:', profile.name);
  console.log('Description:', profile.description || 'N/A');
  console.log('Karma:', profile.karma);
  console.log('Followers:', profile.follower_count);
  console.log('Following:', profile.following_count);
  console.log('Total Posts:', profile.stats?.posts || 0);
  console.log('Total Comments:', profile.stats?.comments || 0);
  console.log('Twitter:', profile.owner?.x_name || 'N/A');
}

async function getFeed(client) {
  console.log('📰 Getting trending feed...\n');

  const posts = await client.feed.getTrending(10);

  console.log(`Found ${posts.length} trending posts:\n`);

  posts.forEach((post, i) => {
    console.log(`${i + 1}. ${post.title}`);
    console.log(`   Submolt: ${post.submolt}`);
    console.log(`   Upvotes: ${post.upvotes}`);
    console.log(`   Comments: ${post.comment_count}`);
    console.log('');
  });
}

async function createPost(client) {
  const title = process.argv[3] || 'Test Post';
  const content = process.argv[4] || 'This is a test post created via the Moltbook Integration API.';

  console.log('✍️  Creating post...\n');

  const post = await client.posts.createPost('general', title, content);

  console.log('✅ Post created successfully!');
  console.log('ID:', post.id);
  console.log('Submolt:', post.submolt);
  console.log('Title:', post.title);
}

async function searchContent(client) {
  const query = process.argv[3] || 'AI';

  console.log(`🔍 Searching for "${query}"...\n`);

  const results = await client.search.search(query, 'posts', 10);

  console.log(`Found ${results.length} results:\n`);

  results.forEach((post, i) => {
    console.log(`${i + 1}. ${post.title}`);
    console.log(`   Upvotes: ${post.upvotes}`);
    console.log('---');
  });
}

async function getStats(client) {
  console.log('📊 Getting community stats...\n');

  const health = await client.healthCheck();
  console.log('API Status:', health.success ? '✅ OK' : '❌ Failed');

  if (health.success) {
    const activity = await client.analytics.getActivitySummary();
    console.log(`Trending: ${activity.trendingCount} posts`);
    console.log(`Popular Submolts: ${activity.popularSubmoltsCount}`);
    console.log(`Top Post: ${activity.topTrendingPost?.title || 'N/A'}`);
  }
}

// Run main function
main().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});
