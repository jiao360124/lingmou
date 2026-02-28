# Self-Learning System

class SelfLearningSystem {
    constructor() {
        this.knowledgeBase = new Map();
        this.learningPatterns = new Map();
        this.mistakes = new Map();
        this.improvementRate = 0.0;
        this.totalLearnings = 0;
    }

    learn(concept, knowledge, importance = 1.0) {
        if (this.knowledgeBase.has(concept)) {
            const existing = this.knowledgeBase.get(concept);
            existing.knowledge = knowledge;
            existing.importance = Math.max(existing.importance, importance);
            existing.lastLearned = Date.now();
            return { updated: true, importance };
        }

        this.knowledgeBase.set(concept, {
            knowledge,
            importance,
            lastLearned: Date.now(),
            learnedCount: 1
        });

        this.totalLearnings++;
        this.updateImprovementRate();

        console.log(\  Learned: \ (importance: \)\);
        return { updated: false, importance };
    }

    retrieve(concept) {
        if (!this.knowledgeBase.has(concept)) {
            return null;
        }

        const knowledge = this.knowledgeBase.get(concept);
        knowledge.learnedCount++;
        knowledge.lastLearned = Date.now();

        return knowledge.knowledge;
    }

    getKnowledge(concept) {
        return this.knowledgeBase.get(concept);
    }

    getAllKnowledge() {
        return Array.from(this.knowledgeBase.values());
    }

    getTopKnowledge(limit = 10) {
        return Array.from(this.knowledgeBase.values())
            .sort((a, b) => b.importance - a.importance)
            .slice(0, limit);
    }

    getUnlearnedConcepts() {
        return Array.from(this.knowledgeBase.keys())
            .filter(concept => this.mistakes.has(concept));
    }

    recordMistake(concept) {
        if (!this.mistakes.has(concept)) {
            this.mistakes.set(concept, 0);
        }
        this.mistakes.set(concept, this.mistakes.get(concept) + 1);
    }

    updateImprovementRate() {
        if (this.totalLearnings > 0) {
            this.improvementRate = Math.min(1.0, this.totalLearnings / 100);
        }
    }

    getStats() {
        return {
            totalConcepts: this.knowledgeBase.size,
            totalLearnings: this.totalLearnings,
            improvementRate: Math.round(this.improvementRate * 100),
            mistakes: this.mistakes.size,
            topConcepts: this.getTopKnowledge(5).map(k => k.importance)
        };
    }

    exportKnowledge() {
        return Object.fromEntries(this.knowledgeBase);
    }

    importKnowledge(data) {
        for (const [concept, knowledge] of Object.entries(data)) {
            this.knowledgeBase.set(concept, knowledge);
        }
        this.totalLearnings = Object.keys(data).length;
    }
}

module.exports = SelfLearningSystem;
