// Chunky stepped version of the bundled reveal: the wipe edge advances in
// visible 12-step increments instead of gliding. Quantize edge, keep softness.
vec4 animation(vec2 uv) {
  float visible = umbriel_direction > 0.0 ? umbriel_clamped_progress : 1.0 - umbriel_clamped_progress;
  visible = floor(visible * 12.0) / 12.0;
  float edge = mix(-0.02, 1.02, visible);
  float mask = 1.0 - smoothstep(edge - 0.02, edge + 0.02, uv.x);
  return umbriel_sample(uv) * mask;
}
