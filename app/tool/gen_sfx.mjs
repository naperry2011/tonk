// Generates the game's sound effects as 16-bit mono WAVs in assets/sfx/.
// Fully synthesized (no samples), so the output is ours to ship.
// Usage (from app/): node tool/gen_sfx.mjs
import { Buffer } from 'node:buffer';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const RATE = 44100;
const outDir = join(dirname(fileURLToPath(import.meta.url)), '..', 'assets', 'sfx');

// Deterministic noise so regenerating gives identical files.
let seed = 1234567;
const noise = () => {
  seed = (seed * 1103515245 + 12345) & 0x7fffffff;
  return (seed / 0x3fffffff) - 1;
};

const buffer = (seconds) => new Float32Array(Math.ceil(seconds * RATE));

function addTone(buf, start, dur, freq, { gain = 0.5, decay = 8, shape = 'sine', glide = 0 } = {}) {
  const s0 = Math.floor(start * RATE);
  let phase = 0;
  for (let i = 0; i < dur * RATE && s0 + i < buf.length; i++) {
    const t = i / RATE;
    const f = freq * (1 + glide * t / dur);
    phase += (2 * Math.PI * f) / RATE;
    const x = shape === 'triangle'
      ? (2 / Math.PI) * Math.asin(Math.sin(phase))
      : Math.sin(phase);
    const attack = Math.min(1, t / 0.004);
    buf[s0 + i] += x * gain * attack * Math.exp(-decay * t);
  }
}

function addNoise(buf, start, dur, { gain = 0.5, decay = 40, highpass = 0.85 } = {}) {
  const s0 = Math.floor(start * RATE);
  let prev = 0;
  let prevOut = 0;
  for (let i = 0; i < dur * RATE && s0 + i < buf.length; i++) {
    const t = i / RATE;
    const n = noise();
    const hp = highpass * (prevOut + n - prev);
    prev = n;
    prevOut = hp;
    buf[s0 + i] += hp * gain * Math.exp(-decay * t);
  }
}

function addSwish(buf, start, dur, gain = 0.35) {
  const s0 = Math.floor(start * RATE);
  let low = 0;
  for (let i = 0; i < dur * RATE && s0 + i < buf.length; i++) {
    const p = i / (dur * RATE);
    low += 0.25 * (noise() - low);
    buf[s0 + i] += low * gain * Math.sin(Math.PI * p) ** 2;
  }
}

function writeWav(name, buf) {
  let peak = 0;
  for (const v of buf) peak = Math.max(peak, Math.abs(v));
  const scale = peak > 0 ? 0.89 / peak : 1;
  const data = Buffer.alloc(buf.length * 2);
  buf.forEach((v, i) => data.writeInt16LE(Math.round(v * scale * 32767), i * 2));
  const header = Buffer.alloc(44);
  header.write('RIFF', 0);
  header.writeUInt32LE(36 + data.length, 4);
  header.write('WAVE', 8);
  header.write('fmt ', 12);
  header.writeUInt32LE(16, 16);
  header.writeUInt16LE(1, 20);
  header.writeUInt16LE(1, 22);
  header.writeUInt32LE(RATE, 24);
  header.writeUInt32LE(RATE * 2, 28);
  header.writeUInt16LE(2, 32);
  header.writeUInt16LE(16, 34);
  header.write('data', 36);
  header.writeUInt32LE(data.length, 40);
  writeFileSync(join(outDir, `${name}.wav`), Buffer.concat([header, data]));
}

mkdirSync(outDir, { recursive: true });

// Tap a card in hand.
const select = buffer(0.05);
addNoise(select, 0, 0.05, { gain: 0.4, decay: 120 });
writeWav('select', select);

// Card hits the table.
const card = buffer(0.12);
addNoise(card, 0, 0.12, { gain: 0.9, decay: 45 });
addTone(card, 0, 0.06, 180, { gain: 0.25, decay: 60 });
writeWav('card', card);

// Draw: a short swish.
const draw = buffer(0.18);
addSwish(draw, 0, 0.18, 0.6);
writeWav('draw', draw);

// Spread: three quick slaps.
const spread = buffer(0.32);
for (const t of [0, 0.09, 0.18]) {
  addNoise(spread, t, 0.12, { gain: 0.8, decay: 50 });
  addTone(spread, t, 0.05, 160, { gain: 0.2, decay: 70 });
}
writeWav('spread', spread);

// Knock: two knuckle raps on wood.
const knock = buffer(0.42);
for (const t of [0, 0.17]) {
  addTone(knock, t, 0.2, 140, { gain: 0.9, decay: 28, glide: -0.4 });
  addNoise(knock, t, 0.03, { gain: 0.4, decay: 160, highpass: 0.5 });
}
writeWav('knock', knock);

// Chips: a few clinks.
const chips = buffer(0.4);
[[0, 3100], [0.05, 2600], [0.11, 3500], [0.16, 2900]].forEach(([t, f]) => {
  addTone(chips, t, 0.2, f, { gain: 0.3, decay: 30 });
  addTone(chips, t, 0.2, f * 1.52, { gain: 0.12, decay: 40 });
});
writeWav('chips', chips);

// Round won: rising arpeggio.
const win = buffer(0.9);
[[0, 523.25], [0.1, 659.25], [0.2, 783.99], [0.32, 1046.5]].forEach(([t, f], i) => {
  addTone(win, t, i === 3 ? 0.55 : 0.3, f, { gain: 0.4, decay: i === 3 ? 4 : 9, shape: 'triangle' });
});
writeWav('win', win);

// Round lost: two falling notes.
const lose = buffer(0.6);
addTone(lose, 0, 0.25, 392, { gain: 0.4, decay: 7, shape: 'triangle' });
addTone(lose, 0.2, 0.4, 311.13, { gain: 0.4, decay: 5, shape: 'triangle', glide: -0.06 });
writeWav('lose', lose);

// TONK: big fanfare with a chip shower.
const tonk = buffer(1.6);
[[0, 523.25], [0.09, 659.25], [0.18, 783.99], [0.27, 1046.5], [0.45, 1318.5]].forEach(([t, f], i) => {
  addTone(tonk, t, i === 4 ? 1.1 : 0.35, f, { gain: 0.45, decay: i === 4 ? 2.5 : 8, shape: 'triangle' });
  if (i === 4) addTone(tonk, t, 1.1, f / 2, { gain: 0.3, decay: 2.5, shape: 'triangle' });
});
for (let i = 0; i < 10; i++) {
  addTone(tonk, 0.5 + i * 0.07, 0.15, 2500 + ((i * 370) % 1200), { gain: 0.12, decay: 35 });
}
writeWav('tonk', tonk);

console.log(`Wrote sfx to ${outDir}`);
