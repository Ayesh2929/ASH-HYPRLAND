// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║           ASH DOTFILES v3.0 — VIBRANCE BOOST SHADER                        ║
// ║           Increases color saturation and vibrancy                          ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝
//
// Vibrance/Saturation boost GLSL shader for Hyprland
// Makes colors more vivid and saturated — great for wallpapers and media
//
// Usage: decoration { screen_shader = ~/.../vibrance.glsl }

precision mediump float;

varying vec2 v_texcoord;
uniform sampler2D tex;

// Vibrance amount (1.0 = no change, 1.5 = 50% boost, 2.0 = double)
const float VIBRANCE   = 1.35;

// Additional saturation (separate from vibrance)
const float SATURATION = 1.15;

// Contrast adjustment (1.0 = no change)
const float CONTRAST   = 1.02;

// Brightness adjustment
const float BRIGHTNESS = 1.0;

// Convert RGB to HSL
vec3 rgb2hsl(vec3 color) {
    float maxC = max(max(color.r, color.g), color.b);
    float minC = min(min(color.r, color.g), color.b);
    float delta = maxC - minC;

    float h = 0.0;
    float s = 0.0;
    float l = (maxC + minC) / 2.0;

    if (delta > 0.0) {
        s = delta / (1.0 - abs(2.0 * l - 1.0));

        if (maxC == color.r) {
            h = mod((color.g - color.b) / delta, 6.0);
        } else if (maxC == color.g) {
            h = (color.b - color.r) / delta + 2.0;
        } else {
            h = (color.r - color.g) / delta + 4.0;
        }

        h = h / 6.0;
        if (h < 0.0) h += 1.0;
    }

    return vec3(h, s, l);
}

// Convert HSL back to RGB
float hue2rgb(float p, float q, float t) {
    if (t < 0.0) t += 1.0;
    if (t > 1.0) t -= 1.0;
    if (t < 1.0/6.0) return p + (q - p) * 6.0 * t;
    if (t < 1.0/2.0) return q;
    if (t < 2.0/3.0) return p + (q - p) * (2.0/3.0 - t) * 6.0;
    return p;
}

vec3 hsl2rgb(vec3 hsl) {
    float h = hsl.x;
    float s = hsl.y;
    float l = hsl.z;

    if (s == 0.0) {
        return vec3(l, l, l);
    }

    float q = (l < 0.5) ? l * (1.0 + s) : l + s - l * s;
    float p = 2.0 * l - q;

    return vec3(
        hue2rgb(p, q, h + 1.0/3.0),
        hue2rgb(p, q, h),
        hue2rgb(p, q, h - 1.0/3.0)
    );
}

void main() {
    vec4 color = texture2D(tex, v_texcoord);
    vec3 rgb   = color.rgb;

    // ── Contrast ──────────────────────────────────────────────────────────────
    rgb = (rgb - 0.5) * CONTRAST + 0.5;

    // ── Brightness ────────────────────────────────────────────────────────────
    rgb *= BRIGHTNESS;

    // ── Vibrance (smart saturation — boosts less-saturated colors more) ───────
    float luminance = dot(rgb, vec3(0.2126, 0.7152, 0.0722));
    float maxRGB    = max(max(rgb.r, rgb.g), rgb.b);
    float minRGB    = min(min(rgb.r, rgb.g), rgb.b);
    float satCurrent = (maxRGB - minRGB) / (1.0 - abs(2.0 * luminance - 1.0) + 0.001);

    // Boost less-saturated colors more aggressively
    float vibranceBoost = (1.0 - satCurrent) * (VIBRANCE - 1.0);
    rgb = mix(vec3(luminance), rgb, 1.0 + vibranceBoost);

    // ── Global Saturation ─────────────────────────────────────────────────────
    vec3 hsl = rgb2hsl(rgb);
    hsl.y   *= SATURATION;
    hsl.y    = clamp(hsl.y, 0.0, 1.0);
    rgb      = hsl2rgb(hsl);

    // ── Final clamp ───────────────────────────────────────────────────────────
    rgb = clamp(rgb, 0.0, 1.0);

    gl_FragColor = vec4(rgb, color.a);
}