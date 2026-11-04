// Generates the game's lofi sound effects as 16-bit mono WAVs in assets/sfx/.
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
  return seed / 0x3fffffff - 1;
};

const buffer = (seconds) => new Float32Array(Math.ceil(seconds * RATE));
const midi = (n) => 440 * 2 ** ((n - 69) / 12);

/// Soft electric-piano note: sine body plus a quickly fading bell partial.
function addKey(buf, start, dur, freq, { gain = 0.4, decay = 3 } = {}) {
  const s0 = Math.floor(start * RATE);
  for (let i = 0; i < dur * RATE && s0 + i < buf.length; i++) {
    const t = i / RATE;
    const attack = Math.min(1, t / 0.012);
    const body = Math.sin(2 * Math.PI * freq * t) * Math.exp(-decay * t);
    const bell = 0.25 * Math.sin(2 * Math.PI * freq * 2 * t) * Math.exp(-decay * 4 * t);
    const tremolo = 1 - 0.12 * (0.5 + 0.5 * Math.sin(2 * Math.PI * 4.5 * t));
    buf[s0 + i] += (body + bell) * gain * attack * tremolo;
  }
}

/// Muffled thump: a low sine with a quick pitch drop.
function addThump(buf, start, dur, freq, { gain = 0.6, decay = 30, drop = 0.5 } = {}) {
  const s0 = Math.floor(start * RATE);
  let phase = 0;
  for (let i = 0; i < dur * RATE && s0 + i < buf.length; i++) {
    const t = i / RATE;
    phase += (2 * Math.PI * freq * (1 - drop * Math.min(1, t / dur))) / RATE;
    buf[s0 + i] += Math.sin(phase) * gain * Math.min(1, t / 0.003) * Math.exp(-decay * t);
  }
}

/// Low-passed noise burst (felt, paper, swish).
function addSoftNoise(buf, start, dur, { gain = 0.5, decay = 40, cutoff = 0.12, swell = false } = {}) {
  const s0 = Math.floor(start * RATE);
  let low = 0;
  for (let i = 0; i < dur * RATE && s0 + i < buf.length; i++) {
    const t = i / RATE;
    const p = i / (dur * RATE);
    low += cutoff * (noise() - low);
    const env = swell ? Math.sin(Math.PI * p) ** 2 : Math.exp(-decay * t);
    buf[s0 + i] += low * gain * env;
  }
}

/// A sprinkle of vinyl crackle.
function addCrackle(buf, count, gain = 0.15) {
  for (let i = 0; i < count; i++) {
    const at = Math.floor(((noise() + 1) / 2) * (buf.length - 40));
    const amp = gain * (0.4 + 0.6 * Math.abs(noise()));
    for (let k = 0; k < 30; k++) buf[at + k] += amp * noise() * Math.exp(-k / 5);
  }
}

/// One-pole low-pass over the whole buffer, for the warm lofi top end.
function warm(buf, cutoffHz) {
  const a = 1 - Math.exp((-2 * Math.PI * cutoffHz) / RATE);
  let y = 0;
  for (let i = 0; i < buf.length; i++) {
    y += a * (buf[i] - y);
    buf[i] = y;
  }
}

function writeWav(name, buf, peakTarget = 0.6) {
  let peak = 0;
  for (const v of buf) peak = Math.max(peak, Math.abs(v));
  const scale = peak > 0 ? peakTarget / peak : 1;
  const data = Buffer.alloc(buf.length * 2);
  buf.forEach((v, i) => data.writeInt16LE(Math.round(Math.tanh(v * scale) * 32767), i * 2));
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

// Tap a card in hand: a tiny soft tick.
const select = buffer(0.06);
addSoftNoise(select, 0, 0.06, { gain: 0.5, decay: 110, cutoff: 0.25 });
warm(select, 3500);
writeWav('select', select, 0.35);

// Card lands on felt.
const card = buffer(0.16);
addSoftNoise(card, 0, 0.16, { gain: 0.9, decay: 38, cutoff: 0.18 });
addThump(card, 0, 0.1, 140, { gain: 0.35, decay: 45 });
warm(card, 2600);
writeWav('card', card, 0.55);

// Draw: a slow paper swish.
const draw = buffer(0.24);
addSoftNoise(draw, 0, 0.24, { gain: 0.7, cutoff: 0.08, swell: true });
warm(draw, 2200);
writeWav('draw', draw, 0.45);

// Spread: three soft cards in a row.
const spread = buffer(0.42);
for (const t of [0, 0.12, 0.24]) {
  addSoftNoise(spread, t, 0.14, { gain: 0.8, decay: 40, cutoff: 0.16 });
  addThump(spread, t, 0.08, 130, { gain: 0.3, decay: 50 });
}
warm(spread, 2400);
writeWav('spread', spread, 0.55);

// Knock: two knuckles on a wooden table, muffled.
const knock = buffer(0.5);
for (const t of [0, 0.19]) {
  addThump(knock, t, 0.25, 115, { gain: 0.9, decay: 22, drop: 0.35 });
  addSoftNoise(knock, t, 0.04, { gain: 0.3, decay: 120, cutoff: 0.3 });
}
warm(knock, 1800);
writeWav('knock', knock, 0.7);

// Chips: soft clay clinks.
const chips = buffer(0.5);
[[0, 1900], [0.06, 1650], [0.13, 2100], [0.2, 1800]].forEach(([t, f]) => {
  addKey(chips, t, 0.3, f, { gain: 0.25, decay: 18 });
});
addSoftNoise(chips, 0, 0.3, { gain: 0.15, decay: 20, cutoff: 0.2 });
warm(chips, 3000);
writeWav('chips', chips, 0.45);

// Round won: a mellow rising Cmaj9 arpeggio.
const win = buffer(1.4);
[60, 64, 67, 71, 74].forEach((n, i) => addKey(win, i * 0.11, 1.1, midi(n), { gain: 0.35, decay: 2.6 }));
addCrackle(win, 6, 0.04);
warm(win, 3200);
writeWav('win', win, 0.55);

// Round lost: two soft falling notes.
const lose = buffer(1.0);
addKey(lose, 0, 0.6, midi(67), { gain: 0.35, decay: 4 });
addKey(lose, 0.22, 0.8, midi(63), { gain: 0.35, decay: 3 });
warm(lose, 2800);
writeWav('lose', lose, 0.5);

// TONK: a warm chord bloom with gentle chimes on top.
const tonk = buffer(2.4);
[48, 55, 64, 71, 74].forEach((n) => addKey(tonk, 0, 2.2, midi(n), { gain: 0.3, decay: 1.2 }));
[79, 83, 86, 91].forEach((n, i) => addKey(tonk, 0.3 + i * 0.14, 1.2, midi(n), { gain: 0.16, decay: 3 }));
addCrackle(tonk, 10, 0.04);
warm(tonk, 3600);
writeWav('tonk', tonk, 0.65);

console.log(`Wrote sfx to ${outDir}`);
