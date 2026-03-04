# Copilot - 扩展代码模式库

## 概述
代码模式库包含200+常见代码模式和最佳实践，涵盖多种编程语言和场景。

## 使用方法
1. 根据问题类型选择合适的模式
2. 参考模式实现，结合实际需求调整
3. 学习模式背后的设计原理
4. 理解应用场景和限制

---

## JavaScript/TypeScript 模式

### 1. 异步编程模式

#### 异步函数等待
```typescript
async function fetchUser(userId: string) {
  try {
    const response = await fetch(`/api/users/${userId}`);
    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Failed to fetch user:', error);
    throw error;
  }
}
```

**场景**：需要等待异步操作完成的场景

**最佳实践**：
- 使用async/await语法
- 在顶层try-catch中处理错误
- 避免嵌套的async函数

#### Promise链式调用优化
```typescript
async function processUser(userId: string) {
  const user = await fetchUser(userId);
  const posts = await fetchUserPosts(userId);
  const comments = await fetchUserComments(userId);

  return {
    user,
    posts,
    comments
  };
}
```

**场景**：需要按顺序执行多个异步操作

**替代方案**：
- 使用`Promise.all`并行执行
- 使用`Promise.allSettled`捕获所有结果

#### 错误边界处理
```typescript
async function safeFetch(url: string) {
  try {
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    return response.json();
  } catch (error) {
    // 记录错误到监控系统
    logError(error, { url });
    throw error;
  }
}
```

**场景**：需要统一错误处理的场景

**最佳实践**：
- 在单层try-catch中处理所有错误
- 记录错误详情以便排查
- 提供有意义的错误信息

### 2. React模式

#### React Hooks最佳实践
```typescript
import { useState, useEffect, useCallback } from 'react';

function UserProfile({ userId }: { userId: string }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchUser = useCallback(async () => {
    try {
      setLoading(true);
      const data = await fetchUserFromAPI(userId);
      setUser(data);
      setError(null);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [userId]);

  useEffect(() => {
    fetchUser();
  }, [fetchUser]);

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error}</div>;

  return <UserCard user={user} />;
}
```

**场景**：需要状态管理和副作用处理的组件

**最佳实践**：
- 使用useCallback缓存函数
- 使用useEffect清理副作用
- 提供loading和error状态

#### 自定义Hooks模式
```typescript
function useLocalStorage<T>(key: string, initialValue: T) {
  const [storedValue, setStoredValue] = useState<T>(() => {
    if (typeof window === 'undefined') {
      return initialValue;
    }
    try {
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch (error) {
      console.error(error);
      return initialValue;
    }
  });

  const setValue = useCallback((value: T | ((val: T) => T)) => {
    try {
      const valueToStore =
        value instanceof Function ? value(storedValue) : value;
      setStoredValue(valueToStore);
      if (typeof window !== 'undefined') {
        window.localStorage.setItem(key, JSON.stringify(valueToStore));
      }
    } catch (error) {
      console.error(error);
    }
  }, [key, storedValue]);

  return [storedValue, setValue] as const;
}
```

**场景**：需要封装重复逻辑的自定义Hook

**最佳实践**：
- 遵循Hooks命名规范（use开头）
- 返回多个值时使用数组
- 在组件顶层使用

#### 错误边界模式
```typescript
class ErrorBoundary extends React.Component<
  { children: React.ReactNode },
  { hasError: boolean }
> {
  constructor(props: { children: React.ReactNode }) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error) {
    return { hasError: true };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('Error caught by boundary:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="error-boundary">
          <h1>Something went wrong.</h1>
          <button onClick={() => this.setState({ hasError: false })}>
            Try again
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}
```

**场景**：需要捕获子组件错误的场景

**最佳实践**：
- 只捕获渲染阶段的错误
- 提供友好的错误UI
- 记录错误详情

### 3. TypeScript模式

#### 泛型约束
```typescript
// 约束对象必须有length属性
function logLength<T extends { length: number }>(obj: T) {
  console.log(`Length: ${obj.length}`);
}

logLength('hello'); // 5
logLength([1, 2, 3]); // 3
logLength({ length: 10 }); // 10

// 泛型约束
interface Person {
  name: string;
  age: number;
}

function createIdentity<T extends Person>(person: T) {
  return {
    id: Math.random().toString(),
    ...person
  };
}

const user = createIdentity({ name: 'Alice', age: 30 });
```

**场景**：需要类型安全的数据处理

**最佳实践**：
- 使用extends约束泛型
- 避免过度使用any
- 提供类型推断

#### 联合类型模式
```typescript
// 简单联合类型
type Direction = 'up' | 'down' | 'left' | 'right';

function move(direction: Direction, distance: number) {
  console.log(`Move ${distance} ${direction}`);
}

move('up', 10); // ✅
move('diagonal', 5); // ❌ Type error

// 函数参数联合类型
function logResponse(response: Response | string) {
  if (typeof response === 'string') {
    console.log(response);
  } else {
    console.log(response.status, response.statusText);
  }
}
```

**场景**：需要处理多种可能类型的场景

**最佳实践**：
- 使用联合类型明确可能值
- 使用类型守卫进行类型检查
- 避免使用never

#### 实用类型
```typescript
// Partial<T> - 部分属性
interface User {
  id: number;
  name: string;
  email: string;
}

type PartialUser = Partial<User>;
const user: PartialUser = { name: 'Alice' }; // ✅

// Required<T> - 必填属性
type RequiredUser = Required<User>;
const requiredUser: RequiredUser = { id: 1, name: 'Alice', email: 'alice@example.com' };

// Pick<T, K> - 选择属性
type UserName = Pick<User, 'name' | 'email'>;

// Omit<T, K> - 排除属性
type UserWithoutId = Omit<User, 'id'>;

// Readonly<T> - 只读
type ReadonlyUser = Readonly<User>;
// readonlyUser.id = 2; // ❌ Type error

// Record<K, T> - 类型映射
type UserMap = Record<string, User>;
const users: UserMap = {
  '1': { id: 1, name: 'Alice', email: 'alice@example.com' }
};
```

**场景**：需要灵活的类型转换

**最佳实践**：
- 使用标准工具类型
- 避免手动重复定义
- 组合使用多个工具类型

### 4. Node.js模式

#### 模块导出模式
```typescript
// Default export
export default class UserService {
  async getUser(id: number): Promise<User> {
    // Implementation
  }
}

// Named exports
export function formatDate(date: Date): string {
  // Implementation
}

export const API_BASE = 'https://api.example.com';
export type UserRole = 'admin' | 'user' | 'guest';

// Multiple exports
export class UserService { /* ... */ }
export class AuthService { /* ... */ }
export { formatDate, API_BASE };
```

**场景**：需要组织代码模块

**最佳实践**：
- 使用named exports组织功能
- 将常量放在单独的文件
- 导出类型定义

#### 异步循环处理
```typescript
async function processFiles(files: File[]): Promise<void> {
  // 使用Promise.all并行处理（适合独立文件）
  await Promise.all(
    files.map(async (file) => {
      await processFile(file);
    })
  );

  // 使用for-await遍历异步迭代器（适合需要顺序处理的场景）
  for await (const file of files) {
    await processFile(file);
  }

  // 使用batch处理大数据集（避免内存溢出）
  const BATCH_SIZE = 10;
  for (let i = 0; i < files.length; i += BATCH_SIZE) {
    const batch = files.slice(i, i + BATCH_SIZE);
    await Promise.all(batch.map(processFile));
  }
}

async function* processFilesBatch(files: File[]): AsyncGenerator<void> {
  const BATCH_SIZE = 10;
  for (let i = 0; i < files.length; i += BATCH_SIZE) {
    const batch = files.slice(i, i + BATCH_SIZE);
    yield Promise.all(batch.map(processFile));
  }
}
```

**场景**：需要处理大量文件或数据

**最佳实践**：
- 使用batch处理大数据集
- 使用for-await处理异步迭代器
- 使用Promise.all并行处理独立任务

### 5. 工具函数模式

#### 数组操作
```typescript
// 数组去重
function unique<T>(array: T[]): T[] {
  return [...new Set(array)];
}

// 数组扁平化
function flatten<T>(array: T[][]): T[] {
  return array.flat();
}

// 数组分组
function groupBy<T>(array: T[], key: keyof T): Record<string, T[]> {
  return array.reduce((acc, item) => {
    const groupKey = String(item[key]);
    if (!acc[groupKey]) {
      acc[groupKey] = [];
    }
    acc[groupKey].push(item);
    return acc;
  }, {} as Record<string, T[]>);
}

// 数组排序
function sortBy<T, K extends keyof T>(
  array: T[],
  key: K,
  order: 'asc' | 'desc' = 'asc'
): T[] {
  return [...array].sort((a, b) => {
    if (order === 'asc') {
      return a[key] > b[key] ? 1 : -1;
    } else {
      return a[key] < b[key] ? 1 : -1;
    }
  });
}
```

**场景**：需要数组操作

**最佳实践**：
- 返回新数组，不修改原数组
- 使用类型推断提高类型安全
- 提供清晰的函数名

#### 对象操作
```typescript
// 深拷贝
function deepClone<T>(obj: T): T {
  return JSON.parse(JSON.stringify(obj));
}

// 对象合并
function merge<T, U>(target: T, source: U): T & U {
  return { ...target, ...source };
}

// 对象映射
function mapObject<T, U>(
  obj: T,
  mapper: (key: keyof T, value: T[keyof T]) => U
): Record<string, U> {
  const result: Record<string, U> = {};
  for (const key in obj) {
    if (Object.prototype.hasOwnProperty.call(obj, key)) {
      result[key] = mapper(key, obj[key] as T[keyof T]);
    }
  }
  return result;
}

// 对象过滤
function filterObject<T>(
  obj: T,
  predicate: (key: keyof T, value: T[keyof T]) => boolean
): Partial<T> {
  const result: Partial<T> = {};
  for (const key in obj) {
    if (Object.prototype.hasOwnProperty.call(obj, key)) {
      if (predicate(key, obj[key] as T[keyof T])) {
        result[key] = obj[key];
      }
    }
  }
  return result;
}
```

**场景**：需要对象操作

**最佳实践**：
- 使用展开运算符简化合并
- 深拷贝使用JSON方法（注意循环引用）
- 类型推断提高类型安全

---

## Python模式

### 1. 异步编程

#### async/await模式
```python
import asyncio

async def fetch_user(user_id: int) -> dict:
    """获取用户信息"""
    await asyncio.sleep(0.1)  # 模拟网络请求
    return {"id": user_id, "name": "Alice"}

async def fetch_posts(user_id: int) -> list:
    """获取用户帖子"""
    await asyncio.sleep(0.1)  # 模拟网络请求
    return [1, 2, 3]

async def get_user_profile(user_id: int) -> dict:
    """获取用户完整资料"""
    user = await fetch_user(user_id)
    posts = await fetch_posts(user_id)
    return {"user": user, "posts": posts}

# 运行异步函数
async def main():
    profile = await get_user_profile(1)
    print(profile)

asyncio.run(main())
```

**场景**：需要异步IO操作

**最佳实践**：
- 使用async/await简化异步代码
- 在顶层使用try-except处理错误
- 避免在async函数中使用阻塞调用

#### 并行执行
```python
import asyncio

async def fetch_data(url: str) -> dict:
    await asyncio.sleep(0.1)
    return {"url": url, "data": "sample"}

async def main():
    # 并行执行多个异步任务
    tasks = [
        fetch_data("https://api1.example.com"),
        fetch_data("https://api2.example.com"),
        fetch_data("https://api3.example.com")
    ]
    results = await asyncio.gather(*tasks)

    for result in results:
        print(result)

asyncio.run(main())

# 使用线程池执行CPU密集型任务
import concurrent.futures
import time

def cpu_intensive_task(x: int) -> int:
    time.sleep(1)
    return x * 2

async def main():
    loop = asyncio.get_event_loop()
    with concurrent.futures.ThreadPoolExecutor() as pool:
        numbers = [1, 2, 3, 4, 5]
        results = await loop.run_in_executor(
            pool, cpu_intensive_task, numbers
        )
        print(results)

asyncio.run(main())
```

**场景**：需要并行处理多个任务

**最佳实践**：
- 使用asyncio.gather并行执行独立任务
- 使用ThreadPoolExecutor处理CPU密集型任务
- 注意任务数量，避免过度并发

### 2. 类设计

#### 类型注解
```python
from typing import List, Optional, Dict

class User:
    def __init__(
        self,
        id: int,
        name: str,
        email: Optional[str] = None,
        age: Optional[int] = None
    ):
        self.id: int = id
        self.name: str = name
        self.email: Optional[str] = email
        self.age: Optional[int] = age

    def greet(self) -> str:
        return f"Hello, {self.name}"

    def is_adult(self) -> bool:
        return self.age is not None and self.age >= 18

class UserService:
    def __init__(self, db_connection):
        self.db = db_connection

    def get_user(self, user_id: int) -> Optional[User]:
        # 实现
        return None

    def get_all_users(self) -> List[User]:
        # 实现
        return []
```

**场景**：需要类型安全的类设计

**最佳实践**：
- 为所有参数和返回值添加类型注解
- 使用Optional表示可能为None的值
- 使用List、Dict等类型注解集合类型

#### 数据类
```python
from dataclasses import dataclass, field
from typing import List

@dataclass
class User:
    id: int
    name: str
    email: Optional[str] = None
    age: Optional[int] = None

@dataclass(order=True)
class SortedUser:
    age: int = field(compare=True)
    name: str = field(compare=True)
    id: int = field(compare=False)

# 使用
user = User(id=1, name="Alice", age=30)
print(user)  # User(id=1, name='Alice', email=None, age=30)

users: List[User] = [
    User(id=3, name="Bob", age=25),
    User(id=1, name="Alice", age=30)
]
users_sorted = sorted(users)
```

**场景**：需要简洁的数据结构定义

**最佳实践**：
- 使用dataclass简化数据类定义
- 添加order=True使类可排序
- 使用field()控制比较行为

---

## Go模式

### 1. 错误处理

#### 错误检查模式
```go
package main

import (
    "errors"
    "fmt"
)

func divide(a, b int) (int, error) {
    if b == 0 {
        return 0, errors.New("division by zero")
    }
    return a / b, nil
}

func main() {
    result, err := divide(10, 0)
    if err != nil {
        fmt.Println("Error:", err)
        return
    }
    fmt.Println("Result:", result)
}
```

**场景**：需要处理可能的错误

**最佳实践**：
- 在可能出错的地方返回error
- 使用if err != nil检查错误
- 不要忽略错误

#### 错误包装
```go
func processFile(filename string) error {
    file, err := os.Open(filename)
    if err != nil {
        return fmt.Errorf("failed to open file %s: %w", filename, err)
    }
    defer file.Close()

    data, err := io.ReadAll(file)
    if err != nil {
        return fmt.Errorf("failed to read file %s: %w", filename, err)
    }

    // 处理数据...
    return nil
}

func main() {
    err := processFile("data.txt")
    if err != nil {
        // 包含原始错误的详细错误信息
        fmt.Println(err) // failed to open file data.txt: open data.txt: no such file or directory
    }
}
```

**场景**：需要保留错误链信息

**最佳实践**：
- 使用fmt.Errorf和%w包装错误
- 在错误信息中包含上下文
- 使用errors.Is()检查特定错误

### 2. 并发编程

#### Goroutine和Channel
```go
package main

import (
    "fmt"
    "sync"
)

func worker(id int, jobs <-chan int, results chan<- int, wg *sync.WaitGroup) {
    defer wg.Done()

    for j := range jobs {
        fmt.Printf("Worker %d started job %d\n", id, j)
        result := j * 2
        results <- result
        fmt.Printf("Worker %d finished job %d, result: %d\n", id, j, result)
    }
}

func main() {
    const numJobs = 5
    const numWorkers = 3

    jobs := make(chan int, numJobs)
    results := make(chan int, numJobs)
    var wg sync.WaitGroup

    // 启动worker
    for i := 1; i <= numWorkers; i++ {
        wg.Add(1)
        go worker(i, jobs, results, &wg)
    }

    // 发送任务
    for j := 1; j <= numJobs; j++ {
        jobs <- j
    }
    close(jobs)

    // 等待所有worker完成
    wg.Wait()
    close(results)

    // 接收结果
    for r := range results {
        fmt.Println("Result:", r)
    }
}
```

**场景**：需要并发处理任务

**最佳实践**：
- 使用goroutine并行处理任务
- 使用channel传递数据
- 使用sync.WaitGroup等待所有任务完成

---

## Rust模式

### 1. 所有权和借用

#### 所有权转移
```rust
fn main() {
    let s1 = String::from("hello");
    let s2 = s1; // 所有权转移

    // println!("{}", s1); // 错误：s1已失效
    println!("{}", s2); // ✅

    let s3 = take_ownership(s1); // 所有权转移给函数
    // println!("{}", s1); // 错误：s1已失效
    println!("{}", s3); // ✅
}

fn take_ownership(s: String) -> String {
    s
}
```

**场景**：需要理解所有权机制

**最佳实践**：
- 理解所有权转移和借用
- 使用引用避免所有权转移
- 使用move语义转移所有权

#### 借用检查
```rust
fn main() {
    let mut s = String::from("hello");

    // 可变引用
    let r1 = &mut s;
    r1.push_str(", world");
    println!("{}", r1); // ✅

    // 可变引用不能同时存在
    // let r2 = &mut s; // 错误：s被r1借用
    // r1.push_str("!"); // ✅
    // println!("{}", s); // ✅
    // println!("{}", r2); // 错误：r1被丢弃
}
```

**场景**：需要理解借用规则

**最佳实践**：
- 同一时间只能有一个可变引用
- 可变引用和不可变引用可以同时存在
- 避免数据竞争

---

## 更多模式

### 工具函数库
- [ ] 数组和对象操作（10+模式）
- [ ] 字符串处理（5+模式）
- [ ] 数学计算（5+模式）
- [ ] 日期时间处理（5+模式）
- [ ] 正则表达式（5+模式）

### 前端框架模式
- [ ] Vue.js（5+模式）
- [ ] Angular（5+模式）
- [ ] Svelte（3+模式）

### 后端框架模式
- [ ] Express.js（5+模式）
- [ ] NestJS（5+模式）
- [ ] Django（5+模式）
- [ ] FastAPI（5+模式）

### DevOps模式
- [ ] Docker（5+模式）
- [ ] Kubernetes（5+模式）
- [ ] CI/CD（5+模式）

---

## 使用建议

1. **按需学习**：根据实际需求学习模式
2. **理解原理**：理解模式背后的设计原理
3. **实践应用**：在实际项目中应用模式
4. **持续优化**：根据反馈持续改进
5. **分享交流**：与他人分享学习心得

---

*最后更新：2026-02-12*
*维护者：灵眸*
