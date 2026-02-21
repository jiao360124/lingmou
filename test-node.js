#!/usr/bin/env node

console.log('🧪 Node.js 环境测试');
console.log('='.repeat(50));
console.log('Node 版本:', process.version);
console.log('Node 路径:', process.execPath);
console.log('当前目录:', process.cwd());
console.log('='.repeat(50));

try {
  const express = require('express');
  console.log('✅ express 模块已安装');
} catch (e) {
  console.log('❌ express 模块未安装');
  console.log('需要运行: npm install express socket.io --legacy-peer-deps');
}

try {
  const http = require('http');
  console.log('✅ http 模块已安装');
} catch (e) {
  console.log('❌ http 模块未安装');
}

try {
  const { Server } = require('socket.io');
  console.log('✅ socket.io 模块已安装');
} catch (e) {
  console.log('❌ socket.io 模块未安装');
}

console.log('='.repeat(50));
console.log('测试完成！');
