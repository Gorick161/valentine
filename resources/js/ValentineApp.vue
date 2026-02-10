<template>
  <div class="page">
    <!-- interactive hearts canvas -->
    <canvas ref="canvasRef" class="hearts-canvas" aria-hidden="true"></canvas>

    <!-- modal appears after 5s -->
    <div v-if="showModal" class="overlay" :class="{ open: isOpen }">
      <div class="modal" :class="{ celebrate: accepted }" role="dialog" aria-modal="true">
        <h1 id="title">Willst du mein Valentinsschatzik sein?</h1>
        <p>Antworte Weise mein bebik.</p>

        <div class="actions" ref="actionsRef" @pointermove="onPointerMove">
          <button class="btn yes" :disabled="accepted" @click="accept">
            {{ accepted ? "Yes ✅" : "Yes" }}
          </button>

          <button
            class="btn no"
            ref="noRef"
            type="button"
            @pointerenter="moveNo"
            @focus="onNoFocus"
          >
            No
          </button>
        </div>

        <div class="success" :class="{ visible: accepted }">
          <div class="headline">
            <span class="big-heart">💖</span>
            JAAAAAAAAAAAAA WUHUUUU KUSSJU KUSSJU!
          </div>

          <div class="next">
            <div class="progress">
              <div class="bar" :style="{ width: `${progress}%` }"></div>
            </div>
            <div class="hint">
              Date-Auswahl in <b>{{ secondsLeft }}</b> Sekunden…
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onBeforeUnmount, onMounted, ref } from "vue";

/** Modal timing */
const showModal = ref(false);
const isOpen = ref(false);
let showModalTimeout = null;

/** Yes/No logic */
const accepted = ref(false);
const actionsRef = ref(null);
const noRef = ref(null);

const secondsLeft = ref(10);  // GEÄNDERT: von 30 auf 10
const progress = ref(0);
let countdownTimer = null;

function accept() {
  if (accepted.value) return;
  accepted.value = true;

  // optional: little celebration burst
  celebratingUntil = performance.now() + 6000;
  burstHearts(90);
  startCelebrationSpawns();

  // 10s countdown -> redirect  // GEÄNDERT: von 30s auf 10s
  secondsLeft.value = 10;  // GEÄNDERT
  progress.value = 0;

  const startedAt = Date.now();
  if (countdownTimer) clearInterval(countdownTimer);

  countdownTimer = setInterval(() => {
    const elapsed = Math.floor((Date.now() - startedAt) / 1000);
    const left = Math.max(0, 10 - elapsed);  // GEÄNDERT: von 30 auf 10

    secondsLeft.value = left;
    progress.value = Math.min(100, (elapsed / 10) * 100);  // GEÄNDERT: von 30 auf 10

    if (left <= 0) {
      clearInterval(countdownTimer);
      countdownTimer = null;
      window.location.assign("/surprise");
    }
  }, 200);
}

function moveNo() {
  const container = actionsRef.value;
  const btn = noRef.value;
  if (!container || !btn) return;

  const c = container.getBoundingClientRect();
  const b = btn.getBoundingClientRect();

  const padding = 6;
  const maxX = Math.max(padding, c.width - b.width - padding);
  const maxY = Math.max(padding, c.height - b.height - padding);

  const x = padding + Math.floor(Math.random() * (maxX - padding + 1));
  const y = padding + Math.floor(Math.random() * (maxY - padding + 1));

  btn.style.left = `${x}px`;
  btn.style.top = `${y}px`;
  btn.style.right = "auto";
}

function onPointerMove(e) {
  const btn = noRef.value;
  if (!btn) return;

  const r = btn.getBoundingClientRect();
  const cx = r.left + r.width / 2;
  const cy = r.top + r.height / 2;

  const dx = e.clientX - cx;
  const dy = e.clientY - cy;
  const dist = Math.hypot(dx, dy);

  if (dist < 90) moveNo();
}

function onNoFocus() {
  noRef.value?.blur();
  moveNo();
}

/** ---- Canvas hearts (same behavior as before) ---- */
const canvasRef = ref(null);

let rafId = 0;
let ctx = null;
let dpr = 1;
let w = 0;
let h = 0;

const mouse = { x: 0, y: 0, active: false };

const HEART_COUNT = 70;
const hearts = [];

// Celebration bursts (optional)
const bursts = [];
let celebratingUntil = 0;

function rand(min, max) {
  return Math.random() * (max - min) + min;
}

function resizeCanvas() {
  const canvas = canvasRef.value;
  if (!canvas) return;

  dpr = window.devicePixelRatio || 1;
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
    vy: rand(0.35, 1.2),
    vx: rand(-0.25, 0.25),
    sway: rand(0, Math.PI * 2),
    rot: rand(-0.4, 0.4),
    vr: rand(-0.01, 0.01),
    alpha: rand(0.35, 0.85),
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

/** bursts (optional) */
function burstHearts(count = 60) {
  for (let i = 0; i < count; i++) {
    const angle = rand(-Math.PI * 0.05, Math.PI + Math.PI * 0.05);
    const speed = rand(2.5, 7.5);

    bursts.push({
      x: rand(w * 0.25, w * 0.75),
      y: rand(h * 0.45, h * 0.75),
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

function startCelebrationSpawns() {
  const interval = setInterval(() => {
    if (performance.now() > celebratingUntil) {
      clearInterval(interval);
      return;
    }
    burstHearts(18);
  }, 400);
}

function tick() {
  rafId = requestAnimationFrame(tick);
  if (!ctx) return;

  ctx.clearRect(0, 0, w, h);

  // subtle glow
  ctx.save();
  ctx.globalAlpha = 0.15;
  const g = ctx.createRadialGradient(w * 0.5, h * 0.4, 50, w * 0.5, h * 0.4, Math.max(w, h));
  g.addColorStop(0, "rgba(255,255,255,0.35)");
  g.addColorStop(1, "rgba(255,255,255,0)");
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, w, h);
  ctx.restore();

  // IMPORTANT: floating hearts loop (this is what you were missing)
  for (let i = 0; i < hearts.length; i++) {
    const p = hearts[i];

    p.sway += 0.02;
    p.x += p.vx + Math.sin(p.sway) * 0.15;
    p.y -= p.vy;
    p.rot += p.vr;

    // mouse repel (same feel as before)
    if (mouse.active) {
      const dx = p.x - mouse.x;
      const dy = p.y - mouse.y;
      const dist = Math.hypot(dx, dy);
      const radius = 120;

      if (dist < radius && dist > 0.001) {
        const strength = (1 - dist / radius) * 1.8;
        p.x += (dx / dist) * strength * 2.2;
        p.y += (dy / dist) * strength * 2.2;
        p.rot += (dx / dist) * 0.02;
      }
    }

    if (p.y < -60) {
      hearts.splice(i, 1);
      i--;
      spawnHeart(false);
      continue;
    }

    if (p.x < -60) p.x = w + 60;
    if (p.x > w + 60) p.x = -60;

    drawHeart(p.x, p.y, p.size, p.rot, p.alpha);
  }

  // bursts (only visible after Yes)
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

function onMouseMove(e) {
  mouse.x = e.clientX;
  mouse.y = e.clientY;
  mouse.active = true;
}

function onMouseLeave() {
  mouse.active = false;
}

onMounted(() => {
  resizeCanvas();

  hearts.length = 0;
  for (let i = 0; i < HEART_COUNT; i++) spawnHeart(true);

  tick();

  window.addEventListener("resize", resizeCanvas, { passive: true });
  window.addEventListener("pointermove", onMouseMove, { passive: true });
  window.addEventListener("pointerleave", onMouseLeave, { passive: true });

  // GEÄNDERT: show modal after 5s (statt 30s)
  showModalTimeout = setTimeout(() => {
    showModal.value = true;
    setTimeout(() => (isOpen.value = true), 120);
  }, 5000);  // GEÄNDERT: von 30000 auf 5000
});

onBeforeUnmount(() => {
  cancelAnimationFrame(rafId);

  window.removeEventListener("resize", resizeCanvas);
  window.removeEventListener("pointermove", onMouseMove);
  window.removeEventListener("pointerleave", onMouseLeave);

  if (showModalTimeout) clearTimeout(showModalTimeout);
  if (countdownTimer) clearInterval(countdownTimer);
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

.overlay {
  position: fixed;
  inset: 0;
  z-index: 2;
  display: grid;
  place-items: center;
  padding: 18px;
  background: rgba(0, 0, 0, 0.25);
  opacity: 0;
  pointer-events: none;
  transition: opacity 650ms ease;
}

.overlay.open {
  opacity: 1;
  pointer-events: auto;
}

.modal {
  width: min(560px, 100%);
  background: #ffffff;
  color: #111827;
  border: 1px solid rgba(0, 0, 0, 0.08);
  border-radius: 22px;
  box-shadow: 0 24px 70px rgba(0, 0, 0, 0.25);
  padding: 26px 22px 22px;
  transform: translateY(10px) scale(0.985);
  opacity: 0;
  transition: transform 650ms ease, opacity 650ms ease;
}

.overlay.open .modal {
  transform: translateY(0) scale(1);
  opacity: 1;
}

.modal.celebrate {
  box-shadow: 0 24px 90px rgba(225, 29, 72, 0.35);
  border-color: rgba(225, 29, 72, 0.2);
}

h1 {
  margin: 14px 0 8px;
  font-size: 32px;
  line-height: 1.1;
  letter-spacing: -0.02em;
}

p {
  margin: 0 0 18px;
  color: rgba(17, 24, 39, 0.7);
  font-size: 15px;
  line-height: 1.45;
}

.actions {
  margin-top: 14px;
  display: flex;
  justify-content: center;
  gap: 12px;
  position: relative;
  height: 56px;
}

.btn {
  appearance: none;
  border: none;
  border-radius: 14px;
  padding: 14px 18px;
  font-size: 16px;
  font-weight: 650;
  cursor: pointer;
  transition: transform 120ms ease, background 150ms ease;
  user-select: none;
  -webkit-tap-highlight-color: transparent;
}

.btn.yes {
  background: #e11d48;
  color: #fff;
  box-shadow: 0 12px 26px rgba(225, 29, 72, 0.35);
}
.btn.yes:hover {
  background: #be123c;
}
.btn.yes:active {
  transform: translateY(1px) scale(0.99);
}
.btn.yes:disabled {
  opacity: 0.9;
  cursor: default;
}

.btn.no {
  background: rgba(17, 24, 39, 0.06);
  color: rgba(17, 24, 39, 0.7);
  border: 1px solid rgba(17, 24, 39, 0.1);
  position: absolute;
  right: 0;
  min-width: 110px;
}

.success {
  margin-top: 14px;
  text-align: center;
  font-size: 16px;
  color: rgba(17, 24, 39, 0.85);
  display: none;
}
.success.visible {
  display: block;
}

.success .headline {
  display: flex;
  flex-direction: column;
  gap: 6px;
  align-items: center;
}

.big-heart {
  font-size: 46px;
  display: block;
  margin: 10px 0 4px;
  transform-origin: center;
  animation: pop 700ms ease both;
}

@keyframes pop {
  0% {
    transform: scale(0.6);
    opacity: 0;
  }
  60% {
    transform: scale(1.12);
    opacity: 1;
  }
  100% {
    transform: scale(1);
  }
}

.next {
  margin-top: 14px;
}

.progress {
  height: 10px;
  width: 100%;
  background: rgba(17, 24, 39, 0.08);
  border-radius: 999px;
  overflow: hidden;
}

.bar {
  height: 100%;
  width: 0%;
  background: #e11d48;
  transition: width 200ms linear;
}

.hint {
  margin-top: 10px;
  font-size: 14px;
  color: rgba(17, 24, 39, 0.75);
}

@media (prefers-reduced-motion: reduce) {
  .overlay,
  .modal,
  .btn {
    transition: none !important;
  }
  .big-heart {
    animation: none !important;
  }
}
</style>