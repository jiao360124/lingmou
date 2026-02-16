// debug-config.js - 调试配置加载器

const fs = require('fs').promises;
const path = require('path');

async function debugConfig() {
  console.log('🔍 调试配置加载器...\n');

  try {
    // 1. 读取配置文件
    const configPath = path.join(__dirname, 'config.json');
    const configData = await fs.readFile(configPath, 'utf-8');
    const config = JSON.parse(configData);

    console.log('📋 配置文件内容:');
    console.log(JSON.stringify(config, null, 2));
    console.log('\n');

    // 2. 读取 Schema
    const schemaPath = path.join(__dirname, 'config-schema.json');
    const schemaData = await fs.readFile(schemaPath, 'utf-8');
    const schema = JSON.parse(schemaData);

    console.log('📋 Schema 内容:');
    console.log(JSON.stringify(schema, null, 2));
    console.log('\n');

    // 3. 检查配置项
    console.log('📋 检查配置项:');
    for (const [key, value] of Object.entries(config)) {
      console.log(`   ${key}: ${value} (${typeof value})`);
    }
    console.log('\n');

    // 4. 检查必需字段
    console.log('📋 检查必需字段:');
    for (const [key, schemaItem] of Object.entries(schema)) {
      if (schemaItem.required) {
        const value = config[key];
        console.log(`   ${key}: ${value} (${typeof value})`);
      }
    }
    console.log('\n');

    // 5. 检查缺失字段
    console.log('📋 检查缺失字段:');
    for (const [key, schemaItem] of Object.entries(schema)) {
      if (schemaItem.required) {
        const value = config[key];
        if (value === undefined) {
          console.log(`   ⚠️  ${key}: 缺失`);
        } else {
          console.log(`   ✅ ${key}: ${value}`);
        }
      }
    }
    console.log('\n');

  } catch (err) {
    console.error('❌ 调试失败:', err.message);
    process.exit(1);
  }
}

// 运行调试
debugConfig();
