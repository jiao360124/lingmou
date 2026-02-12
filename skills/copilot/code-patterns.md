# Copilot代码模式库

## 概述
本代码模式库包含100+常见代码模式，用于智能补全、重构建议和最佳实践指导。

## 分类索引

### 1. JavaScript/TypeScript
- [ ] 函数组合和链式调用
- [ ] 异步/await模式
- [ ] React Hooks最佳实践
- [ ] TypeScript泛型使用
- [ ] 异常处理模式
- [ ] 数据验证模式
- [ ] 响应式编程
- [ ] 性能优化模式

### 2. Python
- [ ] 上下文管理器
- [ ] 装饰器模式
- [ ] 单例模式
- [ ] 工厂模式
- [ ] 观察者模式
- [ ] 装饰器验证
- [ ] 异步IO模式
- [ ] 数据验证模式

### 3. Go
- [ ] 接口设计
- [ ] 错误处理
- [ ] 并发模式
- [ ] 组合优于继承
- [ ] defer使用
- [ ] context传递
- [ ] 服务结构体
- [ ] 依赖注入

### 4. Rust
- [ ] 所有权和借用
- [ ] 模式匹配
- [ ] 错误处理
- [ ] Trait定义
- [ ] Async/Await
- [ ] 枚举和Option
- [ ] Result处理
- [ ] 模块系统

### 5. Web框架
- [ ] REST API设计
- [ ] GraphQL查询
- [ ] 中间件模式
- [ ] 中间件链
- [ ] 路由模式
- [ ] 请求验证
- [ ] 响应格式化
- [ ] 认证授权

### 6. 数据处理
- [ ] 批量处理
- [ ] 流式处理
- [ ] 采样和聚合
- [ ] 过滤和映射
- [ ] 转换和转换
- [ ] 数据清洗
- [ ] 数据转换
- [ ] 数据合并

### 7. 数据库
- [ ] 连接池管理
- [ ] 查询优化
- [ ] 批量插入
- [ ] 事务处理
- [ ] 缓存策略
- [ ] 数据迁移
- [ ] 备份策略
- [ ] 性能监控

### 8. 系统设计
- [ ] 微服务架构
- [ ] 事件驱动
- [ ] CQRS模式
- [ ] 发布订阅
- [ ] 服务发现
- [ ] API网关
- [ ] 配置管理
- [ ] 日志系统

### 9. 安全性
- [ ] 输入验证
- [ ] 输出编码
- [ ] 密码哈希
- [ ] CSRF防护
- [ ] XSS防护
- [ ] SQL注入防护
- [ ] 速率限制
- [ ] 认证授权

### 10. 性能优化
- [ ] 缓存策略
- [ ] 懒加载
- [ ] 预加载
- [ ] 防抖和节流
- [ ] 批量处理
- [ ] 减少不必要的计算
- [ ] 优化数据结构
- [ ] 内存管理

## 常用模式模板

### JavaScript/TypeScript

#### 函数组合
```typescript
const compose = (...fns) => x => fns.reduceRight((v, f) => f(v), x);

// 使用示例
const toUpper = s => s.toUpperCase();
const addExclaim = s => s + '!';
const result = compose(addExclaim, toUpper)('hello'); // 'HELLO!'
```

#### React Hooks
```typescript
// 自定义Hook
const useWindowSize = () => {
  const [size, setSize] = useState([window.innerWidth, window.innerHeight]);

  useEffect(() => {
    const handleResize = () => setSize([window.innerWidth, window.innerHeight]);
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  return size;
};

// 使用示例
const [width, height] = useWindowSize();
```

#### TypeScript泛型
```typescript
// 泛型函数
function identity<T>(arg: T): T {
  return arg;
}

// 泛型约束
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}

// 使用示例
const person = { name: 'Alice', age: 30 };
const name = getProperty(person, 'name'); // 'Alice'
```

#### 异常处理
```typescript
try {
  const result = await fetchData();
  // 处理结果
} catch (error) {
  if (error instanceof NetworkError) {
    // 网络错误处理
  } else if (error instanceof ValidationError) {
    // 验证错误处理
  } else {
    // 未知错误处理
  }
}
```

### Python

#### 上下文管理器
```python
# 使用with语句
with open('file.txt', 'r') as f:
    content = f.read()
# 自动关闭文件

# 自定义上下文管理器
from contextlib import contextmanager

@contextmanager
def timer():
    start = time.time()
    try:
        yield
    finally:
        end = time.time()
        print(f"Time: {end - start:.2f}s")

# 使用
with timer():
    # 你的代码
    pass
```

#### 装饰器
```python
# 基本装饰器
def decorator(func):
    def wrapper(*args, **kwargs):
        print(f"Calling {func.__name__}")
        return func(*args, **kwargs)
    return wrapper

@decorator
def say_hello(name):
    print(f"Hello, {name}!")

# 参数化装饰器
def decorator_with_args(arg):
    def decorator(func):
        def wrapper(*args, **kwargs):
            print(f"{arg}: {func.__name__}")
            return func(*args, **kwargs)
        return wrapper
    return decorator

@decorator_with_args("test")
def my_func():
    pass
```

#### 单例模式
```python
class Singleton:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(Singleton, cls).__new__(cls)
            cls._instance.init()
        return cls._instance

    def init(self):
        # 初始化代码
        pass

# 使用
s1 = Singleton()
s2 = Singleton()
assert s1 is s2  # True
```

### Go

#### 接口设计
```go
package main

type Reader interface {
    Read(p []byte) (n int, err error)
}

type Writer interface {
    Write(p []byte) (n int, err error)
}

type Closer interface {
    Close() error
}

type ReadWriter interface {
    Reader
    Writer
}

type File struct {
    // 文件实现
}

func (f *File) Read(p []byte) (n int, err error) {
    // 实现
}

func (f *File) Write(p []byte) (n int, err error) {
    // 实现
}
```

#### 错误处理
```go
// 返回错误而不是panic
func divide(a, b float64) (float64, error) {
    if b == 0 {
        return 0, fmt.Errorf("division by zero")
    }
    return a / b, nil
}

// 使用
result, err := divide(10, 0)
if err != nil {
    // 处理错误
    log.Fatal(err)
}
```

### Rust

#### 所有权和借用
```rust
fn main() {
    let s1 = String::from("hello");

    // 移动所有权
    let s2 = s1;
    // println!("{}", s1); // 错误！s1已失效

    // 克隆
    let s3 = s2.clone();
    println!("s1: {}, s2: {}", s1, s2);
}

// 可变引用
fn main() {
    let mut s = String::from("hello");

    // 不可变引用
    let len = calculate_length(&s);
    println!("'{}' 的长度是 {}", s, len);

    // 可变引用
    change(&mut s);
    println!("修改后的字符串: {}", s);
}

fn change(some_string: &mut String) {
    some_string.push_str(", world");
}

fn calculate_length(s: &String) -> usize {
    s.len()
}
```

## 最佳实践模板

### 代码风格
```typescript
// 使用ESLint和Prettier
// 推荐的格式

// 1. 函数命名清晰
function getUserById(id: string): User | null {
  // ...
}

// 2. 参数顺序：必需参数 → 可选参数 → 默认值
function createPerson(name: string, age?: number, city?: string) {
  // ...
}

// 3. 使用const代替let，除非必须修改
const MAX_RETRIES = 3;
let retryCount = 0;

// 4. 使用解构赋值
const { name, age } = user;

// 5. 使用可选链和空值合并
const city = user?.address?.city ?? 'Unknown';
```

### 错误处理
```typescript
// 统一错误处理
class AppError extends Error {
  constructor(
    public code: string,
    message: string,
    public statusCode: number = 500,
    public details?: any
  ) {
    super(message);
    this.name = 'AppError';
  }
}

// 使用
try {
  // 业务逻辑
} catch (error) {
  if (error instanceof AppError) {
    return res.status(error.statusCode).json({
      code: error.code,
      message: error.message,
      details: error.details
    });
  }
  // 未知错误
}
```

### 性能优化
```typescript
// 1. 使用对象池
class ObjectPool<T> {
  private pool: T[] = [];
  private factory: () => T;
  private reset: (obj: T) => void;

  constructor(factory: () => T, reset: (obj: T) => void, initialSize = 10) {
    this.factory = factory;
    this.reset = reset;
    for (let i = 0; i < initialSize; i++) {
      this.pool.push(factory());
    }
  }

  acquire(): T {
    return this.pool.pop() || this.factory();
  }

  release(obj: T) {
    this.reset(obj);
    this.pool.push(obj);
  }
}

// 2. 使用防抖
function debounce(func: Function, wait: number) {
  let timeout: NodeJS.Timeout;
  return function(...args: any[]) {
    clearTimeout(timeout);
    timeout = setTimeout(() => func.apply(this, args), wait);
  };
}

// 3. 使用节流
function throttle(func: Function, limit: number) {
  let inThrottle: boolean;
  return function(...args: any[]) {
    if (!inThrottle) {
      func.apply(this, args);
      inThrottle = true;
      setTimeout(() => inThrottle = false, limit);
    }
  };
}
```

## 使用方法

### 方式1：代码补全
当你在编写代码时，Copilot会根据上下文推荐合适的模式：

```typescript
// 输入
function

// Copilot推荐
function getUserById(id: string): Promise<User> {
  // 上下文感知的代码补全
}
```

### 方式2：重构建议
当你需要重构代码时，Copilot会识别可优化的部分：

```typescript
// Copilot建议重构
// 提取公共逻辑
// 减少代码重复
// 优化命名
```

### 方式3：错误诊断
当出现错误时，Copilot会分析并提供修复方案：

```typescript
// 错误诊断
// 分析错误原因
// 提供修复建议
// 优化错误处理
```

## 更新计划
- 每周更新20+新模式
- 收集用户反馈
- 优化现有模式
- 添加更多语言支持
