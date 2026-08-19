// logout — back to the blog, playing the boot fade in reverse: instead of the
// splash fading out to reveal the terminal, it fades back in over the top, then
// we navigate once it's covered — so leaving mirrors the fade on the way in
import { register } from './registry.js';

const FADE_MS = 450;   // a hair past the splash's 0.4s opacity transition

register({
    name: 'logout',
    describe: 'leave the terminal, back to the blog',
    execute: () => {
        const splash = document.getElementById('splash');
        const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

        // no splash to animate (or motion's off) — just go
        if (!splash || reduce) { window.location.href = '/'; return 'logging out…'; }

        const banner = splash.querySelector('#banner');
        if (banner) banner.textContent = '';   // clean fade, don't flash the ascii again
        splash.style.display = '';              // undo the display:none boot.js left it at
        void splash.offsetWidth;                // commit opacity:0 before...
        splash.classList.remove('fade-out');    // ...transitioning back to opacity 1

        setTimeout(() => { window.location.href = '/'; }, FADE_MS);
        return 'logging out…';
    },
});
