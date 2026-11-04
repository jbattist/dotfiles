// Animated neon ring: palette-cycling color, brightness travelling around
// the border, light pass (set in effect.toml) turns it into glow bleed.
// umbriel_border_distance < 0 means inside the ring band; the engine cuts
// the client hole from the result automatically.
vec4 border(vec2 uv) {
  float t = umbriel_time;
  vec4 base = umbriel_palette_at(fract(uv.x + uv.y + t * 0.35));
  float hot = 0.75 + 0.25 * sin((uv.x + uv.y) * 12.566 + t * 2.0);
  float inside = umbriel_border_distance(uv) < 0.0 ? 1.0 : 0.0;
  return vec4(base.rgb * hot * 1.3, base.a) * inside;
}
