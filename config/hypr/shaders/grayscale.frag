// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  ASH DOTFILES v5.0 OMEGA — Grayscale Shader                                 ║
// ║                                                                              ║
// ║  Converts screen to grayscale with multiple luminance formulas.            ║
// ║  Supports partial desaturation, warm/cool tone mapping, and               ║
// ║  accessibility modes (deuteranopia, protanopia, tritanopia simulation).    ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

precision highp float;

uniform sampler2D tex;
uniform float     time;
varying vec2      v_texcoord;

// ══════════════════════════════════════════════════════════════════════════════
// §01  CONFIGURATION
// ══════════════════════════════════════════════════════════════════════════════

// Desaturation amount (0.0 = full color, 1.0 = full grayscale)
const float DESATURATE   = 1.0;

// Luminance formula mode:
//   0 = Rec. 709  (standard, perceptually accurate for modern displays)
//   1 = Rec. 601  (legacy NTSC, warmer feel)
//   2 = Average   (equal weight, mathematical)
//   3 = Luminosity (HSL lightness, maximum information preservation)
const int   LUMA_MODE    = 0;

// Apply warm tint to grayscale (0.0 = neutral gray, 0.1 = warm sepia-lite)
const float WARM_TINT    = 0.0;

// Contrast adjustment (1.0 = no change, 1.2 = +20% contrast)
const float CONTRAST     = 1.05;

// Brightness bias (-1.0 to +1.0, 0.0 = no change)
const float BRIGHTNESS   = 0.0;

// ══════════════════════════════════════════════════════════════════════════════
// §02  LUMINANCE FUNCTIONS
// ══════════════════════════════════════════════════════════════════════════════

float luma_rec709(vec3 c) {
    // ITU-R BT.709 — standard for HD video and sRGB displays
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

float luma_rec601(vec3 c) {
    // ITU-R BT.601 — standard for SD/NTSC (warmer)
    return dot(c, vec3(0.299, 0.587, 0.114));
}

float luma_average(vec3 c) {
    // Equal weight average
    return (c.r + c.g + c.b) / 3.0;
}

float luma_luminosity(vec3 c) {
    // HSL lightness: (max + min) / 2
    return (max(max(c.r, c.g), c.b) + min(min(c.r, c.g), c.b)) * 0.5;
}

float getLuma(vec3 color) {
    if (LUMA_MODE == 0) return luma_rec709(color);
    if (LUMA_MODE == 1) return luma_rec601(color);
    if (LUMA_MODE == 2) return luma_average(color);
    return luma_luminosity(color);
}

// ══════════════════════════════════════════════════════════════════════════════
// §03  COLOR VISION DEFICIENCY SIMULATION MATRICES
//      Uncomment to simulate specific CVD types (for accessibility testing)
// ══════════════════════════════════════════════════════════════════════════════

// Deuteranopia (red-green, green-weak) — ~6% of males
// mat3 CVD_MATRIX = mat3(
//     0.625, 0.375, 0.0,
//     0.700, 0.300, 0.0,
//     0.000, 0.300, 0.700
// );

// Protanopia (red-green, red-weak) — ~1% of males
// mat3 CVD_MATRIX = mat3(
//     0.567, 0.433, 0.0,
//     0.558, 0.442, 0.0,
//     0.000, 0.242, 0.758
// );

// ══════════════════════════════════════════════════════════════════════════════
// §04  MAIN SHADER
// ══════════════════════════════════════════════════════════════════════════════

void main() {
    vec4 tex_color = texture2D(tex, v_texcoord);
    vec3 color     = tex_color.rgb;

    // ── Compute grayscale luminance ────────────────────────────────────────────
    float luma     = getLuma(color);

    // ── Base gray with warm tint option ───────────────────────────────────────
    vec3 gray = mix(
        vec3(luma),                                            // Neutral gray
        vec3(luma * 1.08, luma * 0.97, luma * 0.88),         // Warm tinted gray
        WARM_TINT
    );

    // ── Blend between original and grayscale ──────────────────────────────────
    vec3 result = mix(color, gray, DESATURATE);

    // ── Contrast adjustment (around midpoint 0.5) ─────────────────────────────
    result = (result - 0.5) * CONTRAST + 0.5 + BRIGHTNESS;

    // ── Clamp and output ──────────────────────────────────────────────────────
    gl_FragColor = vec4(clamp(result, 0.0, 1.0), tex_color.a);
}