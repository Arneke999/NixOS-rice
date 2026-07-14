// Faint CRT treatment for the hyprlock lockscreen: subtle scanlines, a soft
// phosphor vignette, and a gentle black-lift so the near-black doesn't crush.
// Deliberately restrained (the "faint" profile) — you notice it on a second
// look, and text stays readable. Tune the constants at the top.
//
// hyprlock's screen_shader interface: GLSL ES 3.00, samples the composited lock
// output from `tex` at `v_texcoord`, writes `fragColor`.

#version 300 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

// ---- tunables (faint profile) ----
const float SCANLINE_STRENGTH = 0.06;   // 0 = off; higher = more visible lines
const float SCANLINE_COUNT    = 720.0;  // lines down the screen
const float VIGNETTE_STRENGTH = 0.28;   // corner falloff (phosphor tube edge)
const float PHOSPHOR_LIFT     = 0.015;  // gentle glow so black doesn't crush

void main() {
    vec4 color = texture(tex, v_texcoord);

    // faint horizontal scanlines
    float s = 0.5 + 0.5 * sin(v_texcoord.y * SCANLINE_COUNT * 3.14159265);
    color.rgb *= 1.0 - SCANLINE_STRENGTH * s;

    // soft vignette
    vec2 uv = v_texcoord - 0.5;
    color.rgb *= 1.0 - VIGNETTE_STRENGTH * dot(uv, uv) * 2.0;

    // subtle phosphor lift
    color.rgb += PHOSPHOR_LIFT;

    fragColor = color;
}
