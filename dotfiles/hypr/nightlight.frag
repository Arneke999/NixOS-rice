// Night-light screen shader for Hyprland (decoration:screen_shader).
// Applied in the compositor's render pipeline, so it works even where the GPU/output
// has no gamma-control support (e.g. this virtio-gpu VM) — unlike gammastep/wlsunset.
// Warms the whole screen toward ~4000K by damping green a touch and blue more.
#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    // Per-channel multipliers: red kept, green slightly reduced, blue cut = warm tint.
    pixColor.rgb *= vec3(1.0, 0.92, 0.78);
    fragColor = pixColor;
}
