// Quake-style drawer: the window slides down from above the top edge when
// shown and slides back up when hidden. Used on [animation.scratchpad].
//
// uv is normalized over the window with (0,0) at the top left.
// umbriel_direction is 1 while showing and -1 while hiding; progress runs
// 0 -> 1 in both cases, so convert it to "how much of the drawer is down".
vec4 animation(vec2 uv) {
  float p = umbriel_clamped_progress;
  float shown = umbriel_direction > 0.0 ? p : 1.0 - p;
  // Offset the sample upward by the part of the drawer still hidden: at
  // shown = 0 only the bottom edge of the window would sit at the top of
  // its rectangle; at shown = 1 the window is in place.
  vec2 src = vec2(uv.x, uv.y + (1.0 - shown));
  if (src.y > 1.0) {
    return vec4(0.0);
  }
  return umbriel_sample(src);
}
