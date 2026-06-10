// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║           ASH DOTFILES v3.0 — BLUE LIGHT FILTER SHADER                     ║
// ║           Reduces blue light for comfortable night viewing                 ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝
//
// Blue light filter GLSL shader for Hyprland
// Reduces blue channel and boosts red/green for warmer color temperature (~4000K)
//
// Usage in Hyprland:
//   decoration {
//       screen_shader = ~/.config/hypr/assets/shaders/blue-light-filter.glsl
//   }
//
// Or toggle via keybind: SUPER + F5

precision mediump float;

// Input texture (current screen content)
varying vec2 v_texcoord;
uniform sampler2D tex;

// Color temperature adjustment
// These values approximate 4000K warm light
const float RED_BOOST    = 1.08;  // Increase red channel slightly
const float GREEN_REDUCE = 0.95;  // Reduce green slightly
const float BLUE_REDUCE  = 0.72;  // Significantly reduce blue channel

// Gamma correction
const float GAMMA = 1.0;

// Brightness adjustment (1.0 = no change, 0.9 = 10% darker)
const float BRIGHTNESS = 0.96;

void main() {
    // Sample the screen texture
    vec4 color = texture2D(tex, v_texcoord);

    // Apply blue light filter
    float r = color.r * RED_BOOST;
    float g = color.g * GREEN_REDUCE;
    float b = color.b * BLUE_REDUCE;

    // Apply brightness
    r = r * BRIGHTNESS;
    g = g * BRIGHTNESS;
    b = b * BRIGHTNESS;

    // Gamma correction (optional)
    if (GAMMA != 1.0) {
        r = pow(clamp(r, 0.0, 1.0), 1.0 / GAMMA);
        g = pow(clamp(g, 0.0, 1.0), 1.0 / GAMMA);
        b = pow(clamp(b, 0.0, 1.0), 1.0 / GAMMA);
    }

    // Clamp values to valid range
    r = clamp(r, 0.0, 1.0);
    g = clamp(g, 0.0, 1.0);
    b = clamp(b, 0.0, 1.0);

    // Output filtered color (preserve alpha)
    gl_FragColor = vec4(r, g, b, color.a);
}