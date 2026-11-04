// Pixelate window content into low-res blocks (downscaled-CRT feel).
// uv is normalized over the window; umbriel_size is in effect logical pixels.
vec4 window(vec2 uv) {
  // BLOCK SIZE IN LOGICAL PIXELS — the one knob to tune.
  //   2.0 = barely-there crunch, text stays sharp
  //   3.0 = default: readable but visibly chunky
  //   6.0+ = arcade / "too aggressive for reading"
  // Fixed pixel size (not a window fraction) so a maximized window and a
  // floating one pixelate the same amount.
  float block = 3.0;
  vec2 g = max(umbriel_size / block, vec2(1.0));
  vec2 cell = floor(uv * g) / g;
  return umbriel_sample(cell + 0.5 / g);
}
