// help — list what's registered, straight from the live registry so it stays honest
import { register, allCommands } from './registry.js';

register({
    name: 'help',
    describe: 'list available commands',
    execute: () => {
        const cmds = allCommands().sort((a, b) => a.name.localeCompare(b.name));
        const width = Math.max(...cmds.map((c) => c.name.length));
        return cmds
            .map((c) => `  ${c.name.padEnd(width)}  ${c.describe || ''}`.trimEnd())
            .join('\n');
    },
});
