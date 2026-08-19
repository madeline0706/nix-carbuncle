// clear — terminal.clear() wipes the screen and re-adds a prompt, so return nothing
import { register } from './registry.js';

register({
    name: 'clear',
    describe: 'clear the screen',
    execute: (args, term) => { term.clear(); },
});
