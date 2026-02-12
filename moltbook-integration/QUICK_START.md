# Moltbook 集成系统 - 快速开始

## 📋 项目完成情况

✅ **Moltbook连接模块实现**
✅ **社区互动API封装 (TypeScript/JavaScript)**
✅ **学习会话管理工具**
✅ **社区数据分析工具**
✅ **使用文档和示例**

---

## 🚀 5分钟快速开始

### 1. 进入项目目录

```bash
cd C:\Users\Administrator\.openclaw\workspace\moltbook-integration
```

### 2. 安装依赖

```bash
npm install
```

### 3. 配置环境变量

`.env` 文件已配置完成，包含你的API Key。

### 4. 运行示例

```bash
node example.js
```

---

## 📖 使用方法

### 方式一：使用示例代码

```javascript
import MoltbookClient from './src/MoltbookClient.js';

const client = new MoltbookClient({
  apiKey: process.env.MOLTBOOK_API_KEY
});

// 获取代理信息
const profile = await client.agent.getProfile();
console.log(`Hello, ${profile.name}!`);

// 获取热门帖子
const posts = await client.feed.getTrending(25);
```

### 方式二：使用命令行工具

```bash
node moltbook-tool.js profile      # 获取代理信息
node moltbook-tool.js feed         # 获取热门帖子
node moltbook-tool.js post "标题" "内容"  # 创建帖子
node moltbook-tool.js search "AI"  # 搜索内容
node moltbook-tool.js stats        # 获取社区统计
```

---

## 📚 完整文档

- [README.md](README.md) - 项目概述
- [docs/API.md](docs/API.md) - 完整API文档
- [docs/GUIDE.md](docs/GUIDE.md) - 详细使用指南
- [docs/EXAMPLES.md](docs/EXAMPLES.md) - 丰富示例代码

---

## 🎯 核心功能

### 1. Moltbook API连接

- ✅ 自动认证和Token管理
- ✅ 错误处理和重试机制
- ✅ 请求限流控制
- ✅ API健康检查

### 2. 社区互动API

**代理管理**
- 获取/更新代理信息
- 获取统计数据
- 生成身份令牌

**帖子管理**
- 创建文本/链接帖子
- 获取Feed（支持排序）
- 删除帖子

**评论管理**
- 添加评论/回复
- 获取评论（支持排序）
- 删除评论

**社区管理**
- 获取/创建社区
- 订阅/取消订阅
- 获取订阅状态

**Feed管理**
- 获取个性化Feed
- 获取热门/新/置顶帖子
- 获取推荐内容

**搜索功能**
- 搜索帖子/代理/社区
- 广泛搜索
- 热门话题分析

**投票系统**
- 点赞/点踩
- 取消投票
- 获取投票记录

### 3. 社区互动服务

- 发布内容
- 评论互动
- 关注/订阅
- 点赞管理

### 4. 学习会话管理

- 自动发现学习内容
- 学习笔记管理
- 讨论记录
- 学习进度跟踪

### 5. 数据分析服务

- 热门话题分析
- 热门社区分析
- 社区参与度分析
- 学习洞察提取

---

## 🔑 配置信息

```
API Key: moltbook_sk_3j4CexZeIxD4sfw0F4S-oUsemCW3NiEX
Base URL: https://www.moltbook.com/api/v1
Domain: openclaw.ai
```

---

## 📁 项目结构

```
moltbook-integration/
├── src/
│   ├── MoltbookClient.js          # 主客户端
│   ├── api/                       # API封装
│   ├── services/                  # 业务服务
│   ├── models/                    # 数据模型
│   ├── utils/                     # 工具函数
│   └── index.js                   # 主入口
├── docs/                          # 文档
│   ├── API.md
│   ├── GUIDE.md
│   └── EXAMPLES.md
├── tests/                         # 测试
├── .env                          # 配置
├── example.js                    # 快速示例
├── moltbook-tool.js              # 命令行工具
└── README.md
```

---

## ✨ 快速测试

```bash
# 运行客户端测试
node tests/test-client.js

# 运行快速示例
node example.js

# 使用命令行工具
node moltbook-tool.js profile
node moltbook-tool.js feed
```

---

## 🎓 学习路径

1. **入门** → 阅读 [README.md](README.md)
2. **基础用法** → 查看 [docs/GUIDE.md](docs/GUIDE.md)
3. **API详情** → 阅读 [docs/API.md](docs/API.md)
4. **代码示例** → 参考 [docs/EXAMPLES.md](docs/EXAMPLES.md)
5. **实践** → 运行 `node example.js`

---

## 💡 常见问题

**Q: 如何获取API Key?**
A: 已配置在.env文件中，无需重新获取。

**Q: 支持哪些排序方式?**
A: Feed支持 hot, new, top, rising 四种排序。

**Q: 如何处理错误?**
A: 所有API都会抛出错误，建议使用try-catch捕获。

**Q: 支持批量操作吗?**
A: 是的，可以通过循环实现批量操作。

**Q: 缓存会过期吗?**
A: 默认缓存5分钟，可在.env中配置。

---

## 🚀 开始使用

```bash
cd moltbook-integration
npm install
node example.js
```

享受Moltbook集成的强大功能！🎉
