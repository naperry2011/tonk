// Generates a seamless lofi background loop (assets/music/lofi_loop.wav).
// Fully synthesized and deterministic, so the output is ours to ship.
// Usage (from app/): node tool/gen_music.mjs
//
// 78 BPM, 16 bars: Dm9 - G13 - Cmaj9 - Am9, Rhodes-style keys with tape
// wobble, round bass, a lazy swung beat, a sparse melody in the second
// half, and vinyl crackle. Every sound is written with wrap-around so the
// tail of the last bar rings into the first: the loop has no seam.
import { Buffer } from 'node:buffer';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const RATE = 22050; // a low sample rate suits the lofi sound and keeps it small
const BPM = 78;
const BEAT = 60 / BPM;
const BAR = BEAT * 4;
const BARS = 16;
const N = Math.round(BAR * BARS * RATE);
const SWING = 0.6; // offbeat 8ths land 60% through the beat

const outDir = join(dirname(fileURLToPath(import.meta.url)), '..', 'assets', 'music');

let seed = 20261103;
const rand = () => {
  seed = (seed * 1103515245 + 12345) & 0x7fffffff;
  return seed / 0x7fffffff;
};
const noise = () => rand() * 2 - 1;
const midi = (n) => 440 * 2 ** ((n - 69) / 12);

const keys = new Float32Array(N);
const bass = new Float32Array(N);
const drums = new Float32Array(N);
const lead = new Float32Array(N);
const vinyl = new Float32Array(N);

/// Adds a sample at a wrapped position so tails cross the loop point.
const put = (buf, i, v) => {
  buf[((i % N) + N) % N] += v;
};

/// Beat position (in beats from loop start) to seconds, with swing on 8ths.
const at = (bar, beat) => {
  const whole = Math.floor(beat);
  const frac = beat - whole;
  const swung = frac === 0.5 ? SWING : frac;
  return bar * BAR + (whole + swung) * BEAT;
};

/// Tape wow: a slow pitch wobble shared by the keys and lead.
const wow = (t) => 1 + 0.0025 * Math.sin(2 * Math.PI * 0.45 * t) + 0.001 * Math.sin(2 * Math.PI * 2.7 * t);

function rhodes(buf, start, dur, freq, gain) {
  const s0 = Math.round(start * RATE);
  let p1 = 0;
  let p2 = 0;
  for (let i = 0; i < dur * RATE; i++) {
    const t = i / RATE;
    const w = wow(start + t);
    p1 += (2 * Math.PI * freq * w) / RATE;
    p2 += (2 * Math.PI * freq * 2.002 * w) / RATE;
    const attack = Math.min(1, t / 0.02);
    const release = Math.min(1, (dur - t) / 0.25);
    const env = attack * release * Math.exp(-1.1 * t);
    const bell = 0.18 * Math.sin(p2) * Math.exp(-6 * t);
    const tremolo = 1 - 0.1 * (0.5 + 0.5 * Math.sin(2 * Math.PI * 4.2 * (start + t)));
    put(buf, s0 + i, (Math.sin(p1) + bell) * env * gain * tremolo);
  }
}

function bassNote(start, dur, freq, gain = 0.5) {
  const s0 = Math.round(start * RATE);
  for (let i = 0; i < dur * RATE; i++) {
    const t = i / RATE;
    const env = Math.min(1, t / 0.01) * Math.min(1, (dur - t) / 0.08) * Math.exp(-1.6 * t);
    const v = Math.sin(2 * Math.PI * freq * t) + 0.25 * Math.sin(2 * Math.PI * freq * 2 * t);
    put(bass, s0 + i, v * env * gain);
  }
}

function kick(start, gain = 0.9) {
  const s0 = Math.round(start * RATE);
  let phase = 0;
  for (let i = 0; i < 0.35 * RATE; i++) {
    const t = i / RATE;
    phase += (2 * Math.PI * (48 + 70 * Math.exp(-28 * t))) / RATE;
    put(drums, s0 + i, Math.sin(phase) * Math.exp(-9 * t) * gain);
  }
}

function snare(start, gain = 0.35) {
  const s0 = Math.round(start * RATE);
  let low = 0;
  for (let i = 0; i < 0.28 * RATE; i++) {
    const t = i / RATE;
    low += 0.35 * (noise() - low);
    const body = 0.5 * Math.sin(2 * Math.PI * 185 * t) * Math.exp(-25 * t);
    put(drums, s0 + i, (low * Math.exp(-16 * t) + body) * gain);
  }
}

function hat(start, gain) {
  const s0 = Math.round(start * RATE);
  let prev = 0;
  for (let i = 0; i < 0.05 * RATE; i++) {
    const n = noise();
    const high = n - prev;
    prev = n;
    put(drums, s0 + i, high * Math.exp((-i / RATE) * 90) * gain);
  }
}

// Chords: [bass note, voicing] per bar, cycling every 4 bars.
const progression = [
  [38, [53, 57, 60, 64]], // Dm9
  [43, [53, 59, 64, 69]], // G13
  [48, [52, 55, 59, 62]], // Cmaj9
  [45, [55, 60, 64, 71]], // Am9
];

for (let bar = 0; bar < BARS; bar++) {
  const [root, voicing] = progression[bar % 4];

  // Keys: a full chord on beat 1, a softer push on the "and" of 2.
  voicing.forEach((n, k) => rhodes(keys, at(bar, 0) + k * 0.012, BAR * 0.95, midi(n), 0.11));
  voicing.slice(1).forEach((n) => rhodes(keys, at(bar, 1.5), BEAT * 1.6, midi(n), 0.06));

  // Bass: root on 1, fifth on the "and" of 3, back to root before the turn.
  bassNote(at(bar, 0), BEAT * 1.8, midi(root), 0.42);
  bassNote(at(bar, 2.5), BEAT * 0.9, midi(root + 7), 0.3);
  bassNote(at(bar, 3.5), BEAT * 0.5, midi(root + 12), 0.22);

  // Drums: lazy boom-bap with swung hats.
  kick(at(bar, 0));
  kick(at(bar, 1.5), 0.6);
  if (bar % 2 === 1) kick(at(bar, 2.5), 0.55);
  snare(at(bar, 1));
  snare(at(bar, 3));
  for (let e = 0; e < 8; e++) {
    hat(at(bar, e / 2), e % 2 === 0 ? 0.09 : 0.05 + 0.03 * rand());
  }
}

// A sparse melody over the second half (D minor pentatonic).
const melody = [
  [8, 0.5, 74, 1.2], [8, 2.5, 72, 0.8], [9, 1, 69, 1.5], [10, 0, 72, 1],
  [10, 1.5, 74, 0.8], [11, 0.5, 76, 2], [12, 2, 74, 1], [13, 0, 72, 1.2],
  [13, 2.5, 69, 0.8], [14, 1, 67, 1.4], [15, 0, 69, 2.4],
];
for (const [bar, beat, note, beats] of melody) {
  rhodes(lead, at(bar, beat), beats * BEAT, midi(note), 0.09);
}

// Vinyl: soft hiss plus random crackles.
let hiss = 0;
for (let i = 0; i < N; i++) {
  hiss += 0.05 * (noise() - hiss);
  vinyl[i] = hiss * 0.05;
}
for (let c = 0; c < N / RATE * 7; c++) {
  const i = Math.floor(rand() * N);
  const amp = 0.08 * rand() ** 2;
  for (let k = 0; k < 24; k++) put(vinyl, i + k, amp * noise() * Math.exp(-k / 4));
}

// Mix, warm it up with a low-pass, and soft-clip.
const mix = new Float32Array(N);
for (let i = 0; i < N; i++) {
  mix[i] = keys[i] + bass[i] + drums[i] * 0.8 + lead[i] + vinyl[i];
}
// Run the filter over the loop twice so its state at the seam matches.
const a = 1 - Math.exp((-2 * Math.PI * 3800) / RATE);
let y = 0;
for (let pass = 0; pass < 2; pass++) {
  for (let i = 0; i < N; i++) {
    y += a * (mix[i] - y);
    if (pass === 1) mix[i] = y;
  }
}
let peak = 0;
for (const v of mix) peak = Math.max(peak, Math.abs(v));
const scale = 0.8 / peak;

const data = Buffer.alloc(N * 2);
for (let i = 0; i < N; i++) {
  data.writeInt16LE(Math.round(Math.tanh(mix[i] * scale * 1.1) * 32767), i * 2);
}
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
mkdirSync(outDir, { recursive: true });
writeFileSync(join(outDir, 'lofi_loop.wav'), Buffer.concat([header, data]));
console.log(`Wrote ${(N / RATE).toFixed(1)}s loop to ${outDir}`);
