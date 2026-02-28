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
        console.log(\  Subscribed to: \\);
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
            console.log(\  No subscribers for: \\);
            return;
        }

        console.log(\  Published: \\);

        const callbacks = this.subscribers.get(event);
        const results = [];

        for (const callback of callbacks) {
            try {
                const result = callback(data);
                results.push({ callback, result });
            } catch (error) {
                console.error(\    Error in subscriber: \\);
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
