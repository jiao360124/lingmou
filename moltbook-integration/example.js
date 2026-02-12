/**
 * Moltbook Integration - Quick Example
 * 简单的使用示例
 */

import MoltbookClient from './src/MoltbookClient.js';

async function main() {
  console.log('🚀 Moltbook Integration - Quick Example\n');

  try {
    // 1. 创建客户端
    console.log('1️⃣  Creating Moltbook client...');
    const client = new MoltbookClient({
      apiKey: process.env.MOLTBOOK_API_KEY
    });
    console.log('   ✅ Client created\n');

    // 2. 检查连接
    console.log('2️⃣  Checking connection...');
    const health = await client.healthCheck();
    if (health.success) {
      console.log(`   ✅ Connected as ${health.agent.name}`);
      console.log(`   Karma: ${health.agent.karma}`);
      console.log(`   Followers: ${health.agent.follower_count}\n`);
    }

    // 3. 获取Profile
    console.log('3️⃣  Getting profile...');
    const profile = await client.agent.getProfile();
    console.log(`   Name: ${profile.name}`);
    console.log(`   Karma: ${profile.karma}`);
    console.log(`   Posts: ${profile.stats?.posts || 0}`);
    console.log(`   Comments: ${profile.stats?.comments || 0}\n`);

    // 4. 获取热门帖子
    console.log('4️⃣  Getting trending posts...');
    const posts = await client.feed.getTrending(5);
    console.log(`   Found ${posts.length} trending posts:\n`);

    posts.forEach((post, i) => {
      console.log(`   ${i + 1}. ${post.title}`);
      console.log(`      ${post.upvotes} upvotes | ${post.comment_count} comments\n`);
    });

    // 5. 社区互动
    console.log('5️⃣  Getting community stats...');
    const activity = await client.analytics.getActivitySummary();
    console.log(`   Trending: ${activity.trendingCount} posts`);
    console.log(`   Popular submolts: ${activity.popularSubmoltsCount}\n`);

    // 6. 获取热门话题
    console.log('6️⃣  Getting trending topics...');
    const topics = await client.analytics.analyzeTrendingTopics(10);
    console.log(`   Top keywords:\n`);
    topics.topKeywords.forEach(([keyword, count], i) => {
      console.log(`   ${i + 1}. ${keyword} (${count})`);
    });

    console.log('\n✅ All operations completed successfully!');

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    process.exit(1);
  }
}

main().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});
