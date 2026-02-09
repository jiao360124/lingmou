# 技能清理报告

生成时间: 2026-02-09 09:49

## 技能统计

### 当前技能状态
- **Workspace技能**: 50个
- **NPM官方技能**: 52个
- **重复技能**: 8个

## 重复技能分析

### 两个目录都存在的技能（8个）
- discord
- gemini
- github
- healthcheck
- sag
- slack
- summarize
- weather

### 建议处理方案
1. **保留NPM版本**（官方维护）
2. **移除workspace版本**（避免重复和版本冲突）

## Workspace独有技能（42个）
这些技能仅在workspace目录中存在，需要评估是否需要：

### 开发工具类
- agent-browser
- api-dev
- browse
- browser-cash
- code-mentor
- database
- debug-pro
- docker-essentials
- exa-web-search-free
- fd-find
- ffmpeg-cli
- git-crypt-backup
- git-essentials
- github-action-gen
- github-pr
- git-sync
- jq
- nextjs-expert
- ripgrep
- sql-toolkit
- webapp-testing

### 项目管理类
- clawlist
- conventional-commits
- file-organizer
- file-search
- openclaw-self-backup
- task-status
- test-runner

### 特殊功能类
- agentguard
- coolify
- decision-trees
- deepwiki
- deepwork-tracker
- fail2ban-reporter
- get-tldr
- kesslerio-stealth-browser
- notion-cli
- skill-vetter
- smtp-send
- technews
- whatsapp-styling-guide

### 其他
- gpt

## NPM独有技能（44个）
这些技能仅在NPM包中存在，主要是官方技能：

### 通用工具
- 1password
- canvas
- mcporter
- model-usage
- skill-creator
- session-logs

### 移动设备集成
- apple-notes
- apple-reminders
- bear-notes
- bluebubbles
- imsg

### 媒体和娱乐
- blogwatcher
- food-order
- gifgrep
- gog
- peekaboo
- songsee
- sonoscli
- spotify-player
- things-mac
- trello
- video-frames
- voice-call

### 专业工具
- eightctl
- goplaces
- himalaya
- local-places
- nano-banana-pro
- nano-pdf
- notion
- obsidian
- openai-image-gen
- openai-whisper
- openai-whisper-api
- openhue
- oracle
- ordercli
- sherpa-onnx-tts
- tmux
- wacli

## 建议的清理步骤

### 第一步：移除重复技能
移除workspace目录中的以下技能，保留NPM版本：
- discord
- gemini
- github
- healthcheck
- sag
- slack
- summarize
- weather

### 第二步：评估workspace独有技能
需要用户确认是否保留以下类型的技能：
1. 开发工具类（如agent-browser, api-dev等）
2. 项目管理类（如clawlist, conventional-commits等）
3. 特殊功能类（如deepwiki, decision-trees等）

### 第三步：检查技能完整性
确保所有SKILL.md文件都存在且格式正确。

## 风险评估
- **低风险**：移除重复技能
- **中风险**：移除workspace独有技能
- **建议**：先移除重复技能，然后询问用户是否需要其他workspace技能

## 下一步操作
1. 执行重复技能清理
2. 询问用户对workspace独有技能的处理意见
3. 验证清理后的技能系统状态