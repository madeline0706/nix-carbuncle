const PLAYER = '@';
const FLOOR = '.';

const MOVES = {
    ArrowUp: [0, -1],
    ArrowDown: [0, 1],
    ArrowLeft: [-1, 0],
    ArrowRight: [1, 0],
};

export class Dungeon {
    constructor(elId, mapText) {
        this.el = document.getElementById(elId);
        this.map = mapText.split('\n').map((row) => row.split(''));
        this.px = 0;
        this.py = 0;

        this.map.forEach((row, y) => row.forEach((ch, x) => {
            if (ch === PLAYER) {
                this.px = x;
                this.py = y;
                this.map[y][x] = FLOOR;
            }
        }));

        this.render();
        window.addEventListener('keydown', (e) => this.onKey(e));
    }

    onKey(e) {
        const delta = MOVES[e.key];
        if (!delta) return;
        e.preventDefault();
        this.move(delta[0], delta[1]);
    }

    move(dx, dy) {
        const nx = this.px + dx;
        const ny = this.py + dy;
        const row = this.map[ny];
        if (!row || row[nx] !== FLOOR) return;
        this.px = nx;
        this.py = ny;
        this.render();
    }

    render() {
        this.el.innerHTML = this.map.map((row, y) =>
            row.map((ch, x) =>
                (x === this.px && y === this.py)
                    ? `<span class="dungeon-player">${PLAYER}</span>`
                    : ch
            ).join('')
        ).join('\n');
    }
}
