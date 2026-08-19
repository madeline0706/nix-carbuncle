// login — swap the name on the prompt. takes it inline (`login madeline`) or asks
import { register } from './registry.js';

// unix-ish: letters/digits plus . _ -, keep it short. also keeps the name safe to
// drop into the prompt's innerHTML (see getPromptString / addInputLine)
const MAX = 32;
const VALID = /^[a-zA-Z0-9._-]+$/;

register({
    name: 'login',
    describe: 'sign in with a username',
    execute: async (args, term) => {
        const name = (args.trim() || (await term.ask('login:'))).trim();
        if (!name) return 'login: no username given';
        if (name.length > MAX) return `login: username too long (max ${MAX})`;
        if (!VALID.test(name)) return 'login: use letters, digits, . _ - only';
        term.username = name;   // getPromptString() reads this, so the next prompt updates
        return `logged in as ${name}`;
    },
});
