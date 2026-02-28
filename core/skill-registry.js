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

        console.log(\  Registered: \ (\)\);
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
