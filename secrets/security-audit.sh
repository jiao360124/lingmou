#!/bin/bash
# 安全审计脚本 - 检测潜在的敏感信息泄露

echo "🔍 OpenClaw 安全审计"
echo "=====================\n"

echo "📋 检测 API Keys..."

# 检测常见的 API Key 模式
echo "检查 OpenRouter API Keys..."
find . -type f \( -name "*.js" -o -name "*.json" -o -name "*.py" -o -name "*.sh" -o -name "*.env*" \) \
  -exec grep -l "sk-or-v1" {} \; 2>/dev/null || echo "✅ 未找到 sk-or-v1"

echo "检查 OpenAI API Keys..."
find . -type f \( -name "*.js" -o -name "*.json" -o -name "*.py" -o -name "*.sh" -o -name "*.env*" \) \
  -exec grep -l "sk-proj-" {} \; 2>/dev/null || echo "✅ 未找到 sk-proj-"

echo "检查数据源密码..."
find . -type f \( -name "*.js" -o -name "*.json" -o -name "*.sh" -o -name "*.env*" \) \
  -exec grep -l "password.*=" {} \; 2>/dev/null || echo "✅ 未找到数据源密码"

echo "\n📋 检测 .env 文件..."
find . -name ".env" -o -name ".env.*" | grep -v ".git" || echo "✅ 未找到 .env 文件"

echo "\n📋 检测包含 secrets 的目录..."
find . -type d -name "*secret*" -o -name "*api_key*" -o -name "*credential*" | grep -v ".git" || echo "✅ 未发现敏感目录"

echo "\n📋 检查 Git 配置..."
if grep -q "secrets/" .gitignore 2>/dev/null; then
  echo "✅ .gitignore 包含 secrets/"
else
  echo "❌ .gitignore 未包含 secrets/"
fi

if grep -q "api_keys/" .gitignore 2>/dev/null; then
  echo "✅ .gitignore 包含 api_keys/"
else
  echo "❌ .gitignore 未包含 api_keys/"
fi

echo "\n🎉 安全审计完成"
