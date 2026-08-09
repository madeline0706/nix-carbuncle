// Entry point: load config, register commands, run the splash, hand off to the
// terminal. Wired together from small modules so each piece stays swappable.

import { loadJson } from './util.js';
import { Splash } from './splash.js';
import { Terminal } from './terminal.js';
import './commands/index.js'; // registers whatever commands are enabled

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
}

window.addEventListener('DOMContentLoaded', () => {
    main().catch((err) => {
        console.error('boot error:', err);
        new Terminal(DEFAULTS);
    });
});
