// Small shared helpers.

export const wait = (ms) => new Promise((r) => setTimeout(r, ms));

// Fetch a file from the site root, returning its trimmed text (or "" on error).
export async function loadText(path) {
    try {
        const r = await fetch(path);
        if (!r.ok) throw new Error(r.status);
        return (await r.text()).replace(/\s+$/, '');
    } catch {
        return '';
    }
}

// Fetch and parse a JSON file, returning `fallback` on any error.
export async function loadJson(path, fallback = {}) {
    try {
        const r = await fetch(path);
        if (!r.ok) throw new Error(r.status);
        return await r.json();
    } catch {
        return fallback;
    }
}
