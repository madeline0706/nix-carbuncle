export const wait = (ms) => new Promise((r) => setTimeout(r, ms));

export async function loadText(path) {
    try {
        const r = await fetch(path);
        if (!r.ok) throw new Error(r.status);
        return (await r.text()).replace(/\s+$/, '');
    } catch {
        return '';
    }
}

export async function loadJson(path, fallback = {}) {
    try {
        const r = await fetch(path);
        if (!r.ok) throw new Error(r.status);
        return await r.json();
    } catch {
        return fallback;
    }
}
