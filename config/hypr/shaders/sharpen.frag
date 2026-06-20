// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  ASH DOTFILES v5.0 OMEGA — Sharpen / Unsharp Mask Shader                    ║
// ║                                                                              ║
// ║  Adaptive sharpening using unsharp mask (USM) technique with edge         ║
// ║  detection to prevent over-sharpening. Separate luma/chroma sharpening    ║
// ║  with controllable radius, amount and threshold.                            ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

precision highp float;

uniform sampler2D tex;
uniform float     time;
varying vec2      v_texcoord;

// ══════════════════════════════════════════════════════════════════════════════
// §01  CONFIGURATION
// ══════════════════════════════════════════════════════════════════════════════

// Screen resolution (for pixel-size calculation)
const vec2  RESOLUTION      = vec2(1920.0, 1080.0);

// Sharpening strength (0.0 = off, 0.5 = subtle, 1.0 = standard, 2.0 = strong)
const float STRENGTH        = 0.65;

// Blur radius for unsharp mask (1.0 = 1-pixel radius Gaussian)
const float RADIUS          = 1.0;

// Edge threshold: prevents sharpening below this contrast level
// (reduces sharpening noise in flat areas)
const float THRESHOLD       = 0.03;

// Adaptive sharpening: reduce effect in bright highlight areas
// (prevents highlight clipping common in USM)
const bool  ADAPTIVE        = true;

// Only sharpen luminance channel (less color fringing)
const bool  LUMA_ONLY       = false;

// ══════════════════════════════════════════════════════════════════════════════
// §02  GAUSSIAN BLUR (small radius)
// ══════════════════════════════════════════════════════════════════════════════

vec3 gaussianBlur(sampler2D sampler, vec2 uv, vec2 pixel, float radius) {
    // 3×3 Gaussian kernel weights
    const float w[9] = float[9](
        0.0625, 0.1250, 0.0625,
        0.1250, 0.2500, 0.1250,
        0.0625, 0.1250, 0.0625
    );

    vec3 result = vec3(0.0);
    int  idx    = 0;

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            result += texture2D(sampler, uv + vec2(float(x), float(y)) * pixel * radius).rgb
                     * w[idx];
            idx++;
        }
    }
    return result;
}

// ══════════════════════════════════════════════════════════════════════════════
// §03  MAIN SHADER
// ══════════════════════════════════════════════════════════════════════════════

void main() {
    vec2  pixel     = 1.0 / RESOLUTION;
    vec4  tex_color = texture2D(tex, v_texcoord);
    vec3  color     = tex_color.rgb;

    // ── Compute blurred version (low-frequency component) ─────────────────────
    vec3  blurred   = gaussianBlur(tex, v_texcoord, pixel, RADIUS);

    // ── Unsharp mask: high-frequency detail ───────────────────────────────────
    vec3  detail    = color - blurred;

    // ── Edge-aware threshold ──────────────────────────────────────────────────
    // Only apply where there's sufficient contrast (avoid sharpening noise)
    float edgeStrength = length(detail);
    float edgeMask     = smoothstep(THRESHOLD, THRESHOLD * 3.0, edgeStrength);

    // ── Adaptive sharpening: reduce in bright highlights ──────────────────────
    float adaptMask = 1.0;
    if (ADAPTIVE) {
        float luma  = dot(color, vec3(0.2126, 0.7152, 0.0722));
        adaptMask   = 1.0 - smoothstep(0.75, 0.95, luma);
    }

    // ── Compute final sharpened result ────────────────────────────────────────
    float finalStrength = STRENGTH * edgeMask * adaptMask;

    vec3 result;
    if (LUMA_ONLY) {
        // Sharpen only luminance channel
        float luma_orig     = dot(color,   vec3(0.2126, 0.7152, 0.0722));
        float luma_detail   = dot(detail,  vec3(0.2126, 0.7152, 0.0722));
        float luma_sharp    = luma_orig + luma_detail * finalStrength;
        result              = color * (luma_sharp / max(luma_orig, 0.0001));
    } else {
        result = color + detail * finalStrength;
    }

    gl_FragColor = vec4(clamp(result, 0.0, 1.0), tex_color.a);
}