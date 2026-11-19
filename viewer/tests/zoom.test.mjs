import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { readFileSync } from "node:fs";
import test from "node:test";

const require = createRequire(import.meta.url);

function loadZoom() {
  try {
    return require("../zoom.js");
  } catch (error) {
    if (error.code === "MODULE_NOT_FOUND") return {};
    throw error;
  }
}

function fakeImage(rect = { left: 100, top: 50, width: 400, height: 600 }) {
  const listeners = new Map();
  const classes = new Set();
  const properties = new Map();

  return {
    listeners,
    classList: {
      add: name => classes.add(name),
      remove: name => classes.delete(name),
      contains: name => classes.has(name)
    },
    style: {
      setProperty: (name, value) => properties.set(name, value),
      removeProperty: name => properties.delete(name),
      getPropertyValue: name => properties.get(name) ?? ""
    },
    addEventListener: (name, handler) => listeners.set(name, handler),
    removeEventListener: (name, handler) => {
      if (listeners.get(name) === handler) listeners.delete(name);
    },
    getBoundingClientRect: () => rect
  };
}

test("calculateOrigin follows the pointer and clamps outside coordinates", () => {
  const zoom = loadZoom();
  assert.equal(typeof zoom.calculateOrigin, "function");

  const rect = { left: 100, top: 50, width: 400, height: 600 };
  assert.deepEqual(zoom.calculateOrigin(200, 500, rect), { x: 25, y: 75 });
  assert.deepEqual(zoom.calculateOrigin(0, 900, rect), { x: 0, y: 100 });
});

test("bind activates mouse zoom, tracks its origin, and resets on leave", () => {
  const zoom = loadZoom();
  assert.equal(typeof zoom.bind, "function");

  const image = fakeImage();
  const controller = zoom.bind(image, { zoomClass: "is-zoomed" });

  image.listeners.get("pointerenter")({ pointerType: "mouse" });
  image.listeners.get("pointermove")({ pointerType: "mouse", clientX: 200, clientY: 500 });

  assert.equal(image.classList.contains("is-zoomed"), true);
  assert.equal(image.style.getPropertyValue("--zoom-x"), "25%");
  assert.equal(image.style.getPropertyValue("--zoom-y"), "75%");

  image.listeners.get("pointerleave")();
  assert.equal(image.classList.contains("is-zoomed"), false);
  assert.equal(image.style.getPropertyValue("--zoom-x"), "");
  assert.equal(image.style.getPropertyValue("--zoom-y"), "");

  controller.destroy();
  assert.equal(image.listeners.size, 0);
});

test("touch input stays unzoomed and explicit reset clears active zoom", () => {
  const zoom = loadZoom();
  assert.equal(typeof zoom.bind, "function");

  const image = fakeImage();
  const controller = zoom.bind(image, { zoomClass: "is-zoomed" });

  image.listeners.get("pointerenter")({ pointerType: "touch" });
  image.listeners.get("pointermove")({ pointerType: "touch", clientX: 300, clientY: 300 });
  assert.equal(image.classList.contains("is-zoomed"), false);

  image.listeners.get("pointerenter")({ pointerType: "mouse" });
  assert.equal(image.classList.contains("is-zoomed"), true);
  controller.reset();
  assert.equal(image.classList.contains("is-zoomed"), false);
});

test("viewer integrates the full-screen hover zoom contract", () => {
  const html = readFileSync(new URL("../index.html", import.meta.url), "utf8");

  assert.match(html, /<script src="zoom\.js"><\/script>/);
  assert.match(html, /class="zoom-viewport"/);
  assert.match(html, /scale\(2\.5\)/);
  assert.match(html, /JacketZoom\.bind\(lightboxImage/);
  assert.match(html, /zoomController\.reset\(\)/);
});
