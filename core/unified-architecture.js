# Unified Architecture System

class UnifiedArchitecture {
    constructor() {
        this.components = new Map();
        this.dependencies = new Map();
        this.integrations = new Map();
        this.architectureLayers = ['presentation', 'business', 'data', 'infrastructure'];
    }

    registerComponent(component) {
        this.components.set(component.name, component);
        console.log(\  Registered: \ (\)\);
    }

    addDependency(componentA, componentB, relation = 'uses') {
        const key = \\->\\;
        this.dependencies.set(key, {
            from: componentA,
            to: componentB,
            relation
        });
        console.log(\  Dependency: \ -> \ (\)\);
    }

    integrateSystem(systemName, components) {
        this.integrations.set(systemName, components);
        console.log(\  Integrated: \ (\ components)\);
    }

    getArchitectureLayers() {
        return this.architectureLayers;
    }

    getComponentsByLayer(layer) {
        return Array.from(this.components.values())
            .filter(c => c.layer === layer);
    }

    getDependencyGraph() {
        return Array.from(this.dependencies.values());
    }

    getIntegrationSystems() {
        return Array.from(this.integrations.keys());
    }

    getUnifiedStats() {
        return {
            totalComponents: this.components.size,
            totalDependencies: this.dependencies.size,
            totalIntegrations: this.integrations.size,
            architectureLayers: this.architectureLayers.length
        };
    }
}

module.exports = UnifiedArchitecture;
