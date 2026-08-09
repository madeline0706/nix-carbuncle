// Splash screen: renders the banner (loaded from content/) and sweeps a
// metallic sheen across it, then fades out into the terminal.

import { wait, loadText } from './util.js';

export class Splash {
    constructor() {
        this.el = document.getElementById('splash');
        this.banner = document.getElementById('banner');
    }

    async show(durationMs) {
        const art = await loadText('content/banner.txt');
        if (art) this.banner.textContent = art;
        await wait(durationMs);
    }

    async hide() {
        this.el.classList.add('fade-out');
        await wait(400);
        this.el.style.display = 'none';
    }
}
