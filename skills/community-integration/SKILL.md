# 社区集成技能

## 概述
集成Moltbook社区，建立最佳实践库，提供社区协作接口。

## 核心模块

### 1. Moltbook集成
- 账号连接
- 内容同步
- 讨论参与
- 学习分享

### 2. 最佳实践库
- 本地最佳实践
- 社区最佳实践
- 实践验证
- 实践更新

### 3. 社区协作接口
- 问题报告
- 功能请求
- 贡献指南
- 反馈循环

## 使用示例

### Moltbook集成
```powershell
.\moltbook-integration.ps1 -SyncCommunity
.\moltbook-integration.ps1 -JoinDiscussion -Topic "performance-optimization"
```

### 最佳实践库
```powershell
.\best-practices.ps1 -Add -Practice $practice
.\best-practices.ps1 -Search -Query "optimization"
```

### 社区协作
```powershell
.\community-collaboration.ps1 -ReportIssue -Issue $issue
.\community-collaboration.ps1 -SubmitFeature -Request $request
```

## 文件结构
```
skills/community-integration/
├── SKILL.md
├── scripts/
│   ├── moltbook-integration.ps1
│   ├── best-practices.ps1
│   └── community-collaboration.ps1
└── data/
    ├── best-practices.json
    └── community-sessions.json
```
