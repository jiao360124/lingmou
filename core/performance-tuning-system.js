# Performance Tuning System

class PerformanceTuningSystem {
    constructor() {
        this.performanceProfiles = new Map();
        this.tuningSessions = new Map();
        this.tuningHistory = [];
        this.tuningCount = 0;
    }

    registerPerformanceProfile(profileName, profile) {
        this.performanceProfiles.set(profileName, {
            name: profileName,
            metrics: profile,
            registered: Date.now()
        });
        console.log(\  Registered profile: \\);
    }

    tunePerformance(systemName, tuningStrategy) {
        console.log(\  Tuning: \\);

        const profile = this.performanceProfiles.get(systemName);
        if (!profile) {
            throw new Error(\Performance profile not found: \\);
        }

        const startTime = Date.now();
        const results = tuningStrategy(profile.metrics);
        const duration = Date.now() - startTime;

        // Update profile
        profile.metrics = { ...profile.metrics, ...results };
        profile.lastTuned = Date.now();

        // Record tuning session
        this.tuningSessions.set(systemName, {
            system: systemName,
            strategy: tuningStrategy.name,
            results,
            duration,
            timestamp: Date.now()
        });

        // Record in history
        this.tuningHistory.push({
            system: systemName,
            strategy: tuningStrategy.name,
            results,
            duration,
            timestamp: Date.now()
        });

        this.tuningCount++;

        console.log(\    Tuning complete in \ms\);
        return results;
    }

    getPerformanceProfile(systemName) {
        return this.performanceProfiles.get(systemName);
    }

    getTuningHistory(limit = 20) {
        return this.tuningHistory.slice(-limit);
    }

    getTuningStats() {
        return {
            totalTunings: this.tuningCount,
            totalProfiles: this.performanceProfiles.size,
            totalSessions: this.tuningSessions.size
        };
    }

    compareProfiles(profileA, profileB) {
        const metricsA = this.performanceProfiles.get(profileA)?.metrics || {};
        const metricsB = this.performanceProfiles.get(profileB)?.metrics || {};

        return {
            profileA,
            profileB,
            comparison: this.compareMetrics(metricsA, metricsB)
        };
    }

    compareMetrics(metricsA, metricsB) {
        const comparison = {};

        for (const key in metricsA) {
            comparison[key] = {
                a: metricsA[key],
                b: metricsB[key] || 0,
                diff: metricsA[key] - (metricsB[key] || 0),
                improvement: metricsB[key] ? ((metricsA[key] - metricsB[key]) / metricsB[key] * 100).toFixed(2) : null
            };
        }

        return comparison;
    }
}

module.exports = PerformanceTuningSystem;
