// The terminal: prompt, input loop, and command dispatch. Commands themselves
// live in ./commands/ and are looked up through the registry — the terminal has
// no built-in commands of its own.

import { getCommand } from './commands/registry.js';

export class Terminal {
    constructor(config = {}) {
        this.username = config.username || 'guest';
        this.promptTemplate = config.prompt || '{user}@spellbound:~#';
        this.el = document.getElementById('terminal');
        this.addInputLine();
    }

    getPromptString() {
        return this.promptTemplate.replace('{user}', this.username);
    }

    addInputLine() {
        this.el.querySelectorAll('.live-input').forEach((e) => e.remove());
        const line = document.createElement('div');
        line.className = 'input-line live-input';
        line.innerHTML =
            `<span class="prompt-sign">${this.getPromptString()}</span>` +
            `<input type="text" class="command-input" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false">`;
        this.el.appendChild(line);
        this.input = line.querySelector('input');
        this.input.addEventListener('keydown', (e) => this.onKey(e));
        this.el.addEventListener('click', (e) => { if (e.target === this.el) this.input.focus(); });
        this.input.focus();
        this.scrollBottom();
    }

    onKey(e) {
        if (e.key === 'Enter') {
            e.preventDefault();
            this.run(this.input.value.trim());
        }
    }

    run(cmd) {
        const live = this.el.querySelector('.live-input');
        if (live) {
            live.classList.remove('live-input');
            const inp = live.querySelector('input');
            const span = document.createElement('span');
            span.className = 'static-cmd';
            span.textContent = ' ' + cmd;
            inp.replaceWith(span);
        }

        if (!cmd) { this.addInputLine(); return; }

        const [base, ...rest] = cmd.split(' ');
        const handler = getCommand(base);
        if (!handler) {
            this.print(`-bash: ${cmd}: command not found`, true);
            this.addInputLine();
            return;
        }

        const result = handler.execute(rest.join(' '), this);
        Promise.resolve(result).then((r) => {
            this.printResult(r);
            this.addInputLine();
            this.scrollBottom();
        });
    }

    printResult(result) {
        if (result === null || result === undefined || result === '') return;
        if (result instanceof Element) {
            this.el.appendChild(result);
            this.scrollBottom();
        } else {
            this.print(String(result));
        }
    }

    print(text, isError = false) {
        const d = document.createElement('div');
        d.className = 'output' + (isError ? ' error' : '');
        d.textContent = text;
        this.el.appendChild(d);
        this.scrollBottom();
    }

    clear() {
        this.el.innerHTML = '';
        this.addInputLine();
    }

    scrollBottom() { this.el.scrollTop = this.el.scrollHeight; }
}
