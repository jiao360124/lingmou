# Knowledge Transfer System

class KnowledgeTransferSystem {
    constructor(learningSystem) {
        this.learningSystem = learningSystem;
        this.transferredKnowledge = new Map();
        this.transferHistory = [];
        this.transferRate = 0.0;
    }

    transfer(sourceConcept, targetConcept, transferStrategy = 'direct') {
        const sourceKnowledge = this.learningSystem.getKnowledge(sourceConcept);

        if (!sourceKnowledge) {
            console.error(\    Source not found: \\);
            return false;
        }

        console.log(\    Transferring: \ -> \\);

        let transferredKnowledge;

        switch (transferStrategy) {
            case 'direct':
                transferredKnowledge = sourceKnowledge.knowledge;
                break;

            case 'adapt':
                transferredKnowledge = this.adaptKnowledge(sourceKnowledge.knowledge);
                break;

            case 'enhance':
                transferredKnowledge = this.enhanceKnowledge(sourceKnowledge.knowledge);
                break;

            default:
                transferredKnowledge = sourceKnowledge.knowledge;
        }

        // Transfer to target
        this.learningSystem.learn(targetConcept, transferredKnowledge, sourceKnowledge.importance);

        // Record transfer
        this.transferredKnowledge.set(targetConcept, {
            source: sourceConcept,
            strategy: transferStrategy,
            timestamp: Date.now()
        });

        this.transferHistory.push({
            source: sourceConcept,
            target: targetConcept,
            strategy: transferStrategy,
            timestamp: Date.now()
        });

        this.transferRate = Math.min(1.0, this.transferHistory.length / 50);

        console.log(\    Transfer complete\);
        return true;
    }

    adaptKnowledge(knowledge) {
        // Adapt knowledge based on context
        return {
            ...knowledge,
            adapted: true,
            adaptationDate: Date.now()
        };
    }

    enhanceKnowledge(knowledge) {
        // Enhance knowledge with additional insights
        return {
            ...knowledge,
            enhanced: true,
            enhancementDate: Date.now()
        };
    }

    getTransferredKnowledge(concept) {
        return this.transferredKnowledge.get(concept);
    }

    getTransferHistory(limit = 20) {
        return this.transferHistory.slice(-limit);
    }

    getTransferStats() {
        const byStrategy = {};

        this.transferHistory.forEach(transfer => {
            if (!byStrategy[transfer.strategy]) {
                byStrategy[transfer.strategy] = 0;
            }
            byStrategy[transfer.strategy]++;
        });

        return {
            totalTransfers: this.transferHistory.length,
            transferRate: Math.round(this.transferRate * 100),
            byStrategy
        };
    }

    autoTransfer(limit = 5) {
        const knowledge = this.learningSystem.getTopKnowledge(limit);
        const transferred = [];

        for (const item of knowledge) {
            const concept = item.importance > 0.7 ? item.importance : 'top';

            if (this.learningSystem.getKnowledge(concept)) {
                const target = this.generateTargetConcept(concept);
                if (target) {
                    this.transfer(concept, target);
                    transferred.push({ source: concept, target });
                }
            }
        }

        return transferred;
    }

    generateTargetConcept(source) {
        const targets = ['derived', 'applied', 'expanded', 'applied'];
        return targets[Math.floor(Math.random() * targets.length)];
    }

    exportTransferHistory() {
        return this.transferHistory;
    }
}

module.exports = KnowledgeTransferSystem;
