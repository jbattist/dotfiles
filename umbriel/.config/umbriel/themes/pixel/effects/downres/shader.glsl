// Pixelate the window into chunky blocks (low-res feel).
// uv is normalized over the window; umbriel_size is logical pixels, so the
// grid is resolution-independent: ~132 blocks wide with square blocks.
vec4 window(vec2 uv) {
  vec2 grid = vec2(132.0, 132.0 * umbriel_size.y / max(umbriel_size.x, 1.0));
  vec2 g = max(grid, vec2(1.0));
  vec2 cell = floor(uv * g) / g;
  return umbriel_sample(cell + 0.5 / g);
}
