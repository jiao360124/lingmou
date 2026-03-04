/**
 * Moltbook Client Test
 */

import MoltbookClient from '../src/MoltbookClient.js';
import { config } from '../src/config/index.js';

async function testBasicConnection() {
  console.log('\n=== Test 1: Basic Connection ===');
  try {
    const client = new MoltbookClient({
      apiKey: config.apiKey,
      baseUrl: config.baseUrl
    });

    // Check API health
    const health = await client.healthCheck();
    console.log('Health check:', health.success ? '✅ Success' : '❌ Failed');
    if (health.success) {
      console.log('Agent:', health.agent.name);
      console.log('Karma:', health.agent.karma);
    }

    return health.success;
  } catch (error) {
    console.error('❌ Error:', error.message);
    return false;
  }
}

async function testGetProfile() {
  console.log('\n=== Test 2: Get Agent Profile ===');
  try {
    const client = new MoltbookClient({
      apiKey: config.apiKey,
      baseUrl: config.baseUrl
    });

    const profile = await client.agent.getProfile();
    console.log('✅ Profile retrieved');
    console.log('Name:', profile.name);
    console.log('Karma:', profile.karma);
    console.log('Followers:', profile.follower_count);

    return true;
  } catch (error) {
    console.error('❌ Error:', error.message);
    return false;
  }
}

async function testGetFeed() {
  console.log('\n=== Test 3: Get Feed ===');
  try {
    const client = new MoltbookClient({
      apiKey: config.apiKey,
      baseUrl: config.baseUrl
    });

    const posts = await client.feed.getTrending(5);
    console.log('✅ Feed retrieved');
    console.log('Total posts:', posts.length);

    posts.forEach((post, index) => {
      console.log(`\n${index + 1}. ${post.title}`);
      console.log(`   Submolt: ${post.submolt}`);
      console.log(`   Upvotes: ${post.upvotes}`);
    });

    return true;
  } catch (error) {
    console.error('❌ Error:', error.message);
    return false;
  }
}

async function testCreatePost() {
  console.log('\n=== Test 4: Create Post ===');
  try {
    const client = new MoltbookClient({
      apiKey: config.apiKey,
      baseUrl: config.baseUrl
    });

    const submolt = 'general';
    const title = 'Moltbook Integration Test';
    const content = 'This is a test post created via the Moltbook Integration API.';

    const post = await client.posts.createPost(submolt, title, content);
    console.log('✅ Post created');
    console.log('Post ID:', post.id);
    console.log('Title:', post.title);

    return true;
  } catch (error) {
    console.error('❌ Error:', error.message);
    return false;
  }
}

async function testSearch() {
  console.log('\n=== Test 5: Search ===');
  try {
    const client = new MoltbookClient({
      apiKey: config.apiKey,
      baseUrl: config.baseUrl
    });

    const results = await client.search.search('AI', 'posts', 10);
    console.log('✅ Search completed');
    console.log('Total results:', results.length);

    results.forEach((result, index) => {
      console.log(`\n${index + 1}. ${result.title}`);
      console.log(`   Upvotes: ${result.upvotes}`);
    });

    return true;
  } catch (error) {
    console.error('❌ Error:', error.message);
    return false;
  }
}

async function testCommunityService() {
  console.log('\n=== Test 6: Community Service ===');
  try {
    const client = new MoltbookClient({
      apiKey: config.apiKey,
      baseUrl: config.baseUrl
    });

    const stats = await client.community.getPersonalFeed(5);
    console.log('✅ Community service test');
    console.log('Posts retrieved:', stats.total);
    console.log('First post:', stats.posts[0]?.title);

    return true;
  } catch (error) {
    console.error('❌ Error:', error.message);
    return false;
  }
}

async function testAnalyticsService() {
  console.log('\n=== Test 7: Analytics Service ===');
  try {
    const client = new MoltbookClient({
      apiKey: config.apiKey,
      baseUrl: config.baseUrl
    });

    const activity = await client.analytics.getActivitySummary();
    console.log('✅ Analytics service test');
    console.log('Trending count:', activity.trendingCount);
    console.log('Popular submolts:', activity.popularSubmoltsCount);

    return true;
  } catch (error) {
    console.error('❌ Error:', error.message);
    return false;
  }
}

async function runTests() {
  console.log('🚀 Moltbook Integration Test Suite');
  console.log('===================================');

  const results = [];

  results.push(await testBasicConnection());
  results.push(await testGetProfile());
  results.push(await testGetFeed());
  results.push(await testCreatePost()); // Will create a post, can be cleaned up
  results.push(await testSearch());
  results.push(await testCommunityService());
  results.push(await testAnalyticsService());

  console.log('\n===================================');
  console.log('Test Summary');
  console.log('===================================');

  const passed = results.filter(r => r).length;
  const total = results.length;

  console.log(`Passed: ${passed}/${total}`);

  if (passed === total) {
    console.log('✅ All tests passed!');
  } else {
    console.log('❌ Some tests failed');
  }

  return passed === total;
}

// Run tests
runTests()
  .then(success => {
    process.exit(success ? 0 : 1);
  })
  .catch(error => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
