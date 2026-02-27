/**
 * Async I/O Operations for Gateway
 *
 * 提供高性能的异步文件操作
 */

const { promisify } = require('util');
const fs = promisify(require('fs').exists);
const fsWrite = promisify(require('fs').writeFile);
const fsRead = promisify(require('fs').readFile);

class AsyncIO {
    constructor() {
        this.queue = [];
        this.active = false;
    }

    async readFileAsync(filePath) {
        if (await fs(filePath)) {
            return await fsRead(filePath, 'utf8');
        }
        return null;
    }

    async writeFileAsync(filePath, content, options = {}) {
        return await fsWrite(filePath, content, options);
    }

    async executeAsync(operation, timeout = 5000) {
        return Promise.race([
            operation(),
            new Promise((_, reject) =>
                setTimeout(() => reject(new Error('Timeout')), timeout)
            )
        ]);
    }

    async batchExecute(operations, concurrency = 5) {
        const results = [];
        for (let i = 0; i < operations.length; i += concurrency) {
            const batch = operations.slice(i, i + concurrency);
            const batchResults = await Promise.all(batch);
            results.push(...batchResults);
        }
        return results;
    }

    async timeoutPromise(promise, timeout, errorMessage = 'Operation timed out') {
        return Promise.race([
            promise,
            new Promise((_, reject) =>
                setTimeout(() => reject(new Error(errorMessage)), timeout)
            )
        ]);
    }
}

module.exports = AsyncIO;
