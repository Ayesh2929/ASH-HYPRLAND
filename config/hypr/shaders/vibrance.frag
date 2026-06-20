// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  ASH DOTFILES v5.0 OMEGA — Vibrance / Saturation Shader                     ║
// ║                                                                              ║
// ║  Intelligent saturation boost that protects already-saturated colors       ║
// ║  (unlike simple HSL saturation). Separately controls vibrance (smart       ║
// ║  boost for muted colors) and global saturation for precise color tuning.   ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

precision highp float;

uniform sampler2D tex;
uniform float     time;
varying vec2      v_texcoord;

// ══════════════════════════════════════════════════════════════════════════════
// §01  CONFIGURATION
// ══════════════════════════════════════════════════════════════════════════════

// Smart vibrance: boosts muted colors, protects saturated ones
// Range: -1.0 to +1.0  │  0.0 = no change  │  0.3 = subtle boost
const float VIBRANCE        =  0.35;

// Global saturation multiplier
// Range: 0.0 (gray) to 3.0 (hyper-saturated)  │  1.0 = no change
const float SATURATION      =  1.15;

// Hue rotation in degrees (0.0 = no rotation, 30.0 = slight warm shift)
const float HUE_SHIFT       =  0.0;

// Gamma correction
const float GAMMA           =  2.2;

// ══════════════════════════════════════════════════════════════════════════════
// §02  COLOR SPACE CONVERSION — RGB ↔ HSL
// ══════════════════════════════════════════════════════════════════════════════

vec3 rgbToHSL(vec3 rgb) {
    float maxC = max(rgb.r, max(rgb.g, rgb.b));
    float minC = min(rgb.r, min(rgb.g, rgb.b));
    float delta = maxC - minC;

    float h = 0.0, s = 0.0;
    float l = (maxC + minC) * 0.5;

    if (delta > 0.0001) {
        s = delta / (1.0 - abs(2.0 * l - 1.0));

        if (maxC == rgb.r)      h = (rgb.g - rgb.b) / delta + (rgb.g < rgb.b ? 6.0 : 0.0);
        else if (maxC == rgb.g) h = (rgb.b - rgb.r) / delta + 2.0;
        else                    h = (rgb.r - rgb.g) / delta + 4.0;
        h /= 6.0;
    }

    return vec3(h, s, l);
}

float hue2rgb(float p, float q, float t) {
    if (t < 0.0) t += 1.0;
    if (t > 1.0) t -= 1.0;
    if (t < 1.0/6.0) return p + (q - p) * 6.0 * t;
    if (t < 1.0/2.0) return q;
    if (t < 2.0/3.0) return p + (q - p) * (2.0/3.0 - t) * 6.0;
    return p;
}

vec3 hslToRGB(vec3 hsl) {
    float h = hsl.x, s = hsl.y, l = hsl.z;
    if (s < 0.0001) return vec3(l);

    float q = (l < 0.5) ? l * (1.0 + s) : l + s - l * s;
    float p = 2.0 * l - q;
    return vec3(
        hue2rgb(p, q, h + 1.0/3.0),
        hue2rgb(p, q, h),
        hue2rgb(p, q, h - 1.0/3.0)
    );
}

// ══════════════════════════════════════════════════════════════════════════════
// §03  VIBRANCE ALGORITHM
//      Smart saturation boost — more effect on desaturated, less on vivid
// ══════════════════════════════════════════════════════════════════════════════

vec3 applyVibrance(vec3 rgb, float strength) {
    float maxC    = max(rgb.r, max(rgb.g, rgb.b));
    float minC    = min(rgb.r, min(rgb.g, rgb.b));
    float sat     = maxC - minC;           // Current saturation (0–1)
    float avg     = (rgb.r + rgb.g + rgb.b) / 3.0;

    // Vibrance coefficient: strongest effect on desaturated pixels
    // Less effect on already-vivid pixels (sat close to 1.0)
    float coeff   = strength * (1.0 - sat * 1.5);

    // Boost each channel proportional to distance from average
    vec3  boosted = rgb + (rgb - avg) * coeff;

    return clamp(boosted, 0.0, 1.0);
}

// ══════════════════════════════════════════════════════════════════════════════
// §04  HUE ROTATION MATRIX
// ══════════════════════════════════════════════════════════════════════════════

mat3 hueRotateMatrix(float angleDeg) {
    float angle = radians(angleDeg);
    float cosA  = cos(angle);
    float sinA  = sin(angle);

    // Hue rotation in RGB space (Rodrigues' formula on gray axis)
    return mat3(
        0.213 + cosA * 0.787 - sinA * 0.213,
        0.213 - cosA * 0.213 + sinA * 0.143,
        0.213 - cosA * 0.213 - sinA * 0.787,

        0.715 - cosA * 0.715 - sinA * 0.715,
        0.715 + cosA * 0.285 + sinA * 0.140,
        0.715 - cosA * 0.715 + sinA * 0.715,

        0.072 - cosA * 0.072 + sinA * 0.928,
        0.072 - cosA * 0.072 - sinA * 0.283,
        0.072 + cosA * 0.928 + sinA * 0.072
    );
}

// ══════════════════════════════════════════════════════════════════════════════
// §05  MAIN SHADER
// ══════════════════════════════════════════════════════════════════════════════

void main() {
    vec4 tex_color = texture2D(tex, v_texcoord);
    vec3 color     = tex_color.rgb;

    // ── Decode gamma to linear space ──────────────────────────────────────────
    vec3 linear = pow(color, vec3(GAMMA));

    // ── Apply hue rotation ────────────────────────────────────────────────────
    if (abs(HUE_SHIFT) > 0.1) {
        linear = hueRotateMatrix(HUE_SHIFT) * linear;
        linear = clamp(linear, 0.0, 1.0);
    }

    // ── Apply vibrance (smart saturation) ─────────────────────────────────────
    vec3 vibrated = applyVibrance(linear, VIBRANCE);

    // ── Apply global saturation ───────────────────────────────────────────────
    vec3 hsl      = rgbToHSL(vibrated);
    hsl.y         = clamp(hsl.y * SATURATION, 0.0, 1.0);
    vec3 result   = hslToRGB(hsl);

    // ── Re-encode to sRGB gamma ───────────────────────────────────────────────
    result = pow(clamp(result, 0.0, 1.0), vec3(1.0 / GAMMA));

    gl_FragColor = vec4(result, tex_color.a);
}