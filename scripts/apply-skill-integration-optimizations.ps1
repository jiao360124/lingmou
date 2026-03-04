# Apply Skill Integration Optimizations to OpenClaw System

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Applying Skill Integration Optimizations" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Skill Registry
Write-Host "[1/3] Creating Skill Registry" -ForegroundColor Yellow

$skillRegistry = @"
# Skill Registry - Central Skill Management

class SkillRegistry {
    constructor() {
        this.skills = new Map();
        this.categories = new Map();
        this.plugins = new Set();
    }

    register(skill) {
        this.skills.set(skill.name, skill);
        this.addCategory(skill.category, skill.name);

        if (skill.plugins) {
            skill.plugins.forEach(plugin => {
                this.plugins.add(plugin);
            });
        }

        console.log(\`  Registered: \${skill.name} (\${skill.category})\`);
    }

    addCategory(category, skillName) {
        if (!this.categories.has(category)) {
            this.categories.set(category, []);
        }
        if (!this.categories.get(category).includes(skillName)) {
            this.categories.get(category).push(skillName);
        }
    }

    get(skillName) {
        return this.skills.get(skillName);
    }

    list() {
        return Array.from(this.skills.values());
    }

    listByCategory(category) {
        return this.categories.get(category) || [];
    }

    search(keyword) {
        const results = [];
        for (const [name, skill] of this.skills) {
            if (name.toLowerCase().includes(keyword.toLowerCase()) ||
                skill.description?.toLowerCase().includes(keyword.toLowerCase())) {
                results.push(skill);
            }
        }
        return results;
    }

    getCategories() {
        return Array.from(this.categories.keys());
    }

    getStats() {
        return {
            totalSkills: this.skills.size,
            categories: this.categories.size,
            plugins: this.plugins.size
        };
    }
}

module.exports = SkillRegistry;
"@

$skillRegistryPath = "core/skill-registry.js"
$skillRegistry | Out-File -FilePath $skillRegistryPath -Encoding UTF8
Write-Host "  ✅ Created: core/skill-registry.js" -ForegroundColor Green
Write-Host ""

# 2. Skill Orchestrator
Write-Host "[2/3] Creating Skill Orchestrator" -ForegroundColor Yellow

$skillOrchestrator = @"
# Skill Orchestrator - Workflow Management

const { SkillRegistry } = require('./skill-registry');

class SkillOrchestrator {
    constructor(registry) {
        this.registry = registry;
        this.workflows = new Map();
        this.executionQueue = [];
        this.isRunning = false;
    }

    registerWorkflow(name, steps) {
        this.workflows.set(name, steps);
        console.log(\`  Registered workflow: \${name}\`);
    }

    async executeWorkflow(workflowName, input = {}) {
        const steps = this.workflows.get(workflowName);
        if (!steps) {
            throw new Error(\`Workflow not found: \${workflowName}\`);
        }

        console.log(\`  Executing workflow: \${workflowName}\`);
        let currentInput = input;

        for (const step of steps) {
            console.log(\`    Step: \${step.name} (\${step.skill})\`);

            const skill = this.registry.get(step.skill);
            if (!skill) {
                throw new Error(\`Skill not found: \${step.skill}\`);
            }

            const startTime = Date.now();

            try {
                const result = await skill.execute({
                    ...currentInput,
                    step: step.name
                });

                const duration = Date.now() - startTime;
                console.log(\`      Completed in \${duration}ms\`);

                currentInput = result;
            } catch (error) {
                console.error(\`      Failed: \${error.message}\`);
                throw error;
            }
        }

        return currentInput;
    }

    async executeParallel(workflowName, input = {}) {
        const steps = this.workflows.get(workflowName);
        if (!steps) {
            throw new Error(\`Workflow not found: \${workflowName}\`);
        }

        console.log(\`  Executing parallel workflow: \${workflowName}\`);

        const skills = steps.map(step => {
            const skill = this.registry.get(step.skill);
            if (!skill) {
                throw new Error(\`Skill not found: \${step.skill}\`);
            }
            return { skill, step };
        });

        const results = await Promise.all(
            skills.map(async ({ skill, step }) => {
                console.log(\`    Step: \${step.name} (\${step.skill})\`);
                const startTime = Date.now();

                try {
                    const result = await skill.execute({
                        ...input,
                        step: step.name
                    });

                    const duration = Date.now() - startTime;
                    console.log(\`      Completed in \${duration}ms\`);
                    return { step, result };
                } catch (error) {
                    console.error(\`      Failed: \${error.message}\`);
                    return { step, error };
                }
            })
        );

        return results;
    }

    getWorkflow(name) {
        return this.workflows.get(name);
    }

    listWorkflows() {
        return Array.from(this.workflows.keys());
    }

    getStats() {
        return {
            workflows: this.workflows.size,
            totalSteps: Array.from(this.workflows.values())
                .reduce((sum, steps) => sum + steps.length, 0)
        };
    }
}

module.exports = SkillOrchestrator;
"@

$skillOrchestratorPath = "core/skill-orchestrator.js"
$skillOrchestrator | Out-File -FilePath $skillOrchestratorPath -Encoding UTF8
Write-Host "  ✅ Created: core/skill-orchestrator.js" -ForegroundColor Green
Write-Host ""

# 3. Skill Bus
Write-Host "[3/3] Creating Skill Bus" -ForegroundColor Yellow

$skillBus = @"
# Skill Bus - Cross-Skill Communication

class SkillBus {
    constructor() {
        this.subscribers = new Map();
        this.publishers = new Set();
        this.eventHistory = [];
        this.maxHistory = 100;
    }

    subscribe(event, callback) {
        if (!this.subscribers.has(event)) {
            this.subscribers.set(event, []);
        }
        this.subscribers.get(event).push(callback);
        this.publishers.add(callback);
        console.log(\`  Subscribed to: \${event}\`);
    }

    unsubscribe(event, callback) {
        if (this.subscribers.has(event)) {
            const callbacks = this.subscribers.get(event);
            const index = callbacks.indexOf(callback);
            if (index > -1) {
                callbacks.splice(index, 1);
                this.publishers.delete(callback);
            }
        }
    }

    publish(event, data) {
        if (!this.subscribers.has(event)) {
            console.log(\`  No subscribers for: \${event}\`);
            return;
        }

        console.log(\`  Published: \${event}\`);

        const callbacks = this.subscribers.get(event);
        const results = [];

        for (const callback of callbacks) {
            try {
                const result = callback(data);
                results.push({ callback, result });
            } catch (error) {
                console.error(\`    Error in subscriber: \${error.message}\`);
                results.push({ callback, error });
            }
        }

        // Store in history
        this.eventHistory.push({
            event,
            data,
            timestamp: Date.now(),
            results: results.length
        });

        if (this.eventHistory.length > this.maxHistory) {
            this.eventHistory.shift();
        }

        return results;
    }

    on(event, callback) {
        return this.subscribe(event, callback);
    }

    off(event, callback) {
        return this.unsubscribe(event, callback);
    }

    getSubscribers(event) {
        return this.subscribers.get(event) || [];
    }

    getHistory(event = null, limit = 10) {
        let history = this.eventHistory;

        if (event) {
            history = history.filter(h => h.event === event);
        }

        return history.slice(-limit);
    }

    getStats() {
        return {
            events: this.subscribers.size,
            subscribers: Array.from(this.subscribers.values())
                .reduce((sum, arr) => sum + arr.length, 0),
            publishers: this.publishers.size,
            historySize: this.eventHistory.length
        };
    }

    clearHistory() {
        this.eventHistory = [];
    }
}

module.exports = SkillBus;
"@

$skillBusPath = "core/skill-bus.js"
$skillBus | Out-File -FilePath $skillBusPath -Encoding UTF8
Write-Host "  ✅ Created: core/skill-bus.js" -ForegroundColor Green
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Skill Integration Optimizations Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Implemented 3 integration systems:" -ForegroundColor Green
Write-Host "  1. Skill Registry - Central skill management"
Write-Host "  2. Skill Orchestrator - Workflow management"
Write-Host "  3. Skill Bus - Cross-skill communication"
Write-Host ""
Write-Host "Files created:" -ForegroundColor Yellow
Write-Host "  - core/skill-registry.js"
Write-Host "  - core/skill-orchestrator.js"
Write-Host "  - core/skill-bus.js"
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Skill Integration Optimizations Applied!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
