/**
 * Strategy Engine Optimization
 *
 * 为策略引擎添加缓存机制，避免重复编译和执行
 */

class OptimizedStrategyEngine {
    constructor() {
        this.strategyCache = new Map();
        this.executionCache = new Map();
        this.compilationCache = new Map();
    }

    async executeStrategy(strategyName, params) {
        const cacheKey = `${strategyName}:${JSON.stringify(params)}`;
        if (this.executionCache.has(cacheKey)) {
            console.log(`  ✓ Cache hit: ${strategyName}`);
            return this.executionCache.get(cacheKey);
        }

        if (!this.compilationCache.has(strategyName)) {
            console.log(`  → Compiling strategy: ${strategyName}`);
            await this.compileStrategy(strategyName);
        }

        const startTime = Date.now();
        const result = await this.executeWithTimeout(
            () => this.runCompiledStrategy(strategyName, params),
            3000
        );
        const duration = Date.now() - startTime;

        this.executionCache.set(cacheKey, result);
        this.executionCache.set(`${cacheKey}_meta`, { duration, timestamp: Date.now() });

        console.log(`  ✓ Strategy "${strategyName}" executed in ${duration}ms`);
        return result;
    }

    async compileStrategy(strategyName) {
        const strategyPath = `core/strategy/${strategyName}.js`;

        try {
            const StrategyClass = require(strategyPath);
            this.compilationCache.set(strategyName, StrategyClass);
        } catch (error) {
            console.log(`  ✗ Failed to compile strategy ${strategyName}: ${error.message}`);
            throw error;
        }
    }

    async runCompiledStrategy(strategyName, params) {
        const StrategyClass = this.compilationCache.get(strategyName);
        if (!StrategyClass) {
            throw new Error(`Strategy ${strategyName} not found`);
        }

        const strategy = new StrategyClass();
        return strategy.execute(params);
    }

    async executeWithTimeout(operation, timeout) {
        return Promise.race([
            operation(),
            new Promise((_, reject) =>
                setTimeout(() => reject(new Error(`Strategy execution timed out (${timeout}ms)`)), timeout)
            )
        ]);
    }

    clearCaches() {
        this.strategyCache.clear();
        this.executionCache.clear();
        this.compilationCache.clear();
        console.log('  ✓ All caches cleared');
    }

    getStats() {
        return {
            strategyCache: this.strategyCache.size,
            executionCache: this.executionCache.size,
            compilationCache: this.compilationCache.size
        };
    }

    getCacheSize() {
        return {
            strategy: this.strategyCache.size,
            execution: this.executionCache.size,
            compilation: this.compilationCache.size,
            total: this.strategyCache.size + this.executionCache.size + this.compilationCache.size
        };
    }
}

module.exports = OptimizedStrategyEngine;
