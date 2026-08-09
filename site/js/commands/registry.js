// Command registry — the plugin surface of the terminal.
//
// A command is a plain object: { name, desc, execute(args, ctx) }.
//   - name:    the word typed at the prompt.
//   - desc:    one-line description (for a future `help`).
//   - execute: (argString, ctx) => string | Element | Promise<…> | null.
//
// To add a command, create a module in ./commands/ that calls `register(...)`,
// then import it from ./commands/index.js. Nothing else needs to change.

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
