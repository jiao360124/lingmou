# Testing System

class TestingSystem {
    constructor() {
        this.testSuites = new Map();
        this.testResults = new Map();
        this.testCoverage = new Map();
        this.testHistory = [];
        this.testCount = 0;
    }

    registerTestSuite(suiteName, tests) {
        this.testSuites.set(suiteName, {
            name: suiteName,
            tests,
            registered: Date.now()
        });
        console.log(\  Registered test suite: \\);
    }

    runTestSuite(suiteName) {
        const suite = this.testSuites.get(suiteName);
        if (!suite) {
            throw new Error(\Test suite not found: \\);
        }

        const results = [];

        for (const test of suite.tests) {
            const startTime = Date.now();
            const result = test();
            const duration = Date.now() - startTime;

            const testResult = {
                test: test.name,
                passed: result,
                duration,
                timestamp: Date.now()
            };

            results.push(testResult);
            this.testCount++;

            console.log(\    Test \: \ (\ms)\);
        }

        this.testResults.set(suiteName, results);

        return results;
    }

    getTestResults(suiteName) {
        return this.testResults.get(suiteName) || [];
    }

    getTestCoverage(filePath) {
        return this.testCoverage.get(filePath) || { covered: 0, total: 0 };
    }

    updateTestCoverage(filePath, covered, total) {
        this.testCoverage.set(filePath, { covered, total });
    }

    getTestStats() {
        const allResults = Array.from(this.testResults.values()).flat();
        const passed = allResults.filter(r => r.passed).length;
        const failed = allResults.filter(r => !r.passed).length;

        return {
            totalTests: this.testCount,
            passed,
            failed,
            passRate: this.testCount > 0 ? Math.round(passed / this.testCount * 100) : 0,
            testSuites: this.testSuites.size,
            testResults: this.testResults.size
        };
    }

    getTestHistory(limit = 20) {
        return this.testHistory.slice(-limit);
    }
}

module.exports = TestingSystem;
