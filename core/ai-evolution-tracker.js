# AI Evolution Tracker

class AIEvolutionTracker {
    constructor() {
        this.evolutionStages = new Map();
        this.currentStage = 'learning';
        this.evolutionHistory = [];
        this.stageTransitions = 0;
        this.evolutionLevel = 1;
    }

    setStage(stage) {
        if (this.evolutionStages.has(stage)) {
            console.log(\  Stage changed: \ -> \\);
            this.evolutionStages.set(this.currentStage, {
                entered: Date.now(),
                duration: Date.now() - this.evolutionStages.get(this.currentStage).entered
            });

            this.currentStage = stage;
            this.stageTransitions++;
            this.evolutionLevel++;

            this.evolutionHistory.push({
                stage: this.currentStage,
                level: this.evolutionLevel,
                timestamp: Date.now()
            });

            return true;
        }

        console.log(\  Stage not found: \\);
        return false;
    }

    getCurrentStage() {
        return this.currentStage;
    }

    getEvolutionLevel() {
        return this.evolutionLevel;
    }

    getEvolutionHistory(limit = 20) {
        return this.evolutionHistory.slice(-limit);
    }

    getStageStats() {
        const stats = {};

        for (const [stage, data] of this.evolutionStages) {
            stats[stage] = {
                entered: data.entered,
                duration: data.duration,
                durationMinutes: Math.round(data.duration / 60000)
            };
        }

        return stats;
    }

    getOverallProgress() {
        const stages = ['learning', 'practicing', 'mastering', 'innovating'];
        const current = this.stages.indexOf(this.currentStage);

        return {
            currentStageIndex: current,
            totalStages: stages.length,
            progress: Math.round((current / (stages.length - 1)) * 100),
            level: this.evolutionLevel
        };
    }

    autoEvolve() {
        const progress = this.getOverallProgress();

        if (progress.progress >= 100) {
            this.setStage('innovating');
        } else if (progress.progress >= 75) {
            this.setStage('mastering');
        } else if (progress.progress >= 50) {
            this.setStage('practicing');
        } else {
            this.setStage('learning');
        }
    }

    exportEvolutionHistory() {
        return this.evolutionHistory;
    }

    reset() {
        this.currentStage = 'learning';
        this.stageTransitions = 0;
        this.evolutionLevel = 1;
        this.evolutionHistory = [];
        this.evolutionStages.clear();
        console.log(\  Evolution reset\);
    }
}

module.exports = AIEvolutionTracker;
