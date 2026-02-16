# OpenClaw 报告系统配置示例

## 环境变量配置

### Telegram 报告发送

```bash
# 在系统环境变量中设置
export TELEGRAM_TOKEN="your_telegram_bot_token"
export TELEGRAM_CHAT_ID="your_telegram_chat_id"
```

**获取 Token 和 Chat ID**:
1. 在 Telegram 中搜索 `@BotFather`
2. 发送 `/newbot` 创建机器人
3. 获取 Token
4. 给机器人发送一条消息，然后使用 `@userinfobot` 获取 Chat ID

---

### 邮件报告发送

```bash
# 在系统环境变量中设置
export EMAIL_FROM="sender@example.com"
export EMAIL_TO="recipient@example.com"
export EMAIL_SMTP_HOST="smtp.example.com"
export EMAIL_SMTP_PORT="587"
export EMAIL_SMTP_USER="sender@example.com"
export EMAIL_SMTP_PASSWORD="your_password"
```

**需要安装 nodemailer**:
```bash
npm install nodemailer
```

---

## 配置文件示例 (report-config.json)

```json
{
  "senderType": "telegram",
  "telegramToken": "your_telegram_bot_token",
  "telegramChatId": "your_telegram_chat_id",
  "emailConfig": {
    "from": "sender@example.com",
    "to": "recipient@example.com",
    "smtpHost": "smtp.example.com",
    "smtpPort": 587,
    "smtpUser": "sender@example.com",
    "smtpPassword": "your_password"
  },
  "retryCount": 3,
  "retryDelay": 5000
}
```

---

## 使用示例

### 在代码中使用

```javascript
const ReportGenerator = require('./report-generator');
const ReportSender = require('./report-sender');

// 1. 生成报告
const generator = new ReportGenerator({
  outputDir: 'reports'
});
const report = await generator.generateDailyReport();

// 2. 发送报告
const sender = new ReportSender({
  senderType: 'telegram',
  telegramToken: process.env.TELEGRAM_TOKEN,
  telegramChatId: process.env.TELEGRAM_CHAT_ID,
  retryCount: 3
});

// 发送到 Telegram
const result = await sender.sendReport(report.file, {
  reportType: 'daily'
});

if (result.success) {
  console.log('✅ 报告发送成功');
} else {
  console.log('❌ 报告发送失败:', result.error);
}
```

---

## 定时任务配置（推荐）

### Windows 任务计划程序

**每日报告**（凌晨 2:00）:
- **触发器**: 每天上午 2:00
- **操作**: 启动程序 `node`
- **参数**: `openclaw-3.0/report-sender.js`
- **工作目录**: `C:\Users\Administrator\.openclaw\workspace\openclaw-3.0`
- **运行方式**: 以当前用户身份

**每周报告**（周日凌晨 3:00）:
- **触发器**: 每周日凌晨 3:00
- **操作**: 启动程序 `node`
- **参数**: `openclaw-3.0/send-weekly-reports.js`
- **工作目录**: `C:\Users\Administrator\.openclaw\workspace\openclaw-3.0`
- **运行方式**: 以当前用户身份

---

## 命令行工具

### 手动生成并发送报告

```bash
# 生成并立即发送报告
node openclaw-3.0/test-report-sender.js

# 使用配置文件发送
node openclaw-3.0/send-report.js --report-type daily
node openclaw-3.0/send-report.js --report-type weekly
```

---

## 故障排查

### Telegram 发送失败

**常见原因**:
1. Token 不正确
2. Chat ID 不正确
3. Bot 被封禁
4. 网络问题

**解决方法**:
1. 验证 Token: `curl https://api.telegram.org/bot<token>/getMe`
2. 验证 Chat ID: 使用 @userinfobot
3. 检查网络连接
4. 重新启动 Bot

### 邮件发送失败

**常见原因**:
1. SMTP 配置错误
2. 密码错误
3. SMTP 服务器不支持
4. 邮箱被反垃圾系统拦截

**解决方法**:
1. 验证 SMTP 配置
2. 使用应用密码（不是登录密码）
3. 尝试使用 `smtp.gmail.com:587`
4. 检查邮箱垃圾箱

---

## 发送历史管理

### 保存和加载历史

```javascript
const sender = new ReportSender();

// 加载历史
await sender.loadHistory('reports/sender-history.json');

// 保存历史
await sender.saveHistory('reports/sender-history.json');

// 获取统计
const stats = sender.getStats();
console.log(stats);

// 重新发送失败的报告
const retryResults = await sender.retryFailed(10);
```

### 查看历史记录

```json
[
  {
    "success": true,
    "method": "telegram",
    "messageId": 123456,
    "chatId": "your_chat_id",
    "timestamp": "2026-02-16T02:00:00.000Z",
    "reportType": "daily"
  },
  {
    "success": false,
    "method": "email",
    "error": "SMTP connection failed",
    "timestamp": "2026-02-16T02:00:00.000Z",
    "reportType": "weekly"
  }
]
```

---

**注意**: 在生产环境使用前，请确保妥善保管敏感信息（Token、密码等）
