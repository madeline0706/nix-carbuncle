const registry = new Map();

export function register(command) {
    if (!command || !command.name) throw new Error('command needs a name');
    registry.set(command.name, command);
}

export function getCommand(name) {
    return registry.get(name);
}

export function allCommands() {
    return [...registry.values()];
}
