/**
 * API Response Cache Implementation
 *
 * 实现API响应的LRU缓存
 */

const fs = require('fs');

class APICache {
    constructor(configPath) {
        // 确保使用绝对路径
        const path = require('path');
        const fs = require('fs');

        // 尝试多个可能的配置文件路径
        const possiblePaths = [
            configPath,
            __dirname + '/api-cache-config.json',
            path.join(__dirname, '..', 'api-cache-config.json'),
            path.join(process.cwd(), 'core', 'api-cache-config.json')
        ];

        let configFilePath = null;
        for (const p of possiblePaths) {
            if (p && fs.existsSync(p)) {
                configFilePath = path.resolve(p);
                break;
            }
        }

        if (!configFilePath) {
            throw new Error('api-cache-config.json not found');
        }

        this.config = JSON.parse(fs.readFileSync(configFilePath, 'utf8'));
        this.cache = new Map();
        this.lruList = [];
        this.maxSize = this.config.cacheSize;

        // 尝试多个可能的缓存文件路径
        const cachePaths = [
            __dirname + '/api-cache.json',
            path.join(__dirname, '..', 'api-cache.json'),
            path.join(process.cwd(), 'core', 'api-cache.json')
        ];

        for (const p of cachePaths) {
            if (fs.existsSync(p)) {
                const cacheFilePath = path.resolve(p);
                const cached = JSON.parse(fs.readFileSync(cacheFilePath, 'utf8'));
                this.cache = new Map(Object.entries(cached));
                break;
            }
        }
    }

    get(key) {
        if (!this.cache.has(key)) {
            return null;
        }

        const entry = this.cache.get(key);

        // Check TTL
        if (Date.now() - entry.timestamp > entry.ttl * 1000) {
            this.delete(key);
            return null;
        }

        // Move to front (LRU)
        this.moveToFront(key);
        return entry.data;
    }

    set(key, data, ttl = null) {
        if (this.cache.size >= this.maxSize) {
            this.evictOldest();
        }

        const ttlSeconds = ttl || this.config.cacheTTL;
        this.cache.set(key, {
            data,
            timestamp: Date.now(),
            ttl: ttlSeconds
        });

        this.lruList.push(key);
        this.save();
    }

    delete(key) {
        this.cache.delete(key);
        this.lruList = this.lruList.filter(k => k !== key);
        this.save();
    }

    moveToFront(key) {
        this.lruList = this.lruList.filter(k => k !== key);
        this.lruList.push(key);
    }

    evictOldest() {
        const oldest = this.lruList.shift();
        this.cache.delete(oldest);
    }

    save() {
        const data = Object.fromEntries(this.cache);
        fs.writeFileSync('core/api-cache.json', JSON.stringify(data, null, 2));
    }

    clear() {
        this.cache.clear();
        this.lruList = [];
        this.save();
    }

    getStats() {
        return {
            size: this.cache.size,
            maxSize: this.maxSize,
            keys: Array.from(this.cache.keys())
        };
    }
}

module.exports = APICache;
