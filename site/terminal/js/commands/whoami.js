// whoami — hand back whatever name the prompt's currently using
import { register } from './registry.js';

register({
    name: 'whoami',
    describe: 'print the current user',
    execute: (args, term) => term.username,
});
