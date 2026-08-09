import { loadJson, loadText } from './util.js';
import { Splash } from './splash.js';
import { Terminal } from './terminal.js';
import { Dungeon } from './dungeon.js';
import './commands/index.js';

const DEFAULTS = {
    username: 'guest',
    prompt: '{user}@spellbound:~#',
    splashDurationMs: 1800,
};

async function main() {
    const config = { ...DEFAULTS, ...(await loadJson('content/config.json')) };

    const splash = new Splash();
    await splash.show(config.splashDurationMs);
    await splash.hide();

    new Terminal(config);

    const room = await loadText('content/room.txt');
    if (room) new Dungeon('dungeon', room);
}

window.addEventListener('DOMContentLoaded', () => {
    main().catch((err) => {
        console.error('boot error:', err);
        new Terminal(DEFAULTS);
    });
});
