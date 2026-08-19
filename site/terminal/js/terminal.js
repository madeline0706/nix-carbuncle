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

    // `label` overrides the usual shell prompt-sign — used by ask() so an
    // interactive prompt (e.g. `login:`) reads like the real thing.
    addInputLine(label) {
        this.el.querySelectorAll('.live-input').forEach((e) => e.remove());
        const line = document.createElement('div');
        line.className = 'input-line live-input';
        const sign = label != null ? label : this.getPromptString();
        line.innerHTML =
            `<span class="prompt-sign">${sign}</span>` +
            `<input type="text" class="command-input" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false">`;
        this.el.appendChild(line);
        this.input = line.querySelector('input');
        this.input.addEventListener('keydown', (e) => this.onKey(e));
        this.el.addEventListener('click', (e) => { if (e.target === this.el) this.input.focus(); });
        this.input.focus();
        this.scrollBottom();
    }

    // freeze the current live input into static text so it scrolls into history
    freezeInput(text) {
        const live = this.el.querySelector('.live-input');
        if (!live) return;
        live.classList.remove('live-input');
        const span = document.createElement('span');
        span.className = 'static-cmd';
        span.textContent = ' ' + text;
        live.querySelector('input').replaceWith(span);
    }

    // read one line from the user. returns a Promise a command can await; while
    // pending, the next Enter feeds it instead of running as a command.
    ask(label = '') {
        return new Promise((resolve) => {
            this.pending = resolve;
            this.addInputLine(label);
        });
    }

    onKey(e) {
        if (e.key !== 'Enter') return;
        e.preventDefault();
        const value = this.input.value.trim();
        this.freezeInput(value);
        if (this.pending) {
            const resolve = this.pending;
            this.pending = null;
            resolve(value);
            return;
        }
        this.run(value);
    }

    run(cmd) {
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
