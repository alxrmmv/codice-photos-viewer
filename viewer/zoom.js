(function (root, factory) {
  const api = factory();

  if (typeof module === "object" && module.exports) {
    module.exports = api;
  }

  if (root) {
    root.JacketZoom = api;
  }
})(typeof window !== "undefined" ? window : null, function () {
  function clamp(value, minimum, maximum) {
    return Math.min(maximum, Math.max(minimum, value));
  }

  function calculateOrigin(clientX, clientY, rect) {
    if (!rect.width || !rect.height) return { x: 50, y: 50 };

    return {
      x: clamp(((clientX - rect.left) / rect.width) * 100, 0, 100),
      y: clamp(((clientY - rect.top) / rect.height) * 100, 0, 100)
    };
  }

  function bind(image, options = {}) {
    const zoomClass = options.zoomClass || "is-zoomed";
    let active = false;
    let baseRect = null;

    function reset() {
      active = false;
      baseRect = null;
      image.classList.remove(zoomClass);
      image.style.removeProperty("--zoom-x");
      image.style.removeProperty("--zoom-y");
    }

    function onPointerEnter(event) {
      if (event.pointerType !== "mouse") return;
      active = true;
      baseRect = image.getBoundingClientRect();
      image.classList.add(zoomClass);
    }

    function onPointerMove(event) {
      if (!active || event.pointerType !== "mouse" || !baseRect) return;
      const origin = calculateOrigin(event.clientX, event.clientY, baseRect);
      image.style.setProperty("--zoom-x", `${origin.x}%`);
      image.style.setProperty("--zoom-y", `${origin.y}%`);
    }

    function destroy() {
      reset();
      image.removeEventListener("pointerenter", onPointerEnter);
      image.removeEventListener("pointermove", onPointerMove);
      image.removeEventListener("pointerleave", reset);
    }

    image.addEventListener("pointerenter", onPointerEnter);
    image.addEventListener("pointermove", onPointerMove);
    image.addEventListener("pointerleave", reset);

    return { reset, destroy };
  }

  return { bind, calculateOrigin };
});
