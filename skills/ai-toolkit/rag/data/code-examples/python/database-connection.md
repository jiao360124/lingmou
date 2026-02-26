# 代码示例: Python数据库连接

## 描述
使用SQLAlchemy和psycopg2连接PostgreSQL数据库，支持连接池

## 代码
```python
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import QueuePool
import psycopg2
from psycopg2.extras import RealDictCursor

# SQLAlchemy配置
DATABASE_URL = "postgresql://user:password@localhost:5432/mydb"

engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=5,
    max_overflow=10,
    pool_pre_ping=True,
    pool_recycle=3600
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# PostgreSQL连接函数
def get_db_connection():
    """获取数据库连接"""
    try:
        conn = psycopg2.connect(
            host="localhost",
            database="mydb",
            user="user",
            password="password",
            cursor_factory=RealDictCursor
        )
        return conn
    except psycopg2.OperationalError as e:
        print(f"Database connection error: {e}")
        raise

# 带连接池的会话
def get_db():
    """获取数据库会话"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 示例模型
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    email = Column(String, unique=True, index=True)

# 初始化数据库
def init_db():
    """初始化数据库表"""
    Base.metadata.create_all(bind=engine)

# 查询示例
def get_user_by_email(email: str):
    """通过邮箱查询用户"""
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == email).first()
        return user
    finally:
        db.close()
```

## 使用
```python
# 初始化数据库
init_db()

# 创建用户
def create_user(name: str, email: str):
    db = SessionLocal()
    try:
        user = User(name=name, email=email)
        db.add(user)
        db.commit()
        db.refresh(user)
        return user
    except Exception as e:
        db.rollback()
        raise
    finally:
        db.close()

# 查询用户
user = create_user("John", "john@example.com")
print(f"User ID: {user.id}, Name: {user.name}")

# 使用会话
for db in get_db():
    users = db.query(User).all()
    for user in users:
        print(f"User: {user.name}, Email: {user.email}")
```

## 说明
- ✅ 使用连接池提高性能
- ✅ 自动垃圾回收
- ✅ 错误处理和回滚
- ✅ 支持类型提示
- ✅ 带重试的连接验证

## 最佳实践
1. 使用连接池管理数据库连接
2. 确保会话正确关闭
3. 事务回滚处理异常
4. 使用类型提示提高可读性
5. 生产环境禁用自动重连
