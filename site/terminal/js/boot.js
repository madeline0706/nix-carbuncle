import { loadJson } from './util.js';
import { Splash } from './splash.js';
import { Terminal } from './terminal.js';
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

    document.documentElement.classList.add('booted');   // fade the bg to near-black
    new Terminal(config);
}

window.addEventListener('DOMContentLoaded', () => {
    main().catch((err) => {
        console.error('boot error:', err);
        new Terminal(DEFAULTS);
    });
});
