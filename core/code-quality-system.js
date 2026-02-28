# Code Quality System

class CodeQualitySystem {
    constructor() {
        this.codebase = new Map();
        this.qualityMetrics = new Map();
        this.qualityRules = new Map();
        this.issues = new Map();
    }

    analyzeFile(filePath, code) {
        const issues = [];

        // Check for common issues
        if (code.length > 10000) {
            issues.push({ type: 'size', message: 'File too large', severity: 'warning' });
        }

        // Check for TODO comments
        if (code.match(/TODO|FIXME|XXX/i)) {
            issues.push({ type: 'comment', message: 'TODO/FIXME comments found', severity: 'info' });
        }

        // Check for console.log statements (except in development)
        if (code.match(/console\.log/i) && !code.includes('// production')) {
            issues.push({ type: 'debug', message: 'Console.log statements found', severity: 'warning' });
        }

        // Check for duplicate code patterns
        const duplicates = this.findDuplicatePatterns(code);
        if (duplicates.length > 3) {
            issues.push({ type: 'duplication', message: 'High code duplication', severity: 'error' });
        }

        this.codebase.set(filePath, {
            code,
            issues,
            analyzed: Date.now()
        });

        return issues;
    }

    findDuplicatePatterns(code) {
        // Simple pattern matching for duplicates
        const patterns = code.match(/(function|const|let|var)\s+\w+/g) || [];
        return patterns;
    }

    calculateQualityScore(filePath) {
        const file = this.codebase.get(filePath);
        if (!file) return 0;

        let score = 100;
        file.issues.forEach(issue => {
            if (issue.severity === 'error') score -= 20;
            else if (issue.severity === 'warning') score -= 10;
            else if (issue.severity === 'info') score -= 5;
        });

        return Math.max(0, score);
    }

    getQualityMetrics() {
        return Array.from(this.codebase.values()).map(file => ({
            file: file.codebase.get(filePath),
            score: this.calculateQualityScore(filePath),
            issues: file.issues.length
        }));
    }

    getIssuesBySeverity(severity) {
        const issues = [];

        this.codebase.forEach((file, filePath) => {
            file.issues.forEach(issue => {
                if (issue.severity === severity) {
                    issues.push({ filePath, ...issue });
                }
            });
        });

        return issues;
    }

    getOverallQuality() {
        const files = Array.from(this.codebase.keys());
        const totalScore = files.reduce((sum, file) => sum + this.calculateQualityScore(file), 0);
        return Math.round(totalScore / files.length);
    }

    getQualityStats() {
        return {
            totalFiles: this.codebase.size,
            avgQuality: this.getOverallQuality(),
            totalIssues: Array.from(this.codebase.values())
                .reduce((sum, file) => sum + file.issues.length, 0)
        };
    }
}

module.exports = CodeQualitySystem;
