# RAG - 知识库结构优化设计

## 概述
优化的知识库结构提供更好的组织、检索、管理和更新能力。

## 知识库架构

### 整体架构

```
knowledge/
├── index.json                 # 索引文件
├── metadata/                  # 元数据管理
│   ├── document-metadata.json
│   ├── category-metadata.json
│   └── tag-metadata.json
├── knowledge-graph/           # 知识图谱
│   ├── graph.json
│   ├── entities.json
│   └── relations.json
├── documents/                 # 文档存储
│   ├── guides/               # 指南文档
│   │   ├── getting-started/
│   │   ├── tutorials/
│   │   └── how-to/
│   ├── documentation/        # 技术文档
│   │   ├── api-reference/
│   │   ├── architecture/
│   │   └── specifications/
│   ├── faqs/                 # 常见问题
│   │   ├── general/
│   │   ├── technical/
│   │   └── troubleshooting/
│   ├── examples/             # 示例代码
│   │   ├── guides/
│   │   ├── templates/
│   │   └── snippets/
│   ├── best-practices/       # 最佳实践
│   │   ├── coding/
│   │   ├── architecture/
│   │   └── security/
│   ├── policies/             # 政策文档
│   │   ├── guidelines/
│   │   └── standards/
│   └── versions/             # 版本控制
│       ├── v1.0/
│       ├── v2.0/
│       └── current/
├── resources/                # 外部资源
│   ├── links.json
│   ├── references.json
│   └── external-docs/
└── cache/                    # 检索缓存
    ├── vector-cache/
    └── search-cache/
```

## 元数据系统

### 文档元数据
```json
{
  "document_id": "doc_001",
  "title": "React Hooks最佳实践",
  "content": "# React Hooks最佳实践\n...",
  "category": "guides",
  "subcategory": "tutorials",
  "tags": ["react", "hooks", "best-practices"],
  "version": "1.0",
  "last_updated": "2024-01-15T10:00:00Z",
  "created_at": "2024-01-10T10:00:00Z",
  "author": "张三",
  "author_id": "user_001",
  "language": "zh-CN",
  "license": "MIT",
  "external_links": [
    {
      "url": "https://react.dev/reference/react",
      "type": "official-documentation"
    }
  ],
  "related_documents": ["doc_002", "doc_003"],
  "review_status": "approved",
  "reviewer_id": "user_002",
  "review_date": "2024-01-16T10:00:00Z"
}
```

### 分类元数据
```json
{
  "category_id": "cat_001",
  "name": "guides",
  "display_name": "指南",
  "description": "提供详细的使用指南和教程",
  "path": "/guides",
  "order": 1,
  "parent": null,
  "children": [
    {
      "category_id": "cat_002",
      "name": "getting-started",
      "display_name": "入门指南",
      "order": 1
    },
    {
      "category_id": "cat_003",
      "name": "tutorials",
      "display_name": "教程",
      "order": 2
    }
  ],
  "document_count": 45,
  "last_updated": "2024-01-15T10:00:00Z",
  "metadata": {
    "visible": true,
    "featured": false,
    "searchable": true
  }
}
```

### 标签系统
```json
{
  "tag_id": "tag_001",
  "name": "react",
  "display_name": "React",
  "description": "React相关技术",
  "category": "frameworks",
  "document_count": 120,
  "frequency": "high",
  "aliases": ["reactjs", "reactjs.org"],
  "metadata": {
    "visible": true,
    "trending": true
  }
}
```

## 知识图谱

### 知识图谱结构
```json
{
  "graph": {
    "nodes": [
      {
        "id": "node_001",
        "type": "document",
        "label": "React Hooks最佳实践",
        "properties": {
          "category": "guides",
          "tags": ["react", "hooks", "best-practices"]
        }
      },
      {
        "id": "node_002",
        "type": "concept",
        "label": "useEffect",
        "properties": {
          "related_document": "node_001",
          "usage_count": 150
        }
      },
      {
        "id": "node_003",
        "type": "principle",
        "label": "单一职责原则",
        "properties": {
          "category": "best-practices",
          "usage_count": 200
        }
      }
    ],
    "edges": [
      {
        "source": "node_001",
        "target": "node_002",
        "type": "contains",
        "weight": 1.0,
        "properties": {
          "context": "具体使用示例"
        }
      },
      {
        "source": "node_001",
        "target": "node_003",
        "type": "illustrates",
        "weight": 0.8,
        "properties": {
          "context": "设计原则"
        }
      }
    ]
  }
}
```

### 实体识别
```typescript
interface KnowledgeEntity {
  id: string;
  type: 'document' | 'concept' | 'principle' | 'framework' | 'library' | 'pattern' | 'standard';
  name: string;
  description: string;
  aliases: string[];
  properties: Record<string, any>;
  usage_count: number;
  last_seen: Date;
}

class KnowledgeGraph {
  private entities: Map<string, KnowledgeEntity> = new Map();

  /**
   * 添加实体
   */
  addEntity(entity: KnowledgeEntity): void {
    this.entities.set(entity.id, entity);
  }

  /**
   * 查找相关实体
   */
  findRelatedEntities(
    query: string,
    type?: KnowledgeEntity['type'],
    limit: number = 10
  ): KnowledgeEntity[] {
    // 语义搜索
    const semanticResults = this.semanticSearch(query);

    // 标签匹配
    const tagResults = this.tagBasedSearch(query);

    // 合并结果
    const combined = this.mergeResults(semanticResults, tagResults);

    // 过滤类型
    if (type) {
      return combined.filter(e => e.type === type).slice(0, limit);
    }

    return combined.slice(0, limit);
  }

  /**
   * 查找关联实体
   */
  findRelatedEntitiesBy(
    entityId: string,
    relationType?: string,
    limit: number = 10
  ): KnowledgeEntity[] {
    const entity = this.entities.get(entityId);
    if (!entity) {
      return [];
    }

    // 使用知识图谱查找关联
    const related = this.graph.getConnected(entityId, relationType);

    return related.slice(0, limit);
  }
}
```

## 版本控制系统

### 文档版本
```json
{
  "document_id": "doc_001",
  "versions": [
    {
      "version": "1.0",
      "content": "# React Hooks最佳实践\n...",
      "checksum": "abc123",
      "created_at": "2024-01-10T10:00:00Z",
      "created_by": "user_001",
      "changes": [
        "Initial version"
      ],
      "is_current": true
    },
    {
      "version": "1.1",
      "content": "# React Hooks最佳实践\n...更新内容...",
      "checksum": "def456",
      "created_at": "2024-01-15T10:00:00Z",
      "created_by": "user_002",
      "changes": [
        "更新useEffect示例",
        "添加新的最佳实践"
      ],
      "is_current": false,
      "parent_version": "1.0"
    }
  ]
}
```

### 版本管理类
```typescript
class DocumentVersionManager {
  private versions: Map<string, Version[]> = new Map();

  /**
   * 创建新版本
   */
  async createVersion(
    documentId: string,
    content: string,
    changes: string[],
    createdBy: string
  ): Promise<string> {
    const versions = this.versions.get(documentId) || [];
    const currentVersion = versions[versions.length - 1];
    const newVersion = {
      version: this.generateVersionNumber(versions.length + 1),
      content,
      checksum: await this.calculateChecksum(content),
      created_at: new Date(),
      created_by: createdBy,
      changes,
      is_current: true
    };

    if (currentVersion) {
      currentVersion.is_current = false;
      newVersion.parent_version = currentVersion.version;
    }

    versions.push(newVersion);
    this.versions.set(documentId, versions);

    return newVersion.version;
  }

  /**
   * 查询版本历史
   */
  getVersionHistory(documentId: string): Version[] {
    return this.versions.get(documentId) || [];
  }

  /**
   * 恢复到指定版本
   */
  async restoreVersion(
    documentId: string,
    version: string
  ): Promise<string> {
    const versions = this.versions.get(documentId) || [];
    const targetVersion = versions.find(v => v.version === version);

    if (!targetVersion) {
      throw new Error(`Version ${version} not found`);
    }

    // 标记当前版本为非当前
    const currentIndex = versions.findIndex(v => v.is_current);
    if (currentIndex >= 0) {
      versions[currentIndex].is_current = false;
    }

    // 恢复指定版本
    targetVersion.is_current = true;
    return targetVersion.version;
  }

  /**
   * 生成版本号
   */
  private generateVersionNumber(versionCount: number): string {
    return `1.${versionCount}`;
  }

  /**
   * 计算内容校验和
   */
  private async calculateChecksum(content: string): Promise<string> {
    // 使用SHA-256
    const crypto = require('crypto');
    return crypto.createHash('sha256').update(content).digest('hex');
  }
}
```

## 检索优化

### 语义搜索
```typescript
class SemanticSearcher {
  private index: VectorIndex;

  /**
   * 语义搜索
   */
  async semanticSearch(
    query: string,
    topK: number = 10,
    filters?: SearchFilters
  ): Promise<SearchResult[]> {
    // 1. 向量化查询
    const queryVector = await this.vectorize(query);

    // 2. 搜索向量相似度
    const results = await this.index.search(queryVector, topK);

    // 3. 应用过滤器
    if (filters) {
      this.applyFilters(results, filters);
    }

    // 4. 相关性排序
    results.sort((a, b) => b.score - a.score);

    // 5. 返回结果
    return results.map(result => ({
      document_id: result.id,
      title: result.title,
      score: result.score,
      snippet: result.snippet,
      metadata: result.metadata
    }));
  }

  /**
   * 向量化文本
   */
  private async vectorize(text: string): Promise<number[]> {
    // 使用embedding模型
    const embeddings = await this.embeddingModel.embed(text);
    return embeddings;
  }
}
```

### 多维度检索
```typescript
interface SearchFilters {
  category?: string;
  tags?: string[];
  dateRange?: [Date, Date];
  language?: string;
  author?: string;
  keywords?: string[];
}

class MultiDimensionalSearcher {
  private semanticSearcher: SemanticSearcher;
  private keywordSearcher: KeywordSearcher;
  private tagSearcher: TagSearcher;

  /**
   * 多维度检索
   */
  async search(
    query: string,
    filters: SearchFilters,
    topK: number = 10
  ): Promise<SearchResult[]> {
    // 并行执行多个检索
    const [semanticResults, keywordResults, tagResults] = await Promise.all([
      this.semanticSearcher.semanticSearch(query, topK, filters),
      this.keywordSearcher.keywordSearch(query, topK),
      this.tagSearcher.tagSearch(query, filters)
    ]);

    // 合并结果
    return this.mergeResults([
      ...semanticResults.map(r => ({ ...r, sources: ['semantic'] })),
      ...keywordResults.map(r => ({ ...r, sources: ['keyword'] })),
      ...tagResults.map(r => ({ ...r, sources: ['tag'] }))
    ], topK);
  }

  /**
   * 合并检索结果
   */
  private mergeResults(
    results: SearchResult[],
    topK: number
  ): SearchResult[] {
    // 重新评分
    const scoredResults = this.reScoreResults(results);

    // 去重
    const uniqueResults = this.deduplicateResults(scoredResults);

    // 排序
    uniqueResults.sort((a, b) => b.finalScore - a.finalScore);

    return uniqueResults.slice(0, topK);
  }

  /**
   * 重新评分
   */
  private reScoreResults(results: SearchResult[]): SearchResult[] {
    const resultMap = new Map<string, SearchResult>();

    for (const result of results) {
      if (resultMap.has(result.document_id)) {
        const existing = resultMap.get(result.document_id)!;
        // 合并评分
        existing.finalScore = (existing.finalScore + result.score) / 2;
        existing.sources = [...new Set([...existing.sources, ...result.sources])];
      } else {
        result.finalScore = result.score;
        resultMap.set(result.document_id, result);
      }
    }

    return Array.from(resultMap.values());
  }
}
```

### 实时更新
```typescript
class KnowledgeBaseUpdater {
  private versionManager: DocumentVersionManager;
  private searchIndex: SearchIndex;

  /**
   * 检测新内容
   */
  async detectNewContent(): Promise<NewContent[]> {
    const newContent: NewContent[] = [];

    // 检查文档更新
    const updatedDocs = await this.detectUpdatedDocuments();
    newContent.push(...updatedDocs);

    // 检查新文档
    const newDocs = await this.detectNewDocuments();
    newContent.push(...newDocs);

    return newContent;
  }

  /**
   * 更新索引
   */
  async updateIndex(newContent: NewContent[]): Promise<void> {
    for (const content of newContent) {
      switch (content.type) {
        case 'document_updated':
          await this.updateDocument(content);
          break;

        case 'document_added':
          await this.addDocument(content);
          break;
      }
    }
  }

  /**
   * 更新文档索引
   */
  private async updateDocument(content: DocumentUpdatedContent): Promise<void> {
    // 更新语义索引
    await this.searchIndex.update(content.document_id, content.content);

    // 更新关键词索引
    await this.keywordIndex.update(content.document_id, content.content);

    // 更新标签索引
    await this.tagIndex.update(content.document_id, content.tags);
  }

  /**
   * 添加文档索引
   */
  private async addDocument(content: DocumentAddedContent): Promise<void> {
    // 添加到语义索引
    await this.searchIndex.add(content.document_id, content.content);

    // 添加到关键词索引
    await this.keywordIndex.add(content.document_id, content.content);

    // 添加到标签索引
    await this.tagIndex.add(content.document_id, content.tags);
  }
}
```

## 缓存系统

### 检索缓存
```typescript
interface SearchResultCache {
  query: string;
  filters: SearchFilters;
  result: SearchResult[];
  created_at: Date;
  ttl: number; // seconds
}

class SearchCache {
  private cache: Map<string, SearchResultCache> = new Map();

  /**
   * 获取缓存结果
   */
  getCacheKey(query: string, filters: SearchFilters): string {
    return JSON.stringify({ query, filters });
  }

  async getCached(
    query: string,
    filters: SearchFilters
  ): Promise<SearchResult[] | null> {
    const key = this.getCacheKey(query, filters);
    const cached = this.cache.get(key);

    if (!cached) {
      return null;
    }

    // 检查TTL
    if (Date.now() - cached.created_at.getTime() > cached.ttl * 1000) {
      this.cache.delete(key);
      return null;
    }

    return cached.result;
  }

  /**
   * 设置缓存
   */
  setCache(
    query: string,
    filters: SearchFilters,
    results: SearchResult[]
  ): void {
    const key = this.getCacheKey(query, filters);
    this.cache.set(key, {
      query,
      filters,
      result: results,
      created_at: new Date(),
      ttl: 3600 // 1小时
    });
  }
}
```

## 使用示例

### 完整检索流程
```typescript
async function searchKnowledge(query: string): Promise<SearchResult[]> {
  const searcher = new MultiDimensionalSearcher();

  const filters: SearchFilters = {
    language: 'zh-CN',
    dateRange: [new Date('2024-01-01'), new Date()]
  };

  const results = await searcher.search(query, filters, 10);

  return results;
}

async function getDocument(documentId: string): Promise<Document | null> {
  const manager = new DocumentVersionManager();

  // 获取最新版本
  const version = manager.getVersionHistory(documentId).find(v => v.is_current);

  if (!version) {
    return null;
  }

  return {
    id: documentId,
    title: '文档标题',
    content: version.content,
    version: version.version,
    created_at: version.created_at,
    updated_at: version.created_at
  };
}
```

---

## 性能优化

### 1. 缓存策略
- 检索结果缓存（TTL: 1小时）
- 向量索引缓存
- 文档内容缓存

### 2. 索引优化
- 使用增量索引更新
- 批量更新减少I/O
- 异步索引构建

### 3. 检索优化
- 语义搜索+关键词搜索混合
- 多维度过滤
- 相关性排序

---

## 总结

优化后的知识库系统提供：

- ✅ 完整的元数据管理
- ✅ 灵活的知识图谱
- ✅ 版本控制系统
- ✅ 高效的多维度检索
- ✅ 实时更新机制
- ✅ 智能缓存系统

---

*最后更新：2026-02-12*
*维护者：灵眸*
