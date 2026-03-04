# 性能优化

## 概述
性能优化指南，涵盖代码加载、缓存机制、并发处理、资源管理等各个方面。

## 性能优化策略

### 1. 代码加载优化

#### 1.1 代码分割
```typescript
// 使用动态导入实现代码分割
const HeavyComponent = React.lazy(() => import('./HeavyComponent'));

function App() {
  return (
    <Suspense fallback={<Loading />}>
      <HeavyComponent />
    </Suspense>
  );
}

// 基于路由的代码分割
const routes = [
  {
    path: '/home',
    component: () => import('./Home').then(m => m.default)
  },
  {
    path: '/about',
    component: () => import('./About').then(m => m.default)
  }
];
```

#### 1.2 懒加载
```typescript
// 懒加载技能模块
class LazySkillLoader {
  private cache = new Map<string, Skill>();

  async loadSkill(skillName: string): Promise<Skill> {
    if (this.cache.has(skillName)) {
      return this.cache.get(skillName);
    }

    // 动态导入技能模块
    const SkillModule = await import(`./skills/${skillName}`);
    const skill = new SkillModule.default();
    this.cache.set(skillName, skill);

    return skill;
  }
}
```

#### 1.3 预加载和预取
```typescript
// 预加载下一个页面
function prefetchNextPage(nextUrl: string) {
  const preloadUrl = nextUrl.startsWith('/') ? nextUrl : `/${nextUrl}`;

  if (preloadUrl) {
    import(`./pages/${preloadUrl}.tsx`).then(module => {
      module.default.preload();
    });
  }
}

// 在页面离开时预加载
function handleRouteChange(nextUrl: string) {
  prefetchNextPage(nextUrl);
}
```

### 2. 缓存机制

#### 2.1 内存缓存
```typescript
class MemoryCache<T> {
  private cache: Map<string, CacheEntry<T>> = new Map();
  private maxSize: number;
  private ttl: number;

  constructor(maxSize: number = 1000, ttl: number = 60000) {
    this.maxSize = maxSize;
    this.ttl = ttl;
  }

  get(key: string): T | undefined {
    const entry = this.cache.get(key);

    if (!entry) {
      return undefined;
    }

    // 检查是否过期
    if (Date.now() - entry.timestamp > this.ttl) {
      this.cache.delete(key);
      return undefined;
    }

    // 更新访问时间
    entry.lastAccess = Date.now();
    return entry.value;
  }

  set(key: string, value: T): void {
    // 如果缓存已满，移除最久未使用的项
    if (this.cache.size >= this.maxSize) {
      this.removeLRU();
    }

    this.cache.set(key, {
      value,
      timestamp: Date.now(),
      lastAccess: Date.now()
    });
  }

  async setWithPromise(key: string, valuePromise: Promise<T>): Promise<void> {
    const value = await valuePromise;
    this.set(key, value);
  }

  async getOrSet<T>(
    key: string,
    valueProvider: () => Promise<T>
  ): Promise<T> {
    let value = this.get(key);
    if (value === undefined) {
      value = await valueProvider();
      this.set(key, value);
    }
    return value;
  }

  private removeLRU(): void {
    let lruKey: string | null = null;
    let oldestTime = Date.now();

    for (const [key, entry] of this.cache) {
      if (entry.lastAccess < oldestTime) {
        oldestTime = entry.lastAccess;
        lruKey = key;
      }
    }

    if (lruKey) {
      this.cache.delete(lruKey);
    }
  }

  clear(): void {
    this.cache.clear();
  }

  getStats(): CacheStats {
    return {
      size: this.cache.size,
      maxSize: this.maxSize,
      oldestEntry: Math.min(...Array.from(this.cache.values()).map(e => e.timestamp))
    };
  }
}

interface CacheEntry<T> {
  value: T;
  timestamp: number;
  lastAccess: number;
}

interface CacheStats {
  size: number;
  maxSize: number;
  oldestEntry: number;
}
```

#### 2.2 分布式缓存
```typescript
class DistributedCache {
  private localCache = new MemoryCache<any>(100, 60000);
  private remoteCache: RemoteCache;

  async get(key: string): Promise<any> {
    // 先检查本地缓存
    let value = this.localCache.get(key);
    if (value !== undefined) {
      return value;
    }

    // 查询远程缓存
    value = await this.remoteCache.get(key);

    if (value !== undefined) {
      this.localCache.set(key, value);
    }

    return value;
  }

  async set(key: string, value: any, ttl?: number): Promise<void> {
    // 更新本地缓存
    this.localCache.set(key, value);

    // 更新远程缓存
    await this.remoteCache.set(key, value, ttl);
  }
}
```

#### 2.3 缓存策略
```typescript
class CacheStrategy {
  // 1. LRU (Least Recently Used) - 最近最少使用
  static readonly LRU = 'lru';

  // 2. LFU (Least Frequently Used) - 最少频率使用
  static readonly LFU = 'lfu';

  // 3. FIFO (First In First Out) - 先进先出
  static readonly FIFO = 'fifo';

  // 4. TTL (Time To Live) - 过期时间
  static readonly TTL = 'ttl';

  static create<T>(
    strategy: string,
    maxSize: number = 1000,
    ttl: number = 60000
  ): Cache<T> {
    switch (strategy) {
      case this.LRU:
        return new LRUCache<T>(maxSize, ttl);
      case this.LFU:
        return new LFUCache<T>(maxSize, ttl);
      case this.FIFO:
        return new FIFOCache<T>(maxSize, ttl);
      case this.TTL:
        return new TTLCache<T>(maxSize, ttl);
      default:
        return new LRUCache<T>(maxSize, ttl);
    }
  }
}
```

### 3. 并发处理

#### 3.1 Promise.all优化
```typescript
// 批量处理数据
async function processBatch<T>(
  items: T[],
  batchSize: number,
  processor: (item: T) => Promise<any>
): Promise<any[]> {
  const results = [];

  for (let i = 0; i < items.length; i += batchSize) {
    const batch = items.slice(i, i + batchSize);
    const batchResults = await Promise.all(
      batch.map(processor)
    );
    results.push(...batchResults);
  }

  return results;
}

// 使用示例
const users = getUsers(1000);
const processedUsers = await processBatch(users, 10, processUser);
```

#### 3.2 并行任务执行
```typescript
class ParallelExecutor {
  private concurrencyLimit: number;
  private runningTasks: Set<Promise<any>> = new Set();

  constructor(concurrencyLimit: number = 5) {
    this.concurrencyLimit = concurrencyLimit;
  }

  async execute<T>(
    items: T[],
    task: (item: T) => Promise<any>,
    options?: {
      onProgress?: (progress: number) => void;
      onSuccess?: (item: T, result: any) => void;
      onError?: (item: T, error: Error) => void;
    }
  ): Promise<ParallelResult<T>> {
    const results: Array<ParallelResultItem<T>> = [];
    const failed: Array<ParallelResultItem<T>> = [];
    let completed = 0;
    let failedCount = 0;

    for (const item of items) {
      const taskPromise = task(item).then(
        result => {
          completed++;
          results.push({ item, result, error: null });

          if (options?.onSuccess) {
            options.onSuccess(item, result);
          }

          if (options?.onProgress) {
            options.onProgress((completed / items.length) * 100);
          }

          return result;
        },
        error => {
          failedCount++;
          failed.push({ item, result: null, error });

          if (options?.onError) {
            options.onError(item, error);
          }

          return null;
        }
      );

      this.runningTasks.add(taskPromise);

      // 等待一个任务完成后再启动下一个
      taskPromise.finally(() => {
        this.runningTasks.delete(taskPromise);

        // 启动下一个任务
        if (this.runningTasks.size < this.concurrencyLimit) {
          // 继续处理
        }
      });
    }

    // 等待所有任务完成
    await Promise.all(this.runningTasks);

    return {
      results,
      failed,
      total: items.length,
      successRate: (completed / items.length) * 100
    };
  }
}

interface ParallelResult<T> {
  results: Array<ParallelResultItem<T>>;
  failed: Array<ParallelResultItem<T>>;
  total: number;
  successRate: number;
}

interface ParallelResultItem<T> {
  item: T;
  result: any;
  error: Error | null;
}
```

#### 3.3 异步流处理
```typescript
class AsyncStreamProcessor<T, R> {
  private stream: AsyncIterable<T>;
  private processor: (item: T) => Promise<R>;

  constructor(
    stream: AsyncIterable<T>,
    processor: (item: T) => Promise<R>
  ) {
    this.stream = stream;
    this.processor = processor;
  }

  async process(options?: {
    concurrency?: number;
    batchSize?: number;
  }): Promise<R[]> {
    const results: R[] = [];
    const batch: T[] = [];

    for await (const item of this.stream) {
      batch.push(item);

      // 达到批次大小时处理
      if (batch.length >= (options?.batchSize || 10)) {
        const batchResults = await this.processBatch(batch);
        results.push(...batchResults);
        batch.length = 0;
      }
    }

    // 处理剩余项
    if (batch.length > 0) {
      const batchResults = await this.processBatch(batch);
      results.push(...batchResults);
    }

    return results;
  }

  private async processBatch(items: T[]): Promise<R[]> {
    return Promise.all(items.map(this.processor));
  }
}

// 使用示例
async function* generateData(): AsyncIterable<number> {
  for (let i = 0; i < 100; i++) {
    await delay(100);
    yield i;
  }
}

const processor = new AsyncStreamProcessor(
  generateData(),
  async (item) => {
    return await processItem(item);
  }
);

const results = await processor.process({
  concurrency: 5,
  batchSize: 10
});
```

### 4. 资源管理

#### 4.1 内存管理
```typescript
class MemoryManager {
  private usage: MemoryUsage = {
    used: 0,
    allocated: 0,
    peaks: []
  };

  constructor(private limit: number = 100 * 1024 * 1024) {
    this.monitorMemory();
  }

  allocate(size: number): boolean {
    if (this.usage.used + size > this.limit) {
      this.gc();
      if (this.usage.used + size > this.limit) {
        return false;
      }
    }

    this.usage.used += size;
    this.recordPeak();

    return true;
  }

  release(size: number): void {
    this.usage.used = Math.max(0, this.usage.used - size);
  }

  private recordPeak(): void {
    this.usage.peaks.push({
      timestamp: Date.now(),
      size: this.usage.used
    });

    // 只保留最近100个峰值
    if (this.usage.peaks.length > 100) {
      this.usage.peaks.shift();
    }
  }

  private monitorMemory(): void {
    setInterval(() => {
      this.gc();
    }, 60000); // 每分钟检查一次
  }

  private gc(): void {
    // 触发垃圾回收
    if (global.gc) {
      global.gc();
    }

    // 清理不活跃的资源
    this.cleanupInactiveResources();
  }

  private cleanupInactiveResources(): void {
    // 实现资源清理逻辑
  }

  getUsage(): MemoryUsage {
    return { ...this.usage };
  }

  getAvailable(): number {
    return this.limit - this.usage.used;
  }

  isHealthy(): boolean {
    const usagePercent = (this.usage.used / this.limit) * 100;
    return usagePercent < 80; // 使用率小于80%视为健康
  }
}

interface MemoryUsage {
  used: number;
  allocated: number;
  peaks: MemoryPeak[];
}

interface MemoryPeak {
  timestamp: number;
  size: number;
}
```

#### 4.2 连接池管理
```typescript
class ConnectionPool<T> {
  private pool: T[] = [];
  private available: T[] = [];
  private inUse: Set<T> = new Set();

  constructor(
    private factory: () => Promise<T>,
    private maxSize: number = 10,
    private timeout: number = 30000
  ) {}

  async acquire(): Promise<T> {
    // 先从池中获取
    if (this.available.length > 0) {
      const connection = this.available.pop()!;
      this.inUse.add(connection);
      return connection;
    }

    // 检查是否可以创建新连接
    if (this.pool.length < this.maxSize) {
      const connection = await this.factory();
      this.pool.push(connection);
      this.inUse.add(connection);
      return connection;
    }

    // 需要等待可用连接
    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        this.available.delete(this);
        this.inUse.delete(this);
        reject(new Error('获取连接超时'));
      }, this.timeout);

      const check = () => {
        if (this.available.length > 0) {
          clearTimeout(timeout);
          const connection = this.available.pop()!;
          this.inUse.add(connection);
          resolve(connection);
        } else {
          setTimeout(check, 100);
        }
      };

      check();
    });
  }

  release(connection: T): void {
    this.inUse.delete(connection);
    this.available.push(connection);
  }

  async closeAll(): Promise<void> {
    // 关闭所有连接
    for (const connection of this.pool) {
      await this.closeConnection(connection);
    }

    this.pool = [];
    this.available = [];
    this.inUse.clear();
  }

  private async closeConnection(connection: T): Promise<void> {
    // 实现连接关闭逻辑
  }

  getStats(): PoolStats {
    return {
      total: this.pool.length,
      available: this.available.length,
      inUse: this.inUse.size,
      maxSize: this.maxSize
    };
  }
}

interface PoolStats {
  total: number;
  available: number;
  inUse: number;
  maxSize: number;
}
```

### 5. 数据库优化

#### 5.1 批量插入优化
```typescript
async function batchInsert<T>(
  db: Database,
  table: string,
  items: T[],
  batchSize: number = 1000
): Promise<void> {
  for (let i = 0; i < items.length; i += batchSize) {
    const batch = items.slice(i, i + batchSize);

    await db.insert(table, batch, {
      batch: true,
      transaction: true
    });

    console.log(`已插入 ${i + batch.length}/${items.length} 条记录`);
  }
}
```

#### 5.2 查询优化
```typescript
async function optimizedQuery(db: Database, conditions: QueryConditions) {
  // 使用索引
  const results = await db.query(`
    SELECT * FROM users
    WHERE ${conditions.where}
    ORDER BY ${conditions.orderBy}
    LIMIT ${conditions.limit}
    OFFSET ${conditions.offset}
  `, conditions.params);

  return results;
}
```

### 6. 前端优化

#### 6.1 虚拟列表
```typescript
class VirtualList<T> {
  private containerHeight: number;
  private itemHeight: number;
  private items: T[] = [];
  private startIndex: number = 0;

  constructor(
    containerHeight: number,
    itemHeight: number
  ) {
    this.containerHeight = containerHeight;
    this.itemHeight = itemHeight;
  }

  render(visibleCount: number): RenderedItems<T> {
    const endIndex = Math.min(
      this.startIndex + visibleCount,
      this.items.length
    );

    const visibleItems = this.items.slice(
      this.startIndex,
      endIndex
    );

    const scrollTop = this.startIndex * this.itemHeight;

    return {
      items: visibleItems,
      scrollTop,
      hasMore: endIndex < this.items.length
    };
  }

  handleScroll(scrollTop: number): void {
    this.startIndex = Math.floor(scrollTop / this.itemHeight);
  }
}

interface RenderedItems<T> {
  items: T[];
  scrollTop: number;
  hasMore: boolean;
}
```

### 7. 性能监控

#### 7.1 性能追踪
```typescript
class PerformanceMonitor {
  private traces: Map<string, TraceEntry> = new Map();

  startTrace(name: string): TraceEntry {
    const entry: TraceEntry = {
      name,
      startTime: Date.now(),
      metrics: {}
    };
    this.traces.set(name, entry);
    return entry;
  }

  endTrace(name: string): TraceEntry {
    const entry = this.traces.get(name);
    if (!entry) {
      throw new Error(`Trace ${name} not found`);
    }

    entry.endTime = Date.now();
    entry.duration = entry.endTime - entry.startTime;
    this.traces.delete(name);

    return entry;
  }

  recordMetric(name: string, key: string, value: any): void {
    const trace = this.traces.get(name);
    if (!trace) {
      return;
    }

    if (!trace.metrics[key]) {
      trace.metrics[key] = [];
    }

    trace.metrics[key].push(value);
  }

  getReport(): PerformanceReport {
    const report: PerformanceReport = {
      traces: Array.from(this.traces.values()).map(trace => ({
        name: trace.name,
        duration: trace.duration,
        metrics: trace.metrics
      })),
      totalTime: this.traces.size > 0
        ? Math.max(...Array.from(this.traces.values()).map(t => t.duration))
        : 0
    };

    return report;
  }
}

interface TraceEntry {
  name: string;
  startTime: number;
  endTime?: number;
  duration?: number;
  metrics: Record<string, any[]>;
}

interface PerformanceReport {
  traces: Array<{
    name: string;
    duration: number;
    metrics: Record<string, any[]>;
  }>;
  totalTime: number;
}
```

#### 7.2 性能分析工具
```typescript
class PerformanceProfiler {
  private profiles: Map<string, Profile> = new Map();

  async profile<T>(
    name: string,
    fn: () => Promise<T>
  ): Promise<T> {
    const start = Date.now();
    const memoryStart = this.getMemoryUsage();

    try {
      const result = await fn();
      return result;
    } finally {
      const duration = Date.now() - start;
      const memoryEnd = this.getMemoryUsage();
      const memoryDelta = memoryEnd - memoryStart;

      this.recordProfile(name, duration, memoryDelta);
    }
  }

  private getMemoryUsage(): number {
    return process.memoryUsage().heapUsed;
  }

  private recordProfile(
    name: string,
    duration: number,
    memoryDelta: number
  ): void {
    const profile: Profile = {
      name,
      duration,
      memoryDelta,
      timestamp: Date.now()
    };

    this.profiles.set(name, profile);
  }

  getSummary(): string {
    let summary = '性能分析报告:\n';

    for (const [name, profile] of this.profiles) {
      summary += `- ${name}: ${profile.duration}ms (内存: ${profile.memoryDelta} bytes)\n`;
    }

    return summary;
  }
}

interface Profile {
  name: string;
  duration: number;
  memoryDelta: number;
  timestamp: number;
}
```

## 性能优化检查清单

### 代码层面
- [ ] 使用代码分割和懒加载
- [ ] 优化函数和算法复杂度
- [ ] 避免不必要的计算和重复
- [ ] 使用缓存减少重复计算

### 数据库层面
- [ ] 使用索引优化查询
- [ ] 批量操作代替单个操作
- [ ] 优化查询语句
- [ ] 使用连接池

### 前端层面
- [ ] 实现虚拟列表
- [ ] 优化图片和资源加载
- [ ] 使用Web Worker处理复杂计算
- [ ] 减少重绘和回流

### 系统层面
- [ ] 优化并发处理
- [ ] 管理内存使用
- [ ] 实现连接池
- [ ] 监控和优化性能

## 性能优化目标

- **响应时间**: < 100ms (P95)
- **吞吐量**: > 1000 QPS
- **内存使用**: < 80% 配额
- **CPU使用**: < 80% 配额

## 使用建议

1. **性能优先**: 在开发阶段就考虑性能
2. **监控驱动**: 使用性能监控工具
3. **数据驱动**: 根据性能数据做优化
4. **持续优化**: 性能优化是持续的过程
5. **测试验证**: 每次优化都要验证效果
