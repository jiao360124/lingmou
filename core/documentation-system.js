# Documentation System

class DocumentationSystem {
    constructor() {
        this.documentation = new Map();
        this.apiDocs = new Map();
        this.tutorials = new Map();
        this.documentationHistory = [];
    }

    addDocumentation(docName, content, docType = 'general') {
        this.documentation.set(docName, {
            name: docName,
            content,
            type: docType,
            added: Date.now()
        });
        console.log(\  Added documentation: \\);
    }

    addAPIDocumentation(apiName, endpoint, description) {
        this.apiDocs.set(apiName, {
            endpoint,
            description,
            added: Date.now()
        });
        console.log(\  Added API doc: \\);
    }

    addTutorial(tutorialName, steps) {
        this.tutorials.set(tutorialName, {
            name: tutorialName,
            steps,
            added: Date.now()
        });
        console.log(\  Added tutorial: \\);
    }

    getDocumentation(docName) {
        return this.documentation.get(docName);
    }

    getAPIDocumentation(apiName) {
        return this.apiDocs.get(apiName);
    }

    getTutorials() {
        return Array.from(this.tutorials.values());
    }

    getDocumentationStats() {
        return {
            totalDocs: this.documentation.size,
            totalAPIDocs: this.apiDocs.size,
            totalTutorials: this.tutorials.size
        };
    }

    generateDocumentationIndex() {
        const index = {
            general: [],
            api: [],
            tutorials: []
        };

        this.documentation.forEach((doc, name) => {
            index.general.push({ name, type: doc.type });
        });

        this.apiDocs.forEach((doc, name) => {
            index.api.push({ name, endpoint: doc.endpoint });
        });

        this.tutorials.forEach((tutorial, name) => {
            index.tutorials.push({ name, steps: tutorial.steps.length });
        });

        return index;
    }
}

module.exports = DocumentationSystem;
