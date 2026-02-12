# Copilot代码示例

## 概述
本目录包含使用Copilot智能代码助手的示例代码和最佳实践。

## 1. 代码重构示例

### 示例1: 提取公共方法
**问题代码**:
```typescript
function calculateArea(width: number, height: number): number {
  return width * height;
}

function calculatePerimeter(width: number, height: number): number {
  return 2 * (width + height);
}

function calculateVolume(width: number, height: number, depth: number): number {
  return width * height * depth;
}
```

**Copilot重构后**:
```typescript
function calculateArea(width: number, height: number): number {
  return width * height;
}

function calculatePerimeter(width: number, height: number): number {
  return 2 * (width + height);
}

function calculateVolume(width: number, height: number, depth: number): number {
  return width * height * depth;
}

// Copilot建议：提取公共计算逻辑
function calculateSurface(width: number, height: number, depth: number) {
  const area = width * height;
  const perimeter = 2 * (width + height);
  const volume = area * depth;
  return { area, perimeter, volume };
}
```

### 示例2: 消除重复代码
**问题代码**:
```typescript
function createUser(name: string, age: number) {
  console.log(`创建用户: ${name}, 年龄: ${age}`);
  // 其他创建逻辑
}

function createProduct(name: string, price: number) {
  console.log(`创建产品: ${name}, 价格: ${price}`);
  // 其他创建逻辑
}

function createOrder(customerId: string, orderId: string) {
  console.log(`创建订单: ${orderId}, 客户: ${customerId}`);
  // 其他创建逻辑
}
```

**Copilot重构后**:
```typescript
type EntityType = 'user' | 'product' | 'order';

function createEntity(type: EntityType, name: string, value: number | string) {
  console.log(`创建${type}: ${name}, ${value}`);
  // 公共创建逻辑
}

// 使用
createEntity('user', 'Alice', 25);
createEntity('product', 'Laptop', 999);
createEntity('order', 'ORD001', 'CUST123');
```

## 2. 性能优化示例

### 示例3: 优化循环
**优化前**:
```typescript
const users = getUsers();
let adminCount = 0;

for (let i = 0; i < users.length; i++) {
  if (users[i].role === 'admin') {
    adminCount++;
  }
}
```

**Copilot优化后**:
```typescript
const users = getUsers();
const adminCount = users.filter(user => user.role === 'admin').length;

// 或者使用reduce
const adminCount = users.reduce((count, user) =>
  user.role === 'admin' ? count + 1 : count, 0
);
```

### 示例4: 优化数据结构
**优化前**:
```typescript
function findUserById(users: User[], id: string): User | undefined {
  for (const user of users) {
    if (user.id === id) {
      return user;
    }
  }
  return undefined;
}

// 性能：O(n)
```

**Copilot优化后**:
```typescript
// 如果经常查询，使用Map
const userMap = new Map(users.map(user => [user.id, user]));

function findUserById(users: User[], id: string): User | undefined {
  return userMap.get(id);
}

// 性能：O(1)
```

## 3. 错误处理示例

### 示例5: 统一错误处理
**优化前**:
```typescript
async function fetchData(url: string) {
  try {
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    console.error('获取数据失败:', error);
    return null;
  }
}
```

**Copilot优化后**:
```typescript
class ApiError extends Error {
  constructor(
    public statusCode: number,
    message: string,
    public details?: any
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

async function fetchData(url: string): Promise<any> {
  try {
    const response = await fetch(url);
    if (!response.ok) {
      throw new ApiError(
        response.status,
        `HTTP error! status: ${response.status}`,
        await response.json()
      );
    }
    return await response.json();
  } catch (error) {
    if (error instanceof ApiError) {
      console.error('API错误:', error.message, error.details);
      throw error;
    }
    console.error('未知错误:', error);
    throw new ApiError(500, '未知错误发生');
  }
}
```

## 4. React示例

### 示例6: 自定义Hook
**Copilot建议**:
```typescript
// 自定义Hook：使用窗口大小
function useWindowSize() {
  const [size, setSize] = useState([window.innerWidth, window.innerHeight]);

  useEffect(() => {
    const handleResize = () => setSize([window.innerWidth, window.innerHeight]);
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  return size;
}

// 使用
function MyComponent() {
  const [width, height] = useWindowSize();
  return <div>窗口大小: {width} x {height}</div>;
}
```

### 示例7: 性能优化
**优化前**:
```typescript
function ProductList({ products }) {
  return (
    <div>
      {products.map(product => (
        <ProductCard key={product.id} product={product} />
      ))}
    </div>
  );
}

// 每次父组件更新，所有ProductCard都会重新渲染
```

**Copilot优化后**:
```typescript
function ProductList({ products }) {
  // 使用React.memo优化
  const MemoizedProductCard = React.memo(ProductCard);

  return (
    <div>
      {products.map(product => (
        <MemoizedProductCard key={product.id} product={product} />
      ))}
    </div>
  );
}
```

## 5. Python示例

### 示例8: 上下文管理器
```python
# 使用with语句自动关闭文件
with open('data.txt', 'r') as f:
    content = f.read()

# 或者自定义上下文管理器
from contextlib import contextmanager

@contextmanager
def timer():
    start = time.time()
    try:
        yield
    finally:
        end = time.time()
        print(f"执行时间: {end - start:.2f}s")

# 使用
with timer():
    # 你的代码
    process_data()
```

### 示例9: 装饰器
```python
from functools import wraps

def log_execution(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        print(f"执行函数: {func.__name__}")
        result = func(*args, **kwargs)
        print(f"函数完成: {func.__name__}")
        return result
    return wrapper

# 使用
@log_execution
def calculate_sum(a, b):
    return a + b
```

## 使用Copilot的技巧

### 1. 提供清晰上下文
```
❌ 不好的提示：
"优化这段代码"

✅ 好的提示：
"优化这段React组件，使用React.memo减少不必要的渲染，
并添加性能监控日志"
```

### 2. 说明期望输出
```
❌ 不好的提示：
"帮我重构这个函数"

✅ 好的提示：
"帮我重构这个函数：
1. 提取公共逻辑到单独的函数
2. 使用更清晰的变量名
3. 添加详细的注释
4. 返回优化后的代码"
```

### 3. 提供示例参考
```
❌ 不好的提示：
"用Rust写这个"

✅ 好的提示：
"用Rust重写这个JavaScript函数，使用Option和Result类型处理可能的错误，
参考以下风格：
fn divide(a: i32, b: i32) -> Option<i32> {
    if b == 0 {
        None
    } else {
        Some(a / b)
    }
}"
```

## 最佳实践

1. **迭代优化**: 先实现基本功能，然后逐步优化
2. **保留注释**: 重要的优化决策应该有注释说明
3. **性能测试**: 每次优化后都要进行性能测试
4. **代码审查**: 让Copilot审查优化后的代码
5. **持续学习**: 学习Copilot提供的最佳实践建议

## 更多示例

查看其他目录获取更多示例：
- `/api-examples/` - API使用示例
- `/database-examples/` - 数据库操作示例
- `/testing-examples/` - 测试用例示例
