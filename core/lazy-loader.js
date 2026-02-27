/**
 * Lazy Loader for Skills
 *
 * 按需加载技能模块，避免启动时加载所有技能
 */

class SkillLazyLoader {
    constructor() {
        this.loadedSkills = new Map();
        this.unloadedSkills = new Set();
    }

    loadSkill(skillName) {
        if (this.loadedSkills.has(skillName)) {
            return this.loadedSkills.get(skillName);
        }

        try {
            const skillPath = `skills/${skillName}`;
            const skill = require(skillPath);

            this.loadedSkills.set(skillName, skill);
            console.log(`  ✓ Loading skill: ${skillName}`);
            return skill;
        } catch (error) {
            console.log(`  ✗ Failed to load skill ${skillName}: ${error.message}`);
            return null;
        }
    }

    preloadSkills(skillNames) {
        console.log(`  → Preloading ${skillNames.length} skills...`);
        skillNames.forEach(name => this.loadSkill(name));
    }

    getLoadedCount() {
        return this.loadedSkills.size;
    }

    getLoadedSkills() {
        return Array.from(this.loadedSkills.keys());
    }

    isLoaded(skillName) {
        return this.loadedSkills.has(skillName);
    }

    unloadSkill(skillName) {
        this.loadedSkills.delete(skillName);
        this.unloadedSkills.add(skillName);
    }

    clear() {
        this.loadedSkills.clear();
        this.unloadedSkills.clear();
    }
}

module.exports = SkillLazyLoader;
