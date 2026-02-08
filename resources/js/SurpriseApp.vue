<template>
  <div class="page">
    <canvas ref="canvasRef" class="hearts-canvas" aria-hidden="true"></canvas>

    <div class="card">
      <div class="top">
        <div class="badge">💘 DATE CHOOSER</div>
        <h1>Okay bebik. Du darfst wählen 😌</h1>
        <p>Such dir eins aus – ich sag zu allem ja.</p>
      </div>

      <div class="grid">
        <button
          v-for="opt in options"
          :key="opt.id"
          class="option"
          :class="{ active: selected?.id === opt.id }"
          type="button"
          @click="select(opt)"
        >
          <div class="emoji">{{ opt.emoji }}</div>
          <div class="title">{{ opt.title }}</div>
          <div class="desc">{{ opt.desc }}</div>
        </button>
      </div>

      <div v-if="selected" class="result">
        <div class="resultTitle">Deine Wahl:</div>

        <div class="resultMain">
          <span class="resultEmoji">{{ selected.emoji }}</span>
          <span class="resultText">{{ selected.title }}</span>
        </div>

        <div class="resultNote">
          {{ selected.note }}
        </div>

        <div class="actions">
          <button class="primary" type="button" @click="celebrate">Fix machen 💌</button>
          <button class="secondary" type="button" @click="reset">Umentscheiden</button>
        </div>

        <div v-if="confirmed" class="confirmed">
          <span class="big">💖</span>
          Deal. Ich freu mich auf unser Date.
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onBeforeUnmount, onMounted, ref } from "vue";

/**
 * -------------------------
 * Date chooser state
 * -------------------------
 */
const options = [
  {
    id: "dinner",
    emoji: "🍝",
    title: "Dinner-Date",
    desc: "Essen gehen oder selber kochen",
    note: "Du bestimmst: Restaurant oder ich koch was richtig Gutes.",
  },
  {
    id: "movie",
    emoji: "🎬",
    title: "Filmabend Deluxe",
    desc: "Snack-Setup + Kuscheldecke",
    note: "Du wählst den Film, ich mach Snacks und Decke.",
  },
  {
    id: "walk",
    emoji: "☕",
    title: "Spaziergang + Kakao",
    desc: "Kurz raus, dann warm werden",
    note: "Wir gehen eine Runde, dann heißer Kakao und ganz viel Kuscheln.",
  },
  {
    id: "picknick",
    emoji: "🧺",
    title: "Picknick (drinnen)",
    desc: "Kerzen + Musik + kleine Sachen",
    note: "Indoor-Picknick: Kerzen, Musik, kleine Leckereien, comfy.",
  },
];

const selected = ref(null);
const confirmed = ref(false);

function select(opt) {
  selected.value = opt;
  confirmed.value = false;
}

function reset() {
  selected.value = null;
  confirmed.value = false;
}

function celebrate() {
  confirmed.value = true;
  burstHearts(80);
}

/**
 * -------------------------
 * Canvas hearts background
 * (like your previous version)
 * -------------------------
 */
const canvasRef = ref(null);

let rafId = 0;
let ctx = null;
let dpr = 1;
let w = 0;
let h = 0;

const mouse = { x: 0, y: 0, active: false };
const hearts = [];
const bursts = [];
const HEART_COUNT = 70;

function rand(min, max) {
  return Math.random() * (max - min) + min;
}

function resizeCanvas() {
  const canvas = canvasRef.value;
  if (!canvas) return;

  dpr = Math.max(1, Math.floor(window.devicePixelRatio || 1));
  w = window.innerWidth;
  h = window.innerHeight;

  canvas.width = Math.floor(w * dpr);
  canvas.height = Math.floor(h * dpr);
  canvas.style.width = `${w}px`;
  canvas.style.height = `${h}px`;

  ctx = canvas.getContext("2d");
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
}

function spawnHeart(initial = false) {
  const y = initial ? rand(0, h) : h + rand(20, 200);

  hearts.push({
    x: rand(0, w),
    y,
    size: rand(8, 18),
    vy: rand(0.35, 1.1),
    vx: rand(-0.25, 0.25),
    sway: rand(0, Math.PI * 2),
    rot: rand(-0.4, 0.4),
    vr: rand(-0.01, 0.01),
    alpha: rand(0.3, 0.8),
  });
}

function drawHeart(x, y, size, rotation, alpha) {
  ctx.save();
  ctx.translate(x, y);
  ctx.rotate(rotation);
  ctx.globalAlpha = alpha;

  ctx.fillStyle = "#E11D48";
  ctx.beginPath();

  const s = size;
  ctx.moveTo(0, s * 0.35);
  ctx.bezierCurveTo(s * 0.65, -s * 0.35, s * 1.1, s * 0.45, 0, s * 1.15);
  ctx.bezierCurveTo(-s * 1.1, s * 0.45, -s * 0.65, -s * 0.35, 0, s * 0.35);

  ctx.closePath();
  ctx.fill();
  ctx.restore();
}

function burstHearts(count = 50) {
  for (let i = 0; i < count; i++) {
    const angle = rand(-Math.PI * 0.05, Math.PI + Math.PI * 0.05);
    const speed = rand(2.5, 7.0);

    bursts.push({
      x: rand(w * 0.25, w * 0.75),
      y: rand(h * 0.35, h * 0.7),
      size: rand(10, 22),
      vx: Math.cos(angle) * speed * rand(0.6, 1.2),
      vy: -Math.sin(angle) * speed * rand(0.9, 1.4),
      rot: rand(-0.6, 0.6),
      vr: rand(-0.08, 0.08),
      alpha: 1,
      life: rand(50, 90),
      drag: rand(0.98, 0.992),
      gravity: rand(0.02, 0.05),
    });
  }
}

function updateFloatingHearts() {
  for (let i = 0; i < hearts.length; i++) {
    const p = hearts[i];

    // drift + sway
    p.sway += 0.02;
    p.x += p.vx + Math.sin(p.sway) * 0.15;
    p.y -= p.vy;
    p.rot += p.vr;

    // mouse repulsion
    if (mouse.active) {
      const dx = p.x - mouse.x;
      const dy = p.y - mouse.y;
      const dist = Math.hypot(dx, dy);
      const radius = 140;

      if (dist < radius && dist > 0.001) {
        const strength = (1 - dist / radius) * 1.8;
        p.x += (dx / dist) * strength * 2.2;
        p.y += (dy / dist) * strength * 2.2;
        p.rot += (dx / dist) * 0.02;
      }
    }

    // recycle
    if (p.y < -60) {
      hearts.splice(i, 1);
      i--;
      spawnHeart(false);
      continue;
    }

    // wrap x
    if (p.x < -60) p.x = w + 60;
    if (p.x > w + 60) p.x = -60;

    drawHeart(p.x, p.y, p.size, p.rot, p.alpha);
  }
}

function updateBursts() {
  for (let i = 0; i < bursts.length; i++) {
    const p = bursts[i];

    p.vx *= p.drag;
    p.vy *= p.drag;
    p.vy += p.gravity;

    p.x += p.vx;
    p.y += p.vy;
    p.rot += p.vr;

    p.life -= 1;
    p.alpha = Math.max(0, p.life / 90);

    drawHeart(p.x, p.y, p.size, p.rot, p.alpha);

    if (p.life <= 0 || p.y > h + 80 || p.x < -80 || p.x > w + 80) {
      bursts.splice(i, 1);
      i--;
    }
  }
}

function tick() {
  rafId = requestAnimationFrame(tick);
  if (!ctx) return;

  ctx.clearRect(0, 0, w, h);
  updateFloatingHearts();
  updateBursts();
}

function onMouseMove(e) {
  mouse.x = e.clientX;
  mouse.y = e.clientY;
  mouse.active = true;
}

function onMouseLeave() {
  mouse.active = false;
}

function onDocPointerOut(e) {
  // when leaving the browser window/document
  if (!e.relatedTarget) onMouseLeave();
}

onMounted(() => {
  resizeCanvas();
  hearts.length = 0;
  bursts.length = 0;

  for (let i = 0; i < HEART_COUNT; i++) spawnHeart(true);

  tick();

  window.addEventListener("resize", resizeCanvas, { passive: true });
  window.addEventListener("pointermove", onMouseMove, { passive: true });

  // robust deactivate behavior
  window.addEventListener("blur", onMouseLeave, { passive: true });
  document.addEventListener("pointerout", onDocPointerOut, { passive: true });
});

onBeforeUnmount(() => {
  cancelAnimationFrame(rafId);

  window.removeEventListener("resize", resizeCanvas);
  window.removeEventListener("pointermove", onMouseMove);

  window.removeEventListener("blur", onMouseLeave);
  document.removeEventListener("pointerout", onDocPointerOut);
});
</script>

<style scoped>
.page {
  min-height: 100vh;
  display: grid;
  place-items: center;
  overflow: hidden;
  position: relative;
  font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif;

  background: radial-gradient(900px 500px at 20% 20%, #ffd1dc, transparent 60%),
              radial-gradient(900px 600px at 80% 80%, #ff8fb1, transparent 60%),
              linear-gradient(135deg, #ffb3c7, #ff6f91);
}

.hearts-canvas {
  position: fixed;
  inset: 0;
  z-index: 0;
  pointer-events: none;
}

.card {
  position: relative;
  z-index: 2;
  width: min(780px, 92vw);
  background: #fff;
  color: #111827;
  border: 1px solid rgba(0,0,0,0.08);
  border-radius: 24px;
  box-shadow: 0 24px 70px rgba(0,0,0,0.25);
  padding: 24px;
}

.badge {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: rgba(17,24,39,0.75);
  background: rgba(225, 29, 72, 0.10);
  border: 1px solid rgba(225, 29, 72, 0.18);
  padding: 8px 10px;
  border-radius: 999px;
}

h1 {
  margin: 12px 0 6px;
  font-size: 30px;
  letter-spacing: -0.02em;
}

p {
  margin: 0 0 16px;
  color: rgba(17,24,39,0.70);
}

.grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}

@media (max-width: 640px) {
  .grid { grid-template-columns: 1fr; }
}

.option {
  text-align: left;
  border: 1px solid rgba(0,0,0,0.10);
  background: rgba(17,24,39,0.03);
  border-radius: 18px;
  padding: 16px;
  cursor: pointer;
  transition: transform 120ms ease, background 160ms ease, border-color 160ms ease;
}

.option:hover {
  transform: translateY(-1px);
  background: rgba(225, 29, 72, 0.06);
  border-color: rgba(225, 29, 72, 0.18);
}

.option.active {
  background: rgba(225, 29, 72, 0.10);
  border-color: rgba(225, 29, 72, 0.22);
}

.emoji { font-size: 26px; margin-bottom: 8px; }
.title { font-weight: 750; font-size: 16px; }
.desc { margin-top: 4px; color: rgba(17,24,39,0.70); font-size: 14px; }

.result {
  margin-top: 16px;
  border-top: 1px solid rgba(0,0,0,0.08);
  padding-top: 16px;
}

.resultTitle {
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: rgba(17,24,39,0.60);
}

.resultMain {
  margin-top: 8px;
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 18px;
  font-weight: 800;
}

.resultEmoji { font-size: 22px; }
.resultNote { margin-top: 8px; color: rgba(17,24,39,0.72); }

.actions {
  margin-top: 14px;
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.primary, .secondary {
  border: none;
  border-radius: 14px;
  padding: 12px 14px;
  font-weight: 700;
  cursor: pointer;
}

.primary {
  background: #e11d48;
  color: #fff;
  box-shadow: 0 12px 26px rgba(225, 29, 72, 0.35);
}

.secondary {
  background: rgba(17,24,39,0.06);
  color: rgba(17,24,39,0.78);
  border: 1px solid rgba(17,24,39,0.10);
}

.confirmed {
  margin-top: 14px;
  background: rgba(225, 29, 72, 0.08);
  border: 1px solid rgba(225, 29, 72, 0.18);
  border-radius: 18px;
  padding: 14px;
  font-weight: 650;
}

.confirmed .big {
  font-size: 22px;
  margin-right: 8px;
}
</style>
